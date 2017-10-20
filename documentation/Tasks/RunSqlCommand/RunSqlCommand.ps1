[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [string] [Parameter(Mandatory = $true)]
    $command,
    
    [string] [Parameter(Mandatory = $true)]
    $serverName,
    
     [string] [Parameter(Mandatory = $true)]
    $databaseName,
    
    [string] [Parameter(Mandatory = $false)]
    $deployUser,
    
    [string] [Parameter(Mandatory = $false)]
    $deployPass
)
 
Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName
 
invoke-command -session $session -scriptblock {
    Param([string]$command, [string]$databaseName)
 
   Invoke-Sqlcmd -Query "$command" -Database "$databaseName"

 
} -ArgumentList $command, $databaseName
 
    Remove-PSSession $session





