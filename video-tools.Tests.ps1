BeforeAll {
    Import-Module .\video-tools.psm1 -Force
}

AfterAll {
    Uninstall-Module video-tools
}



Describe "video-tools" {
    It "does something useful" {
        # Initialize hashset, which will hold unique YouTube IDs.
        $youtubeIds = New-Object System.Collections.Generic.HashSet[string]
        Get-ChildItem . -Recurse -File | ForEach-Object {
            $currentId = Get-YouTubeId $_
            if ($null -ne $currentId) {
                Write-Debug "Current YouTube ID: $currentId"
                $youtubeIds.Add($currentId)
            }
        }
        
        Write-Debug "There were $($youtubeIds.Count) YouTubeIDs found."
        
        $youtubeIds.Count | Should -BeGreaterThan 0
        $youtubeIds | Should -Not -Contain "hokuto-no-ken"
    }
}
