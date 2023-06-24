<#
.SYNOPSIS
    Downloads sound effect audio files from TrekCore website.
.DESCRIPTION
    Downloads sound effect audio files from TrekCore website.
#>

$ErrorActionPreference = 'Stop'

$url = 'https://www.trekcore.com/audio/'

$outFolder = $PSScriptRoot

$response = Invoke-WebRequest $url -HttpVersion 3.0 -Authentication None -Method Get -ContentType 'text/html'

$response.Links | Foreach-Object -ThrottleLimit 5 -Parallel {
    #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
    <#
    outerHTML : <a href="weapons/tos_ship_phaseer_2.mp3">TOS Ship Phaser 2</a>
    tagName   : A
    href      : weapons/tos_ship_phaseer_2.mp3
    #>
    $outerHTML = [regex]::Replace($PSItem.outerHTML, '\n+', " ")
    $href = $PSItem.href

    $re = [regex]::new('>([^<]+)<', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $match = $re.Match($outerHTML)

    $description = $null

    if ($match.Success) {
        $description = $match.Groups[1].Value.Trim()
    }
    else {
        Write-Warning "The text '$outerHTML' did not match the expected format: $re."
    }

    $outPath = Join-Path $USING:outFolder $href

    $fileUrl = [uri]::new($USING:url, $href)


    $outDir = [System.IO.Path]::GetDirectoryName($outPath)

    if (-not (Test-Path $outDir)) {
        New-Item $outDir -ItemType Directory
    }

    if (Test-Path $outPath) {
        Write-Host "The file $outPath already exists. Skipping."
        continue
    }
    else {
        Write-Host "Downloading '$description' to $outPath from $fileUrl"
        Invoke-WebRequest $fileUrl | Out-File -LiteralPath $outPath
    }

}