Param(
    [string]$parentName,
    [string]$name,
    [string]$path,
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
    Param([string]$parentName, [string]$name, [string]$path)
 
    Set-ExecutionPolicy RemoteSigned
    
    Import-Module Servermanager 
    Write-Host "Physical Path: c:\apps\$path"
        
    # Create the directory if it doesn't exist
    New-Item -ItemType Directory -Force -Path "c:\apps\$path" 
    
    New-WebApplication -Site $parentName -Name $name -PhysicalPath "c:\apps\$path" -ApplicationPool $parentName -force

} -ArgumentList $parentName, $name, $path
 
Remove-PSSession $session





