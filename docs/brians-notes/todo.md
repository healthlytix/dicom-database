
* static IP and/or subdomain
* a proper tls cert
* move to us-west-2. this will require putting it in an existing vpn and probably tweaking the cidr ranges
* fix terraform warnings

questions for syed:

* delete .env files from instances?
* using an SSH key from AWS secrets manager instead of a local one?
* is this stuff Soc2 compliant?