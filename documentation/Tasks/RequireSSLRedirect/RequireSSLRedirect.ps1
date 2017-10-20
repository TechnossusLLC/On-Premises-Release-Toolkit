[CmdletBinding(DefaultParameterSetName = 'None')]
Param(
    [string] [Parameter(Mandatory = $true)]
    $name,
    
    [string] [Parameter(Mandatory = $true)]
    $serverName,
    
    [string] [Parameter(Mandatory = $false)]
    $deployUser,
    
    [string] [Parameter(Mandatory = $false)]
    $deployPass,   
    
    [string] [Parameter(Mandatory = $false)]
    $installWebPlatformInstaller
)
 
Import-Module .\CommonAuth.psm1 

$session = New-Deploy-Session -DeployUser $deployUser -DeployPass $deployPass -ServerName $serverName
 
invoke-command -session $session -scriptblock {
    Param([string]$name, [string]$installWebPlatformInstaller)
 
    Set-ExecutionPolicy RemoteSigned
      
    if($installWebPlatformInstaller -eq "true"){
        ##### 
        # Install URL Rewrite 
        #
        write-host Downloading WebPlatform Installer
        $source = "http://download.microsoft.com/download/F/4/2/F42AB12D-C935-4E65-9D98-4E56F9ACBC8E/wpilauncher.exe"
        $destination = "$env:temp\wpilauncher.exe"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $destination)

        ####Start WEB Platform Installer
        Start-Process -FilePath $destination 

        # Wait for Installation to Complete 
        Start-Sleep -Seconds 30
    }
    
    # Web Platform Installer CommandLine Tool 
    $WebPiCMd = 'C:\Program Files\Microsoft\Web Platform Installer\WebpiCmd-x64.exe'
    Start-Process -wait -FilePath $WebPiCMd -ArgumentList "/install /Products:UrlRewrite2 /AcceptEula /OptInMU /SuppressPostFinish" 

    # Add Management Tools 
    Add-WindowsFeature Web-Server -IncludeManagementTools
    import-module webAdministration
    
    Write-Host "Updating site IIS:\Sites\$name"

    # Create URL Rewrite Rules
    Add-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webserver/rewrite/rules" -name "." -value @{name='HTTP to HTTPS Redirect'; patternSyntax='ECMAScript'; stopProcessing='True'}
    Set-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webserver/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']/match" -name url -value "(.*)"
    Add-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webserver/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']/conditions" -name "." -value @{input="{HTTPS}"; pattern='^OFF$'}
    Set-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webServer/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']/action" -name "type" -value "Redirect"
    Set-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webServer/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']/action" -name "url" -value "https://{HTTP_HOST}/{R:1}"
    Set-WebConfigurationProperty -pspath "IIS:\Sites\$name" -filter "system.webServer/rewrite/rules/rule[@name='HTTP to HTTPS Redirect']/action" -name "redirectType" -value "SeeOther" 


 
} -ArgumentList $name, $installWebPlatformInstaller
 
    Remove-PSSession $session





