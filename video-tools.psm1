using namespace System.IO

<#
Represents a partially downloaded video found in
the file system.
#>
class VideoPart {
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

    [VideoPart]
    static Parse([System.IO.FileInfo]$file, [bool]$throwExceptionOnMismatch = $false) {
        $match = [VideoPart]::VideoPartRegex.Match($file.Name)
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

        return [VideoPart]$params
    }
}

<#
.SYNOPSIS
    Finds all of the files ending with the ".part" extension
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-PartialDownloadFiles | Select-Object -ExpandProperty YouTubeUri | Select-Object -ExpandProperty OriginalString
    Get all of the URLs for partially downloaded files.
.EXAMPLE
    Get-PartialDownloadFiles | Format-List

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
    Get-PartialDownloadFiles | Select-Object -Property *,@{
    >> Name='Directory'
    >> Expression={
    >>    $_.File.Directory
    >> }
    >> }
    >> | Group-Object -Property Directory
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Get-PartialDownloadFiles {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $GroupByFolder
    )

    Get-ChildItem -Filter '*.part' -File -Recurse |
    ForEach-Object {
        [VideoPart]::Parse($_, $false)
    }
}

<#
.SYNOPSIS
    Checks folders recursively and resumes any partial 
    downloads that are found.
#>
function Resume-PartialDownloads {
    # Find all the .part files and the folders they reside in.
    Get-PartialDownloadFiles 
    | Select-Object -Property YouTubeUrl, @{
        Name       = 'Folder'
        Expression = {
            $_.File.Directory
        }
    } -Unique
    # Group the objects by folder
    | Group-Object 'Folder'
    # Run yt-dlp for the YouTube URLs corresponding to the .part
    # files in the folder.
    | ForEach-Object -Parallel {
        $directory = $_.Name
        Write-Host "Current directory is $directory"
        $urls = $_.Group | Select-Object -ExpandProperty YouTubeUrl
        # Change to that directory
        Set-Location $directory
        # Start yt-dlp for those URLs.
        Start-Process 'yt-dlp' $urls -Wait -NoNewWindow
    }
}


New-Variable videoExtensions @(
    '.m4v',
    '.mkv',
    '.mp3',
    '.mp4',
    '.ogv'
) -Option Constant -Scope 'Script'
    
function Get-YouTubeId {
    [CmdletBinding()]
    param (
        # The input file. The name of this file will be
        # checked against the YouTubeIdRe regex to attempt
        # YouTube ID extraction from filename.
        [Parameter(Mandatory, Position = 0)]
        [System.IO.FileInfo]
        $InputFile,

        [Parameter()]
        [ValidateNotNull()]
        [regex]
        $YoutubeIdRe = '(?<=\[)[^\[\]]+(?=\])',

        # Known strings that would falsely be detected as YouTube IDs.
        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        $InvalidIds = @('hokuto-no-ken')
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


function ConvertTo-FileHashes {
    param (
        # Specifies a path to one or more locations.
        [ValidateNotNull()]
        [FileInfo]
        $HashCsvFile
    )
    
    return [Microsoft.PowerShell.Commands.FileHashInfo[]](Get-Content $HashCsvFile | ConvertFrom-Csv)
}

<#
.EXAMPLE
    Get-DuplicateFiles(ConvertTo-FileHashes .\FileHashes.csv) | Select-Object -ExpandProperty Group | Format-Table -GroupBy Hash -Property Path
    Path
    ----
    C:\Videos\Feature Presentation - Odeon Theatre (unknown date) [4K] [FTD-0800] [RQeneZqyX7o].info.json
    C:\Videos\Trailers\Feature Presentation - Odeon Theatre (unknown date) [4K] [FTD-0800] [RQeneZqyX7o].info.json

    Hash: FFFCBABBFD2DDD4ED59557C955DA7C69

    Path
    ----
    C:\Videos\If - Timi Yuro (1950) Scopitone S-1050 [4K] [FTD-0649] [K8wi7hGNYbg].info.json
    C:\Videos\Trailers\If - Timi Yuro (1950) Scopitone S-1050 [4K] [FTD-0649] [K8wi7hGNYbg].info.json
#>
function Get-DuplicateFiles {
    param (
        [Parameter(
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.FileHashInfo[]]
        $FileHashes
    )

    $FileHashes
    | Group-Object Hash
    | Where-Object Count -GT 1
}

