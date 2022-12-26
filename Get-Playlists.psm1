# _type                  : playlist

function Get-InfoFiles {
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Path to one or more locations.')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $InputPath = '.',

        [Parameter()]
        [AllowNull()]
        [string[]]
        $InfoFileTypes,

        [switch]
        $Recurse,

        [switch]
        $ReturnOnlyPropertyNames,

        [switch]
        $AsHashTable
    )
    process {
        # Define parameters for Get-ChildItems
        $gciParams = @{
            Path    = $InputPath
            Filter  = '*.json'
            File    = $true
            Recurse = $Recurse
        }

        # Define parameters for JSON parsing.
        $cfjParams = @{
            AsHashTable = $AsHashTable
        }

        Get-ChildItem @gciParams | ForEach-Object {
            $o = $_ | Get-Content | ConvertFrom-Json @cfjParams

            if (-not $InfoFileTypes -or $o._type -in $InfoFileTypes) {
                if ($ReturnOnlyPropertyNames) {
                    return $o.Keys
                }
                else {
                    return [PSCustomObject]@{
                        File = $_
                        Data = $o
                    }
                }
            }
        } 
            
    }
}

<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Get-InfoFiles -Recurse -AsHashtable -InfoFileTypes playlist |  Get-InfoJsonProperties
    uploader
    uploader_id                                                                                                             
    uploader_url                                                                                                            
    thumbnails                                                                                                              
    tags                                                                                                                    
    playlist_count                                                                                                          
    channel_follower_count                                                                                                  
    channel                                                                                                                 
    channel_id                                                                                                              
    channel_url                                                                                                             
    id                                                                                                                      
    title                                                                                                                   
    description                                                                                                             
    _type                                                                                                                   
    webpage_url                                                                                                             
    webpage_url_basename                                                                                                    
    webpage_url_domain                                                                                                      
    extractor                                                                                                               
    extractor_key                                                                                                           
    epoch                                                                                                                   
    _version                                                                                                                
    view_count
    availability                                                                                                            
    modified_date                                                                                                           
    thumbnail
    age_limit   
#>


function Get-InfoJsonProperties {
    param (
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [PSObject[]]
        $JsonInfos
    )

    begin {
        $progParams = @{
            Activity = 'Gathering property names'
        }
        Write-Progress @progParams
        $outputSet = [System.Collections.Generic.HashSet[string]]::new()
    }
    process {
        $PSItem 
        | Select-Object -ExpandProperty 'Data' 
        | ForEach-Object {
            $_
        }
        | Select-Object -ExpandProperty Keys 
        | ForEach-Object {
            if ($outputSet.Add($_)) {
                Write-Debug "$($_.GetType())"
                $_
                Write-Progress @progParams -Status "Found $($outputSet.Count) items"
            }
        }
    }
    end {
        Write-Progress @progParams -Completed
        Write-Host "Found $($outputSet.Count) items" -ForegroundColor (($outputSet.Count -gt 0) ? "Green" : "DarkRed" )
    }
}

# | ForEach-Object {
#     $o = ($_ | Get-Content | ConvertFrom-Json)
#     # if ($o._type -ieq "playlist") {
#     Write-Output ([PSCustomObject]@{
#             File    = $_
#             Content = $o
#         })
#     # }
# }