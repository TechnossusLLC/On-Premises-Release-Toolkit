# Require SSL Redirect

This task allows you to force an IIS Application to only allow an SSL connection. It adds rewrite rules to the web.config so that any requires to http will be redirected to https. It will also try to install Url rewrite.

## Inputs
------------------

There are 5 possible inputs for this Task

### Name - Required

The name of the IIS Application.

### Server Name - Required

Name of the server to deploy the application to

### Deploy User 

If the service account of the Build Agent does not have access to the destination server, you can override the user account which the work is done under.

### Deploy Password 

If the service account of the Build Agent does not have access to the destination server, you can override the user account which the work is done under.

## Install Web Platform Installer

If checked, the task will attempt to install the Web Platform installer which will allow Url Rewrite to be installed if it is not currently.
