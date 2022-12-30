[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName
    )]
    [ValidateNotNullOrEmpty()]
    [uri[]]
    $uris = 'https://www.youtube.com/feeds/videos.xml?channel_id=UCioQmyB0WnsT9jwMczLpI7g'
)

ForEach-Object -InputObject $uris -Parallel {
    Invoke-WebRequest "$_" -HttpVersion 3.0 -Headers @{'Accept-Encoding' = 'gzip' } 
    | Select-Object -ExpandProperty Content 
    | Select-Xml '*' 
    | Select-Object -ExpandProperty Node
}
