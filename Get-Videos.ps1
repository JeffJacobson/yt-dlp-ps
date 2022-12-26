Import-Module .\video-tools.psm1 -Scope Local

# Get extensions

Set-Variable DebugPreference -Value "Continue"

Get-ChildItem . -Recurse -File
| Select-Object -Property *, (
    @{
        Name       = 'YouTubeId'
        Expression = { return Get-YouTubeId($_) } 
    }), (@{
        Name       = "FileExtension"
        Expression = { return Get-FileExtension($_) }
    })
| Format-Table -GroupBy YouTubeId -Property Extension, FullName
