BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psm1') -Force -Scope Local
}

Describe "Get-Playlists" {
    It "Returns expected output" {
        Get-InfoFiles . -InfoFileTypes "playlist" -Recurse -OutVariable items
        | ForEach-Object {
            Write-Debug $_
        }
        
    }
}
