@{
    RootModule = 'ADCustomAttributes.psm1'
    ModuleVersion = '0.0.0.3'
    GUID = '10704184-4704-452f-b7b2-172bdfe8dfdc'
    Author = 'drlsdee'
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee. All rights reserved.'
    Description = 'Here should be a PS module creating custom AD attributes in AD schema'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'New-ADCustomAttributeOID', 'New-ADObjectCustomAttribute'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    PrivateData = @{
        PSData = @{}
    }
}
