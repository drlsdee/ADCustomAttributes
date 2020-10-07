@{
    RootModule = 'ADCustomAttributes.psm1'
    ModuleVersion = '0.0.0.4'
    GUID = '10704184-4704-452f-b7b2-172bdfe8dfdc'
    Author = 'drlsdee'
    CompanyName = 'Unknown'
    Copyright = '(c) 2020 drlsdee. All rights reserved.'
    Description = 'A small PowerShell module creating custom AD attributes in AD schema. Inspired by: https://www.dataart.ru/news/extending-active-directory-schema-to-store-application-configuration-powershell-examples/'
    PowerShellVersion = '5.1'
    FunctionsToExport = 'New-ADCustomAttributeOID', 'New-ADObjectCustomAttribute'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/drlsdee/ADCustomAttributes'
        }
    }
}
