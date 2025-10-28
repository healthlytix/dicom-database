[The orthanc book](https://orthanc.uclouvain.be/book/index.html) is a very useful reference. Most of this stuff is pulled from there.

# Prerequisites

By default, the terraform scripts in this repo set up orthanc to accept https traffic on port 443 (as usual), and dicom traffic on port 11112. The default AETitle is ORTHANC_DCM. The following instructions assume that your orthanc hostname is $ORTH_HOST and the path to your SSH private key or $ORTH_KEY:

    export ORTH_HOST=<value from terraform outputs>
    export ORTH_IP=<value from terraform outputs>
    export ORTH_KEY=<value from terraform outputs>

In the following, ORTH_HOST should be just the hostname (do not include https).

You first need to fetch the (self-signed) certificates from the instance. (I think this requirement will go away once we have proper SSL certs): `scp -r -i $ORTH_KEY ec2-user@$ORTH_IP:~/orthanc-config/config/certs/ .` In the following you will need the path to the `ca.crt` which you just downloaded. I'll assume that this path is `certs/ca.crt`

# Tests

Basic connectivity `curl --insecure -X GET https://$ORTH_HOST/nginx_health`. Should return `{"status":"UP"}`. I don't think you need any credentials for this. Obviously, the `--insecure` flag is only necessary until we get a proper SSL cert.

Most other operations require a token. To get it:

TOKEN=$(curl -s -X POST \
--insecure \
https://$ORTH_HOST/keycloak/realms/orthanc/protocol/openid-connect/token \
-d "grant_type=password" \
-d "client_id=orthanc" \
-d "username=$USER" \
-d "password=$PASSWORD" \
| jq -r '.access_token')

where `USER`/`PASSWORD` are the credentials you use to log into the site in the browser.


----

This token didn't work right away. I decoded the token like so:

    PAYLOAD=$(echo $TOKEN | cut -d. -f2)
    PADDING=$(( (4 - ${#PAYLOAD} % 4) % 4 ))
    printf "%s" "$PAYLOAD" | tr '_-' '/+' | sed -E "s/.*/&$(printf '=%.0s' $(seq 1 $PADDING))/" | base64 --decode | jq

The `iss` field did not match the `iss` field in `orthanc-config/app/orthanc_auth_service/shares/keycloak.py`. I edited this file on the instance and replaced the `iss` field so it matches my decoded token (ie `iss: 'https://ec2-52-53-217-147.us-west-1.compute.amazonaws.com/keycloak/realms/orthanc'`). Then I restarted the containers `docker compose down`, `docker compose up -d`

------

still didn't work. I went into keycloak for user 'brian', and on the 'role mapping' tab, I added all the roles to my user.

------



`curl -k -H "Authorization: Bearer $TOKEN" https://$ORTH_HOST/orthanc/instances`

`curl -k -H "Authorization: Bearer $TOKEN" -X POST https://$ORTH_HOST/orthanc/instances --data-binary @glioma_study.zip`

----

export USER=brian
export PASSWORD=fart

or

USER=admin
PASSWORD=ithink