# On Premises Release Toolkit

This is the documentation for the On-Premises release toolkit. The goal of this toolkit is to ensure that releasing software to On-Premise machines can be simple. This toolkit has a couple of requirements. 

Add it to your VSTS instance [here](https://marketplace.visualstudio.com/items?itemName=technossusllc.on-premises-build-tasks)

1. Make sure you have RSAT(Remote Server Administraion Tools) installed on any machine you want to deploy to
   
   ```
   Add-WindowsFeature RSAT-AD-PowerShell
   ```
   
2. Your build agent must be on the same network as the machines you wish to deploy to.

Other than that, the whole process is pretty seamless

## Included Tools

1. [Deploy IIS Application](deployiis.md)
2. [Deploy IIS Virtual Directory](deployvirtualdirectory.md)
3. [Deploy Database](deploydatabase.md)
4. [Update App Settings](updateappsettings.md)
5. [Update Connection String](updateconnectionstring.md)
6. [Require SSL Redirect](requiresslredirect.md)
