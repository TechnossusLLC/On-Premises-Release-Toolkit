Param(
    [string]$webConfig,
    [string]$connectionStringName,
    [string]$newConnectionStringValue,
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
    [string]$connectionStringName,
    [string]$newConnectionStringValue
    )
    
    $doc = (Get-Content $webConfig) -as [Xml]
    
    $root = $doc.get_DocumentElement();
    
    $mycon=$root.connectionStrings.add|?{$_.name -eq $connectionStringName}
    
    Write-Host "Old Connection String: "$mycon.connectionString
    
    $mycon.SetAttribute("connectionString","$newConnectionStringValue")
    Write-Host "New Connection String: "$mycon.connectionString
    
    $doc.Save($webConfig)
} -argumentlist $webConfig,$connectionStringName,$newConnectionStringValue