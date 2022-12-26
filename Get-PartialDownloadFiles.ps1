<#
.SYNOPSIS
    Finds all of the files ending with the ".part" extension
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> Get-PartialDownloadFiles | Select-Object -ExpandProperty YouTubeUri | Select-Object -ExpandProperty OriginalString
    Get all of the URLs for partially downloaded files.
.EXAMPLE
    C:> .\Get-PartialDownloadFiles.ps1 
    >> | Select-Object -Property "*",(@{Name='ParentDirectory';Expression={($_.File).Directory}})
    >> | Sort-Object -Property ParentDirectory,Title
    >> | Format-Table -GroupBy ParentDirectory
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
$re = [regex]'(?inx)
    # Opening square bracket
    \[
        # YouTube ID
        (?<YouTubeId>[^\[\]]+)
    # Closing square bracket
    \]
    (?<FullExtension>
        (\.f
        (?<FragmentNo>
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
Get-ChildItem . -Filter "*.part" -File -Recurse |
ForEach-Object {
    $match = $re.Match($_.Name)

    
    
    $matchGroupValues = [ordered]@{}

    ($match)?.Groups?.Keys 
    # The first match key will be 0, or the entire match.
    | Select-Object -Skip 1 
    | ForEach-Object {
        $value = $match.Groups[$_]
        $matchGroupValues.Add($_, $value)
        if ($_ -ieq "YouTubeId") {
            $matchGroupValues.Add("YouTubeUrl", "https://www.youtube.com/watch?v=$value")
        }
    }

    $matchGroupValues.Add("VideoTitle", ($_.Name.Replace($match.Value,"").TrimEnd()))
    $matchGroupValues.Add("File", $_)

    [PSCustomObject]$matchGroupValues 
    
}