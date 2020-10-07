#   Inspired by: https://www.dataart.ru/news/extending-active-directory-schema-to-store-application-configuration-powershell-examples/
function New-ADObjectCustomAttribute {
    [CmdletBinding(SupportsShouldProcess    = $true)]
    param (
        # AD class name, must be a LDAP display name
        [Parameter(
            Mandatory   = $true,
            HelpMessage = 'Enter the AD object class name here. It must be a LDAPDisplayName.'
        )]
        [string]
        $ClassName,

        # Attribute name
        [Parameter(Mandatory    = $true)]
        [string]
        $AttributeName,

        # AD context type
        [Parameter()]
        [ValidateSet(
            'Forest',
            'DirectoryServer',
            'ConfigurationSet' # "DirectoryServer" and "ConfigurationSet" are not implemented yet
        )]
        [string]
        $ContextType    = 'Forest',

        # OID Prefix
        [Parameter()]
        [string]
        $Prefix     = '1.2.840.113556.1.8000.2554',

        # Attribute syntax
        [Parameter()]
        [ValidateSet(
            'AccessPointDN',
            'Bool',
            'CaseExactString',
            'CaseIgnoreString',
            'DirectoryString',
            'DN',
            'DNWithBinary',
            'DNWithString',
            'Enumeration',
            'GeneralizedTime',
            'IA5String',
            'Int',
            'Int64',
            'NumericString',
            'OctetString',
            'Oid',
            'ORName',
            'PresentationAddress',
            'PrintableString',
            'ReplicaLink',
            'SecurityDescriptor',
            'Sid',
            'UtcTime'
        )]
        [string]
        $AttributeSyntax = 'CaseIgnoreString',

        # Attribute common name
        [Parameter()]
        [string]
        $CommonName
    )
    [string]$myName = "$($MyInvocation.InvocationName):"
    Write-Verbose -Message "$myName Starting the function..."
    #   In the first, we need System.DirectoryServices .NET assembly to manipulate AD attrinutes, classes and properties
    $null = [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices")
    #   Now get AD context:
    switch ($ContextType) {
        'Forest'            {
            [System.DirectoryServices.ActiveDirectory.DirectoryContextType]$adContextType   = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::$ContextType
        }
        'DirectoryServer'   {
            Write-Warning -Message "$myName Context type `'$ContextType`' is not implemented yet! Exiting."
            return
        }
        'ConfigurationSet'  {
            Write-Warning -Message "$myName Context type `'$ContextType`' is not implemented yet! Exiting."
            return
        }
    }
    Write-Verbose -Message "$myName Loading AD context with context type `'$ContextType`'"
    [System.DirectoryServices.ActiveDirectory.DirectoryContext]$adContext   = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($adContextType)
    #   Get Schema
    Write-Verbose -Message "$myName Getting the AD schema with current context..."
    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]$adSchema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetSchema($adContext)
    #   If shema not found, exiting.
    if ($null -eq $adSchema) {
        Write-Warning -Message "$myName Failed to get the Active Directory schema with current context: Type: `'$($adContext.ContextType)`'; Name: `'$($adContext.Name)`'; UserName: `'$($adContext.UserName)`'! Exiting."
        return
    }
    #   Go deeper...
    try {
        Write-Verbose -Message "$myName Looking for the class `'$ClassName`' in the AD schema `'$adSchema`'.."
        [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaClass]$adObjectClass = $adSchema.FindClass($ClassName)
    }
    catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException] {
        Write-Warning -Message "$myName The class `'$ClassName`' does not exist in the AD schema `'$adSchema`'! Exiting."
        return
    }
    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaPropertyCollection]$adClassOptionalProperties  = $adObjectClass.OptionalProperties
    Write-Verbose -Message "$myName Found class `'$($adObjectClass.Name)`' with OID `'$($adObjectClass.Oid)`' and $($adClassOptionalProperties.Count) optional properties."
    #   Make sure the property we want to set doesn't already exist:
    [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]$attrExisting = ($adClassOptionalProperties.Where({$_.Name -eq $AttributeName}))[0]
    if ($null -ne $attrExisting) {
        Write-Verbose -Message "$myName The class `'$($adObjectClass.Name)`' with OID `'$($adObjectClass.Oid)`' already contains the attribute with name `'$AttributeName`':"
        return $attrExisting
    }

    #   The class does not contain the attribute. But maybe the attribute already exists in the schema, so we try to find it.
    try {
        Write-Verbose -Message "$myName Looking for the attribute `'$AttributeName`' by its name..."
        [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]$adObjectProperty   = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]::FindByName($adContext, $AttributeName)
    }
    catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectNotFoundException] {
        Write-Verbose -Message "$myName The attribute with name `'$AttributeName`' not found in the current context `'$ContextType`'. Creating..."
        #[System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]$adObjectProperty   = $null
        [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]$adObjectProperty   = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchemaProperty]::new($adContext, $AttributeName)
    }
    catch {
        throw $_
    }

    if ($null -ne $adObjectProperty.Oid) {
        #   Attribute found, it will be enough to set it to the our class.
        Write-Verbose -Message "$myName The attribute `'$($adObjectProperty.Name)`' with OID `'$($adObjectProperty.Oid)`' already exists in the AD schema. Adding to the class `'$ClassName`'..."
    } else {
        #   Attribute not found, creating:
        Write-Verbose -Message "$myName Filling the attribute `'$AttributeName`' with properties..."
        $adObjectProperty.Oid   = New-ADCustomAttributeOID -Prefix $Prefix
        if ($CommonName) {
            $adObjectProperty.CommonName    = $CommonName
        } else {
            $adObjectProperty.CommonName    = $AttributeName
        }
        $adObjectProperty.IsSingleValued    = $true
        $adObjectProperty.Syntax    = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySyntax]::$AttributeSyntax
        #   Creating debug string:
        [string[]]$adAttributePropNames     = $adObjectProperty.PSObject.Properties.Name
        [string]$adAttributePropSummary     = $adAttributePropNames.ForEach({"$($_):`t`'$($adObjectProperty.$_)`'"}) -join ";`n"
        if ($PSCmdlet.ShouldProcess("`n$adAttributePropSummary", "Saving the AD custom attribute `'$($adObjectProperty)`' with parameters:")) {
            try {
                $adObjectProperty.Save()
            }
            catch [System.UnauthorizedAccessException] {
                Write-Warning -Message "$myName Unable to save the attribute `'$($AttributeName)`' with properties:`n$adAttributePropSummary.`nCheck your privileges! Exiting."
                return
            }
            catch {
                Write-Warning -Message "$myName Unhandled error has occurred during saving the attribute `'$($AttributeName)`': $($_.Exception.Message)"
                throw $_
            }
        }
    }

    #   Adding the attribute to the class:
    try {
        [int]$adSchemaPropertyIndex = $adClassOptionalProperties.Add($adObjectProperty)
    }
    catch {
        Write-Warning -Message "$myName Unable to add the custom attribute `'$AttributeName`' to the class `'$ClassName`'! If you invoke function with the `'WhatIf`' parameter, the attribute was not created. For any other cases see the exception: $($_.Exception.Message)"
    }
    if ($null -ne $adSchemaPropertyIndex) {
        Write-Verbose -Message "$myName The custom attribute `'$AttributeName`' was added to the class `'$ClassName`' with index `'$adSchemaPropertyIndex`'"
    } else {
        Write-Verbose -Message "$myName The custom attribute `'$AttributeName`' was NOT added to the class `'$ClassName`'."
    }

    #   Saving the class
    if ($PSCmdlet.ShouldProcess("AD object class `'$($adObjectClass.Name)`' with OID `'$($adObjectClass.Oid)`'", "Saving the added custom attribute `'$AttributeName`' with properties:`n$adAttributePropSummary")) {
        try {
            $adObjectClass.Save()
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "$myName Unable to add the attribute `'$($AttributeName)`' with properties:`n$adAttributePropSummary`n to the AD object class `'$($adObjectClass.Name)`' with OID `'$($adObjectClass.Oid)`'!`nCheck your privileges! Exiting."
            return
        }
        catch {
            Write-Warning -Message "$myName Unhandled error has occurred during saving the AD object class `'$($adObjectClass.Name)`' with OID `'$($adObjectClass.Oid)`' with added attribute `'$($AttributeName)`': $($_.Exception.Message)"
            throw $_
        }
    }

    Write-Verbose -Message "$myName End of the function."
    return
}
