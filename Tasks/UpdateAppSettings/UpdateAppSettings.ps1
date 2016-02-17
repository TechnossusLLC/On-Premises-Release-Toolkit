Param(
    [string]$webConfig,
    [string]$key,
    [string]$value,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName

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