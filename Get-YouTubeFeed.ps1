[CmdletBinding()]
param (
    [Parameter(
        Mandatory,
        Position = 0,
        ValueFromPipeline,
        ValueFromPipelineByPropertyName
    )]
    [ValidateNotNullOrEmpty()]
    [uri[]]
    $uris
)

ForEach-Object -InputObject $uris -Parallel {
    Invoke-WebRequest "$_" -HttpVersion 3.0 -Headers @{'Accept-Encoding' = 'gzip' } 
    | Select-Object -ExpandProperty Content 
    | Select-Xml '*' 
    | Select-Object -ExpandProperty Node
}
