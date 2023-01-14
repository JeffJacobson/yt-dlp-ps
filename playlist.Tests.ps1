BeforeAll {
    Import-Module $PSCommandPath.Replace('.Tests.ps1', '.psm1') -Force -Scope Local
}

Describe "Get-Playlists" {
    It "Can parse type names" {
        Get-TypeData PlaylistInfo | Write-Debug
        Get-InfoType("playlist") | Should -Be [PlaylistInfo]
    }
    It "Returns expected output" -Skip {
        Get-InfoFiles . -InfoFileTypes "playlist" -Recurse -OutVariable items
        | ForEach-Object {
            Write-Debug $_
        }
        
    }
}
