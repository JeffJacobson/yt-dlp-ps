using namespace System.IO


<#
.SYNOPSIS
    Finds all of the files ending with the ".part" extension
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-PartialDownloadFiles | Select-Object -ExpandProperty YouTubeUri | Select-Object -ExpandProperty OriginalString
    Get all of the URLs for partially downloaded files.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
function Get-PartialDownloadFiles {
    $re = [regex]'(?inx)
    # Opening square bracket
    (?<=\[)
        # YouTube ID
        (?<YouTubeId>[^\[\]]+)
    # Closing square bracket
    \]
    (\.f
    (?<FragmentNo>
        \d+
    ))?
    (?<Extension>
        (\.\w+)*
    )
    # The final .part extension
    \.part'
    Get-ChildItem . -Filter '*.part' -File -Recurse |
    ForEach-Object {
        $match = $re.Match($_.Name)
        $youTubeId = ($match)?.Groups['YouTubeId']?.Value
        $number = ($match)?.Groups['FragmentNo']?.Value
        $ext = ($match)?.Groups['Extension']?.Value 
        [PSCustomObject]@{
            YouTubeId  = $youTubeId
            Extension  = $ext
            YouTubeUri = $youTubeId ? [uri]"https://www.youtube.com/watch?v=$youTubeId" : $null
            FragmentNo = $number ?? [int]::Parse($number)
            File       = $_
        }
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


        [ValidateNotNull()]
        [regex]
        $YoutubeIdRe = '(?<=\[)[^\[\]]+(?=\])',

        # Known strings that would falsely be detected as YouTube IDs.
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

