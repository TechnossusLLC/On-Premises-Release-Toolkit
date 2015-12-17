Param(
    [string]$webConfig,
    [string]$key,
    [string]$value,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

Function Get-PSCredential($User,$Password)
{
 $SecPass = convertto-securestring -asplaintext -string $Password -force
 $Creds = new-object System.Management.Automation.PSCredential -argumentlist $User,$SecPass
 Return $Creds
}    
   
$credential = Get-PSCredential -User $deployUser -Password $deployPass
$session = New-PSSession $serverName -Credential $credential

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