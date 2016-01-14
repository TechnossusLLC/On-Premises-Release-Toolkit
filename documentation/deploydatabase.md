# Deploy Database

This plugin allows you to deploy a database using a dacpac. 

![Plugin Config](databasedeployconfig.png)

## Inputs
------------------

There are 3 inputs required for this plugin.

## Server Name

The name of the Sql Server

## Database Name

The name of the destination database

## Dacpac Location

The location of the dacpac from your build drop.


In order for the dacpac to deploy, the TFS Service account will also need 'sysadmin' access to the db server.

