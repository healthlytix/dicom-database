# Brian's Notes to self

Documenting my troubles + fixes with deploying the existing orthweb setup completely off-the-shelf.

## Issues

I could not SSH onto the instances bc the security group has no ingress rules. I added/commited some terraform updates to pass a list of admin IP address; these are added to the ingress whitelist on port 22 (SSH)

----

The containers failed to start on the instances. I believe the issue is with this file `https://github.com/digihunchinc/orthanc-config/blob/main/config/orthanc/orthanc.json.local` (the orthanc-config repo is cloned and `make`d at instance startup). The problem is that that file is not valid JSON -- it includes "comments", which are not allowed in JSON. I manually deleted the offending lines, and re-ran `make ec2` and then started the containers with `docker compose up -d`. The updated `orthanc.json.local` file is saved here.

----

The site was still not loading correctly. Instead of https://54.193.51.35, I had to navigate to the path
https://54.193.51.35/orthanc/ui/app/#/. I then get an "insecure site" warning, which I clicked through.

----

Now the page is loading, but it is empty, and the browser JS console shows "Could not connect to Keycloak". I think the keycloak container is not exposing the correct port to the other docker containers. 

I edited the docker-compose.yaml file and under the `keycloak-service` container, I added the following:

    ports:
      - "8080:8080"

Then restart the containers:

    docker compose down
    docker compose up -d

The "Could not connect to Keycloak" JS message is now gone, but I'm still getting a blank page!

----

After 3.5 hours of fucking with this shit and going around in circles with cursor.ai, I finally realized that the solution is to use the hostname (https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/) instead of the IP address in the browser! 
Among other lessons learned is this important one: cursor.ai is almost always worse than chatgpt!

----

I got the login credentials with `grep -R KC_ADMIN .`, they are `KC_ADMIN_USR=admin` and `KC_ADMIN_PSW=changeme`. These did not work in the browser, somehow these are only "bootstrap" credentials which didn't work when I tried them. To reset, I followed the chatgpt insturctions here (https://chatgpt.com/c/68fd4ab7-15c4-8323-8fd0-5682390dcdfe, search for "Connect to RDS (PostgreSQL)"):

* get KC_DB_USERNAME, KC_DB_PASSWORD from .env file and export them
* connect to keycloak rds database: `psql "host=liberal-pipefish-orthancpostgres.cqcpq9xdxooo.us-west-1.rds.amazonaws.com port=5432 dbname=keycloakdb user=$KC_DB_USERNAME password=$KC_DB_PASSWORD sslmode=require"`
* delete stuff: `DROP SCHEMA public CASCADE;`, `CREATE SCHEMA public;`
* exit db and `docker compose restart keycloak-service`. then `docker logs keycloak-backend | grep -i admin` should show "Created temporary admin user with username admin"

I had to go straight to `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/keycloak` in order to log in. navigating to `https://ec2-54-193-51-35.us-west-1.compute.amazonaws.com/` and logging into the page I was redirected to did not work with teh bootstrap credentials!
