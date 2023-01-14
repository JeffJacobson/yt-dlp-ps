<#
.SYNOPSIS
    Finds all of the files ending with the ".part" extension
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-PartialDownloadFiles | Select-Object -ExpandProperty YouTubeUri | Select-Object -ExpandProperty OriginalString
    Get all of the URLs for partially downloaded files.
.EXAMPLE
    PS C:\> .\Get-PartialDownloadFiles.ps1 | Format-List

    VideoTitle : The Hidden Life of Fred Gwynne Herman Munster.mp4.part
    File       : C:\Users\JoeUser\Downloaded Videos\The Hidden Life of Fred Gwynne Herman Munster.mp4.part

    YouTubeId     : 8dtv_P466Kw
    YouTubeUrl    : https://www.youtube.com/watch?v=8dtv_P466Kw
    FullExtension : .f271.webm.part
    FragmentNo    : 271
    Extension     : .webm
    PartOfPart    : 
    VideoTitle    : Almost Live!   vs  The Media
    File          : C:\Users\JoeUser\Downloaded Videos\Almost Live\Almost Live!   vs  The Media [8dtv_P466Kw].f271.webm.part

    YouTubeId     : rcYINGCmzZc
    YouTubeUrl    : https://www.youtube.com/watch?v=rcYINGCmzZc
    FullExtension : .f248.webm.part
    FragmentNo    : 248
    Extension     : .webm
    PartOfPart    : 
    VideoTitle    : Classic Popeye： Popeye and the Polite Dragon AND MORE (Episode 53)
    File          : C:\Users\JoeUser\Downloaded Videos\Cartoons\Popeye and Friends Official\Classic Popeye： Popeye and the Polite Dragon AND MORE (Episode 53) [rcYINGCmzZc].f248.webm.part
.EXAMPLE
    
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $GroupByFolder
)

class VideoInfo {
    [regex]
    static $VideoPartRegex = '(?inx)
    # Opening square bracket
    \[
        # YouTube ID
        (?<YouTubeId>[^\[\]]+)
    # Closing square bracket
    \]
    (?<FullExtension>
        (\.f
        (?<FragmentNumber>
            \d+
        ))?
        (?<Extension>
            (\.\w+)*
        )
        # The final .part extension
        \.part
        (
            -
            (
                Frag(?<PartOfPart>\d+)
            )
            \.part
        )?
    )$'


    [string]
    $YouTubeId

    [uri]
    $YouTubeUrl
    
    [string]
    $FullExtension

    [int]
    $FragmentNumber

    [string]
    $Extension

    [int]
    $PartOfPart

    [string]
    $VideoTitle

    [System.IO.FileInfo]
    $File

    [VideoInfo]
    static Parse([System.IO.FileInfo]$file, [bool]$throwExceptionOnMismatch = $false) {
        $match = [VideoInfo]::VideoPartRegex.Match($file.Name)
        if (-not $match.Success) {
            if ($throwExceptionOnMismatch) {
                throw New-Object System.FormatException "Invalid format: $($file.Name)"
            }
            return $null
        }

        $params = [ordered]@{
            YouTubeId      = $match.Groups['YouTubeId'].Value
            FullExtension  = $match.Groups['FullExtension'].Value
            FragmentNumber = $match.Groups['FragmentNumber'].Value
            Extension      = $match.Groups['Extension'].Value
            PartOfPart     = $match.Groups['PartOfPart'].Value
            # Trim off the part that matched the regex from the end of the filename to get the video title.
            VideoTitle     = $_.Name.Replace($match.Value, '').TrimEnd()
            File           = $file
            YouTubeUrl     = $match.Groups['YouTubeId'].Success ? "https://www.youtube.com/watch?v=$($match.Groups['YouTubeId'])" : $null
        }

        return [VideoInfo]$params
    }
}



Get-ChildItem . -Filter '*.part' -File -Recurse |
ForEach-Object {
    [VideoInfo]::Parse($_.Name, $false)
}