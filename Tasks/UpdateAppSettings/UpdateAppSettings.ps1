Param(
    [string]$webConfig,
    [string]$key,
    [string]$value,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

. .\CommonAuth.ps1 
 
 $session = New-Deploy-Session($deployUser, $deployPass, $serverName)

invoke-command -session $session -scriptblock {
    Param(
        [string]$webConfig,
        [string]$key,
        [string]$value
    )
                       
    $doc = (Get-Content $webConfig) -as [Xml]
    
    $node = $doc.SelectSingleNode('configuration/appSettings/add[@key="' + $key + '"]')
    $node.Attributes['value'].Value = $value
    $doc.Save($webConfig)
} -ArgumentList $webConfig, $key, $value