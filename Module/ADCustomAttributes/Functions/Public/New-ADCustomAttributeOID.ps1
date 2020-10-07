#   Inspired by this: https://gallery.technet.microsoft.com/scriptcenter/Generate-an-Object-4c9be66a
#   Generates an object identifier (OID) using a GUID and the OID prefix 1.2.840.113556.1.8000.2554 (or any other).
#   Gist on my GitHub:  https://gist.github.com/drlsdee/713171eb3eb847b7b30e2dc6ab4f27ee
function New-ADCustomAttributeOID {
    [CmdletBinding()]
    param (
        # OID Prefix
        [Parameter()]
        [string]
        $Prefix     = '1.2.840.113556.1.8000.2554'
    )
    [string]$GUID   = [System.Guid]::NewGuid().Guid.Replace('-','')

    [int]$step          = 4

    [string[]]$Parts    = ,$Prefix + @(
        for ($i = 0; $i -le 26; $i = $i + $step) {
            if ($i -ge 20) {
                [int]$step  = 6
            }
            [uint64]::Parse($GUID.Substring($i,$step),'AllowHexSpecifier')
        }
    )

    [string]$OID    = [string]::Join('.', $Parts)

    return $OID
}
