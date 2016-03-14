## Deploy Applications to your On-Premises Servers ##
This extension add tasks for deploying IIS Applications, Virtual Directories, Databases, and updating app settings and connection strings. Dragging and dropping these tasks into Release Management vNext is much easier than building your own Powershell scripts. All we require is that your build agent is on the same network as the machine you intend to deploy to. This can either be via an Azure virtual network or by hosting your own build agent On-Premises.

![Tasks](tasks.png)

### Tasks Supported by this extension
- Deploying an IIS Application
-- This task depends on using Managed Service Accounts for security.
-- Task will remove existing Application Pool and Site from IIS.
-- Task then creates new App Pool and Website using specified Managed Service Account.

- Deploying a Virtual Directory
-- This task removes the existing Virtual Directory
-- The new Virtual Directory is created under the specified Application.

- Database Deployment
-- Deploy your databases from your database project. 

- Update App Settings
-- Reuse your same build between environments. All you have to do is update the configuration

- Update Connection Strings
-- Reuse your same build between environments. All you have to do is update the configuration

- Require SSL Redirect
-- This task allows you to force an IIS Application to only allow an SSL connection.

### Roadmap
- Coming Soon!

### Quick steps to get started
1. Open the Visual Studio Team Service account where you installed the extension.

### Learn more about this extension
We have lots of documentation available over at github!: [https://github.com/TechnossusLLC/On-Premises-Release-Toolkit](https://github.com/TechnossusLLC/On-Premises-Release-Toolkit).
