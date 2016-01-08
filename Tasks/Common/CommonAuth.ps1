Function Get-PSCredential($User,$Password)
{
 $SecPass = convertto-securestring -asplaintext -string $Password -force
 $Creds = new-object System.Management.Automation.PSCredential -argumentlist $User,$SecPass
 Return $Creds
}    

Function New-Deploy-Session($DeployUser, $DeployPass, $ServerName){
	$credential = Get-PSCredential -User $DeployUser -Password $DeployPass
	return New-PSSession $ServerName -Credential $credential
    
    if($DeployUser){  
        "Using Credentials"
        $credential = Get-PSCredential -User $DeployUser -Password $DeployPass
        return New-PSSession $ServerName -Credential $credential
    } else {
        return New-PSSession $ServerName     
    }
 
}

Export-ModuleMember -Function New-Deploy-Session
   