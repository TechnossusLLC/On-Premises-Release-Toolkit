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
7. [Deploy Windows Service](deploywindowsservice.md)


## Release History
- 0.8.6 - Add assembly versioning to the toollkit.
- 0.8.0 - Allow a configuration fille to be specified during database deployment time instead of using the predefined options.
- 0.7.2 - Add the ability to set a description during the Enable Windows Service Task.
- 0.7.0 - Add additional functionality to the Enable Windows Service Task. Allow default account to be used when deploying IIS App Pools.
- 0.6.4  - Fix the Enable Service Account task so that it properly uses service accounts.
- 0.6.0 - Add the ability to run Sql Commands during a release
- 0.5.0 - Add the ability to enable/disable windows services as part of a build/release