Param(
    [string]$webConfig,
    [string]$connectionStringName,
    [string]$newConnectionStringValue,
    [string]$deployUser,
    [string]$deployPass,
    [string]$serverName
)

. .\CommonAuth.ps1 
 
 $session = New-Deploy-Session($deployUser, $deployPass, $serverName)

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