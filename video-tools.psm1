
New-Variable videoExtensions @(
    '.m4v',
    '.mkv',
    '.mp3',
    '.mp4',
    '.ogv'
) -Option Constant -Scope "Script"
    
function Get-YouTubeId {
    [CmdletBinding()]
    param (
        # The input file. The name of this file will be
        # checked against the YouTubeIdRe regex to attempt
        # YouTube ID extraction from filename.
        [Parameter(Mandatory,Position=0)]
        [System.IO.FileInfo]
        $InputFile,


        [ValidateNotNull()]
        [regex]
        $YoutubeIdRe = '(?<=\[)[^\[\]]+(?=\])',

        # Known strings that would falsely be detected as YouTube IDs.
        $InvalidIds = @("hokuto-no-ken")
    )
            
    process {
        Write-Debug "YoutubeIdRe = $YoutubeIdRe"
        if (-not $YoutubeIdRe) {
            Write-Error "$YoutubeIdRe" -ErrorAction Stop
        }
        $match = $YoutubeIdRe.Match($InputFile.Name)
        
        if ($match.Success -and ($match.Value -inotin $InvalidIds)) {
            return $match.Value
        }
        return $null
    }
}

<#
.SYNOPSIS
    Gets the extension of a file.
#>
function Get-FileExtension {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true,
            Position = 0,
            ParameterSetName = "ParameterSetName",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $InputFile,

        # Extensions to check for, such as ".info.json", which 
        # built-in functions might not detect.
        [Parameter(
            HelpMessage = 'Extensions to check for, such as ".info.json", which built-in functions might not detect.'
        )]
        [string[]]
        $ExtensionsToCheckFor = @(".info.json"),

        [switch]
        $ReturnNameWOExtension
    )
    

    foreach ($current in $InputFile) {
        Write-Debug "Current file: $current"
        $outExt = $null
        foreach ($ext in $ExtensionsToCheckFor) {
            if ($current.EndsWith($ext)) {
                $outExt = $ext
                break
            }
        }
        if (-not $outExt) {
            if ($ReturnNameWOExtension) {
                [regex]::Match("(?<=[/\\]).+(?<=$([regex]::Escape($outExt))$)", $current).Value
            }
            else {
                ([System.IO.FileInfo]$current).Extension
            }
        }
        else {
            if ($ReturnNameWOExtension) {
                [regex]::Match("(?<=[/\\].+)$([regex]::Escape($outExt))$", $current).Value
            }
            else {
                ([System.IO.FileInfo]$current).Extension
            }
        }
    }
}
