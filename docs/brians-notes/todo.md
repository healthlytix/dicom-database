
* save terraform state to S3. or wherever syed wants it
* static IP and/or subdomain
* a proper tls cert
* move to us-west-2. this will require putting it in an existing vpn and probably tweaking the cidr ranges
* fix terraform warnings
* KC_DB_USERNAME is set to `myuser`. This should be `dbadmin` or similar
* update AETitle in `orthanc-config/config/orthanc/orthanc.json.local`

user stuff:
* delete default users - `doctor`, `external`
* how to assign different roles to different users? not everyone should be able to delete/update or even download
* after updating `admin` keycloak password, I still see the `You are logged in as a temporary admin user. To harden security, create a permanent admin account and delete the temporary one.` warning banner. I guess they want you to create a new user and delete this one?
* see if email verification works okay. if so, update user management docs appropriately

questions for syed:

* delete .env files from instances?
* using an SSH key from AWS secrets manager instead of a local one?
* is this stuff Soc2 compliant?