Function Get-PSCredential($User,$Password)
{
 $SecPass = convertto-securestring -asplaintext -string $Password -force
 $Creds = new-object System.Management.Automation.PSCredential -argumentlist $User,$SecPass
 Return $Creds
}    

Function New-Deploy-Session($DeployUser, $DeployPass, $ServerName){
	$credential = Get-PSCredential -User $DeployUser -Password $DeployPass
	return New-PSSession $ServerName -Credential $credential
}

Export-ModuleMember -Function New-Deploy-Session
   