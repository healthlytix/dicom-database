# Initial log in

## Initial setup 

initial credentials are on the instance at `orthanc-config/.env`. They're probably "admin"/"changeme" or similar. These creds are used for keycloak - user/password administration - and don't work to log your into the main orthanc site. This is because they are in the "master" realm, as opposed to the "orthanc" realm (apparently this means something in keycloak world)

* To log into keycloak and manage user, you need to go to `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/keycloak`, NOT `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com`.
* In the drop down at top-left, select the "Othanc" realm (should exist).
* Click on "Clients" and select existing "orthanc" client. Under "Root URL", paste `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/orthanc/`. Under "Valid redirect URIs" paste `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/*`. "Web origins" I kept as `*`.

