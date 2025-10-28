# Deploy DICOM server

This document describes how to deploy a new DICOM server instance into AWS, and how to do basic user administration.

These instructions were tested on MacOS 26.01 (Tahoe) with terraform 1.10.2.

## from scratch

Prerequisites:

* `terraform`
* an SSH key

Deploy:

From the `terraform` directory

* `terraform init` to install modules
* `terraform apply` to create cloud infrastructure. It can take 15-30 minutes to create everything; the database creation in particular is slow. A lot of resources will be created (~90), but half of them are just S3 file objects (the `orthan-config` contents are uploaded to an S3 bucket as part of deployment). 
* the terraform outputs are printed after a successful deployment. you can view them later with the command `terraform output`. The outputs include a lot of useful information:
    * the instance IDs, hostnames, IP addresses, and SSH commands to connect to then
    * the database hostname and credentials
    * the bucket name(s)

### User administration

#### Update keycloak admin password

* The terraform output include `keycloak_urls` names for your instances. Copy one into the browser and add the path `/keycloak` to the end to connect to the keycloak access/user management console. Note that **you must log into `/keycloak` (not the base URL) to manage users**.
    * If you cannot "connection refused" or similar connection error, then the containers probably did not start. You'll need to SSH onto one of the instances using the `terraform output` to debug the userdata scripts and/or the docker containers. If you cannot SSH onto the instance, then it is likely that you need to add your IP address to the `admin_ips` whitelist in `terraform.tfvars`.
* Log into keycloak using the temp admin credentials `KC_ADMIN_USR`/`KC_ADMIN_PSW` specified in `orthanc-config/.env`. They will probably be "admin" and "changeme" or similar weak credentials.
* By default you will be in the "Master" realm, as indicated in the drop-down. Click on the `Users` menu option, then `admin`, and update to a strong password which is saved in your password manager. 
* Sign out and back in again with your new password

> [!WARNING]
> You absolutely MUST change the admin credentials! They are very weak!
> Do not move on until the keycloak `admin` has a strong password saved in 1password.

If something goes wrong with your admin password, you can SSH onto the instance, open a shell in the keycloak container and run the appropriate keycloak commands.

#### Create regular user

* Log into the keycloak console with your new strong `admin` password.
* From the dropdown at the top-left, change the realm from "master" to "orthanc"
* Select "Users" from the menu and add a new user
* Add "Update password" as a required user action so that they'll need to update/save their password (so you don't have access to it)
* Create the user, then select their "Credentials" tab and create a temporary password for them. Since you do not control when the new user will update it, use a strong password, even if it's temporary! 
* Share the temp password and the link with the new user

