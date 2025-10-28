# User Management

This document describes how admins can manage users of the DICOM database via the keycload console.

The following instructions assume you've already completed all of the steps in `deploy`, including setting a strong admin password for keycloak. The server hostname and the link to the keycloak console are both available as terraform output; view them with `cd terraform`, `terraform output`. 

## Create regular user

* Log into the keycloak console with your `admin` password.
* From the dropdown at the top-left, change the realm from "master" to "orthanc"
* Select "Users" from the menu and add a new user
* Add "Update password" as a required user action so that they'll need to update/save their password (so you don't have access to it)
* Create the user, then select their "Credentials" tab and create a temporary password for them. Since you do not control when the new user will update it, use a strong password, even if it's temporary! 
* Share the temp password and the link with the new user
