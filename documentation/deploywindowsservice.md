# Deploy Windows Service

This task allows you to deploy a windows service to a machine. This task will delete the service(if it exists) and deploy a new one setting credentials and the startup type optionally.

## Inputs
------------------

There are 5 possible inputs for this Task

### Service Name - Required

The name of the Service.

### Service Path - Required

The folder path of the service on the machine you are installing it on.

### Server Name - Required

Name of the server to deploy the application to

### Install If Not Exists - Required

This will install the service if it does not exist. If you set this to false, you will only be able to set the description, disaply name, and startup type. Due to limitations with the windows powershell API's, you cannot change the credentials the service runs as.

### Deploy User 

The user which the account will deploy as.

### Deploy Password 

The password for the user which the account will deploy as.

### Display Name

The name that will be used when you browse the services explorer

### Description

A description of what your service does

### Service Account User

The username for which the service will run as.

### Service Account Password

The password for the service account the service will run as. Is this is empty but username is populated, the task will attempt to populate it as a gMSA.

### Depends on

The name of the service that this service may rely on.

### Startup type

The startup Type of the service. This could be Automatic, None, System, or Manual.