[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('Manifest', 'Publish', 'All')]
    [string]
    $Action
)

[string]$nuGetApiFile       = [System.IO.Directory]::EnumerateFiles($PSScriptRoot, '*-apikey.txt')[0]
[string]$nuGetRepoName      = ([string]([System.IO.Path]::GetFileNameWithoutExtension($nuGetApiFile))).Split('-')[0]
[string]$nuGetApiKey        = [System.IO.File]::ReadAllLines($nuGetApiFile)

[string]$moduleName         = [System.IO.Path]::GetFileNameWithoutExtension($PSScriptRoot)
[string]$modulePath         = [System.IO.Path]::Combine($PSScriptRoot, 'Module', $moduleName)
[string]$moduleRootName     = "$($moduleName).psm1"
[string]$moduleManifestName = "$($moduleName).psd1"
[string]$moduleManifestPath = [System.IO.Path]::Combine($modulePath, $moduleManifestName)
[string[]]$manifestContent  = Get-Content -Path $moduleManifestPath -Encoding UTF8
[string]$powerShellVersion  = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
[string]$functionPublic     = [System.IO.Path]::Combine($modulePath, 'Functions', 'Public')
[string[]]$funcToExport     = ([System.IO.FileInfo[]]([System.IO.Directory]::EnumerateFiles($functionPublic, '*.ps1'))).BaseName

[string]$funcExportString   = [string]::Join(', ', ($funcToExport.ForEach({"`'$_`'"})))
[string]$functionsToExport  = "FunctionsToExport = $funcExportString"
[string]$versionOldRaw      = $manifestContent -match '^\s*ModuleVersion\s*='
[version]$versionOldValue   = $versionOldRaw.Split('=').Where({$_})[-1].Trim("' ")
switch ($versionOldValue)   {
    {$_.Revision -lt 0}     {
        [int]$revisionNew   = 0
    }
    {$_.Build -lt 0}        {
        [int]$buildNew      = 0
    }
    {$_.Minor -lt 0}        {
        [int]$minorNew      = 0
    }
    {$_.Major -lt 0}        {
        [int]$majorNew      = 0
    }
    Default {
        [int]$revisionNew   = $versionOldValue.Revision + 1
        [int]$buildNew      = $versionOldValue.Build
        [int]$minorNew      = $versionOldValue.Minor
        [int]$majorNew      = $versionOldValue.Major
    }
}
[string]$versionNewValue    = "$($majorNew).$($minorNew).$($buildNew).$($revisionNew)"
[string]$versionToManifest  = "ModuleVersion = `'$versionNewValue`'"
[string[]]$contentNew       = (($manifestContent -replace 'ModuleVersion.*', $versionToManifest) `
                                                -replace 'FunctionsToExport.*', $functionsToExport) `
                                                -replace 'PowerShellVersion.*', "PowerShellVersion = `'$powerShellVersion`'"

switch ($Action) {
    'Manifest'  {
        Set-Content -Encoding UTF8 -Path $moduleManifestPath -Value $contentNew
    }
    'Publish'   {
        Publish-Module -Path $modulePath -Repository $nuGetRepoName -NuGetApiKey $nuGetApiKey -Verbose
    }
    'All'       {
        Set-Content -Encoding UTF8 -Path $moduleManifestPath -Value $contentNew
        Publish-Module -Path $modulePath -Repository $nuGetRepoName -NuGetApiKey $nuGetApiKey -Verbose
    }
    Default {
        Write-Host -ForegroundColor Yellow "No action selected!"
    }
}