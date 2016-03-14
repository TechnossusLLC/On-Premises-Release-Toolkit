[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [string] [Parameter(Mandatory = $true)]
    $name,
    
    [string] [Parameter(Mandatory = $true)]
    $hostName,

    [string] [Parameter(Mandatory = $true)]
    $serviceAccountName,
    
    [string] [Parameter(Mandatory = $true)]
    $serverName,
    
    [string] [Parameter(Mandatory = $false)]
    $deployUser,
    
    [string] [Parameter(Mandatory = $false)]
    $deployPass,   
    
    [string] [Parameter(Mandatory = $false)]
    $certificateThumbprint,
    
    [string] [Parameter(Mandatory = $false)]
    $overridePath,
    
    [string] [Parameter(Mandatory = $false)]
    $enableThirtyTwoBit
)
 
Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName
 
invoke-command -session $session -scriptblock {
    Param([string]$name, [string]$hostName, [string]$serviceAccountName, [string]$certificateThumbprint, [string]$overridePath, [string]$enableThirtyTwoBit)
 
    Set-ExecutionPolicy RemoteSigned
 
    # Install IIS if required
    Import-Module Servermanager
 
    $check = Get-WindowsFeature | Where-Object {$_.Name -eq "web-server"}
 
    If (!($check.Installed)) {
     Write-Host "Adding web-server"
     Add-WindowsFeature web-server
    }
   
    $physicalPath = "C:\apps\" + $name
    
    if([string]::IsNullOrEmpty($overridePath)){
      $physicalPath = "C:\apps\" + $name
    } else {      
      $physicalPath = $overridePath    
    }

    try
    {
        if((Get-Website -Name $name))
        {
            "Site Exists. Deleting!"
            Remove-Website -Name $name
        }
    }
    catch
    {
        "Folder did not exist"
    }
 
    "Creating App Pool"
    # Create Application Pool
    
     try {
     	$poolCreated = Get-WebAppPoolState $name –errorvariable myerrorvariable
	if($poolCreated)
	{
        	Remove-WebAppPool $name
     	}
     }	
	catch
	{
		"App pool does not exist"
	}
    
     $appPool = New-WebAppPool -Name $name
     Set-ItemProperty IIS:\AppPools\$name -name processModel -value @{userName="$serviceAccountName";identitytype=3}
     Set-ItemProperty IIS:\AppPools\$name managedRuntimeVersion v4.0    
    
    Write-Host "32-bit Mode: $enableThirtyTwoBit"
    Set-ItemProperty IIS:\AppPools\$name -name enable32BitAppOnWin64 -Value "$enableThirtyTwoBit"
   
    "Creating Folder"
    # Create Folder for the website
    if(!(Test-Path $physicalPath)) {
     md $physicalPath
    }
    else {
     Remove-Item "$physicalPath\*" -recurse -Force
    }
 
    $site = Get-WebSite | where { $_.Name -eq $name }
    if($site -eq $null)
    {
     Write-Host "Creating site: $name $physicalPath"   
     New-WebSite -PhysicalPath $physicalPath -Name $name -HostHeader $hostName -ApplicationPool $name  
    }

    if($certificateThumbprint){
        Write-Host "Using SSL"
        Write-Host "IIS:\SslBindings\*!443!$hostName"
        New-WebBinding -Name $name -Protocol "https" -Port 443 -HostHeader $hostName -SslFlags 1
        try{
        New-Item -Path "IIS:\SslBindings\*!443!$hostName" -Thumbprint $certificateThumbprint -SSLFlags 1
        }
        catch{

        }
    } else{
     Write-Host "Not using SSL"
    }

 
} -ArgumentList $name, $hostName, $serviceAccountName, $certificateThumbprint, $overridePath, $enableThirtyTwoBit
 
    Remove-PSSession $session





