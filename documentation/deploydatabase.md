# Deploy Database

This plugin allows you to deploy a database using a dacpac. In order for the dacpac to deploy, the TFS Service account will also need 'sysadmin' access to the db server.

You will need to have SSDT installed on your build agent. You can get the correct version [here](https://www.microsoft.com/en-us/download/details.aspx?id=43370)

![Plugin Config](databasedeployconfig.png)

## Inputs
------------------

There are 10 inputs required for this plugin.

## Server Name

The name of the Sql Server

## Database Name

The name of the destination database

## Dacpac Location

The location of the dacpac from your build drop.

## SqlCmd Variables

Any SqlCmd variables that may be needed for deploy entered as comma sepatated key/value pairs ex. 'foo1':'bar1','foo2':'bar2'

## Allow Incompatible Platform

Specifies whether deployment will block due to platform compatibility.

## Backup Database Before Changes

Specifies whether a database backup will be performed before proceeding with the actual deployment actions.

## Block On Possible Data Loss

Specifies whether deployment should stop if the operation could cause data loss.

## Create New Database

Sspecifies whether the existing database will be dropped and a new database created before proceeding with the actual deployment actions. Acquires single-user mode before dropping the existing database.

## Deploy Database In Single User Mode

Specifies whether the system will acquire single-user mode on the target database during the duration of the deployment operation.

## Generate Smart Defaults

Specifies whether default values should be generated to populate NULL columns that are constrained to NOT NULL values.



