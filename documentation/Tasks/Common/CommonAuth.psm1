Function Get-PSCredential($User,$Password)
{
 $SecPass = convertto-securestring -asplaintext -string $Password -force
 $Creds = new-object System.Management.Automation.PSCredential -argumentlist $User,$SecPass
 Return $Creds
}    

Function New-Deploy-Session($DeployUser, $DeployPass, $ServerName){
	Write-Host "Attempting to create session to $ServerName"
    if($DeployUser){  
        Write-Host "Using Credentials"
        $credential = Get-PSCredential -User $DeployUser -Password $DeployPass
        return New-PSSession $ServerName -Credential $credential
    } else {
        return New-PSSession $ServerName     
    }
 
}

Function Resolve-Error($Error)
{
   $ErrorRecord=$Error[0]
    
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

Export-ModuleMember -Function New-Deploy-Session
Export-ModuleMember -Function Resolve-Error
   