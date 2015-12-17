Param(
    [string]$webConfig,
    [string]$key,
    [string]$value,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

Import-Module ../Common/CommonAuth   
   
$session = New-Deploy-Session -ServerName $serverName -DeployUser $deployUser -DeployPass $deployPass

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