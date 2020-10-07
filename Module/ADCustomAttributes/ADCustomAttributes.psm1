[string]$funcFolderPrivate  = "$PSScriptRoot\Functions\Private"
[string]$funcFolderPublic   = "$PSScriptRoot\Functions\Public"

if ([System.IO.Directory]::Exists($funcFolderPrivate)) {
    [string[]]$funcScriptsPrivate   = [System.IO.Directory]::EnumerateFiles($funcFolderPrivate, '*.ps1')
}


if ([System.IO.Directory]::Exists($funcFolderPublic)) {
    [string[]]$funcScriptsPublic    = [System.IO.Directory]::EnumerateFiles($funcFolderPublic, '*.ps1')
}

[string[]]$functionsToExport    = $funcScriptsPublic.ForEach({
    [System.IO.Path]::GetFileNameWithoutExtension($_)
})

[string[]]$functionsToImport    = $funcScriptsPrivate + $funcScriptsPublic

$functionsToImport.ForEach({
    . $_
})

$functionsToExport.ForEach({
    Export-ModuleMember -Function $_
})