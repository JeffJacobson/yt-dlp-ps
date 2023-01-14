using namespace System.Collections.Generic

$ErrorActionPreference = 'Stop'
New-Variable HeaderRe -Value ([regex]'(?<=^\s{2})[^\s-][^:]+') -Option Constant -Scope Script

New-Variable OptionRe -Value ([regex]'(?m)(?<=^\s{4})\S.+?$(^\s{10,}}.+$)*') -Option Constant -Scope Script


# function Get-YTDlp () {
#     Get-Command yt-dlp -All
#     | Select-String $HeaderRe,$OptionRe -Raw
#     | ForEach-Object {
#         $match = [regex]::Match($_.Path, '(?<=Python)(?<major>3)(?<minor>\d+)')

#         $version = $match.Success ? [version]::new(
#             "$($match.Groups[1]).$($match.Groups[2])"
#         ) : $null

#         [PSCustomObject]@{
#             Command = $_
#             Version = $version
#         }
#     }
#     | Sort-Object -Property PythonVersion -Descending
#     | Select-Object -First 1 -ExpandProperty Command
# }

# $ytDlp = Get-YTDlp

$content = Invoke-Expression "yt-dlp -h"

$category = $null

foreach ($line in $content) {
    if ($line -match '^\S') {
        continue
    }
    $categoryMatch = $HeaderRe.Match($line)
    if ($categoryMatch.Success) {
        $category = $categoryMatch.Value
        continue
    }

    $optionMatch = $OptionRe.Match($line)
    if ($optionMatch.Success) {
        [PSCustomObject]@{
            Category = $category
            Option   = ($optionMatch).Value -split '\s{10,}'
        }
    }
    $i++
}