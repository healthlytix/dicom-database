.PHONY: TBD
# For consistent command interpreter behaviour across Linux and Mac, set shell to bash. Otherwise, command substitution breaks
SHELL := /bin/bash 
include .env
CERT_COUNTRY=CA
CERT_STATE=Ontario
CERT_LOC=Toronto
CERT_ORG=DigiHunch
CERT_OU=Imaging
CERT_DAYS=1095
AUTH_SERVICE_INTERNAL_SECRET_KEY:=$(shell LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)

dev: dep certs local done 
aws: dep dep_ec2 certs psql ec2 done

dep:
	$(info --- Checking Dependencies for dev deployment ---)
	@if ! command -v docker &> /dev/null; then echo "Docker is not installed. Please install Docker."; exit 1; fi
	@if ! command -v yq &> /dev/null; then echo "yq is not installed. Please install yq."; exit 1; fi
	@echo [makefile][$@] dependency check passed!
	$(eval SANS := DNS:$(SITE_NAME),DNS:issuer.$(SITE_NAME))
	@echo [makefile][$@] SANs is set to $(SANS)
dep_ec2:
	$(info --- Checking Dependencies for non-dev deployment ---)
	@if ! command -v jq &> /dev/null; then echo "jq is not installed. Please install jq."; exit 1; fi
	@if ! command -v psql &> /dev/null; then echo "postgresql is not installed. Please install postgresql."; exit 1; fi
	@echo [makefile][$@] dependency check on ec2 passed!
	$(eval TOKEN := $(shell curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"))
	$(eval ServerPublicHostName := $(shell curl -s -H "X-aws-ec2-metadata-token: $(TOKEN)" http://169.254.169.254/latest/meta-data/public-hostname))
	$(eval SANS := $(SANS),DNS:$(ServerPublicHostName))
	@echo [makefile][$@] SANs is updated to $(SANS) 
certs:
	$(info --- Creating Self-signed Certificates ---)
	@echo [makefile][$@] starting to create self-signed certificate for $(SITE_NAME) in config/certs
	@openssl req -x509 -sha256 -newkey rsa:4096 -days $(CERT_DAYS) -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=issuer.$(SITE_NAME)/emailAddress=info@$(SITE_NAME) -keyout config/certs/ca.key -out config/certs/ca.crt 2>/dev/null
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=$(SITE_NAME)/emailAddress=issuer@$(SITE_NAME) -addext extendedKeyUsage=serverAuth -addext subjectAltName=$(SANS) -keyout config/certs/server.key -out config/certs/server.csr 2>/dev/null
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/server.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/server.crt -extfile <(echo subjectAltName=$(SANS))
	@cat config/certs/server.key config/certs/server.crt config/certs/ca.crt > config/certs/$(SITE_NAME).pem
	@openssl req -new -newkey rsa:4096 -nodes -subj /C=$(CERT_COUNTRY)/ST=$(CERT_STATE)/L=$(CERT_LOC)/O=$(CERT_ORG)/OU=$(CERT_OU)/CN=client.$(SITE_NAME)/emailAddress=client@$(SITE_NAME) -keyout config/certs/client.key -out config/certs/client.csr 2>/dev/null
	@openssl x509 -req -sha256 -days $(CERT_DAYS) -in config/certs/client.csr -CA config/certs/ca.crt -CAkey config/certs/ca.key -set_serial 01 -out config/certs/client.crt
	@echo [makefile][$@] finished creating self-signed certificate
local:
	$(info --- Configuring Orthanc for local dev ---)
	@cp config/orthanc/orthanc.json.local config/orthanc/orthanc.json
	@yq e '.services.orthanc-auth-service.environment.SECRET_KEY = "$(AUTH_SERVICE_INTERNAL_SECRET_KEY)"' docker-compose.yaml.local > docker-compose.yaml
psql:
	$(info --- Provisioning PostgreSQL database for Keycloak on RDS ---)
	@sed s/keycloak_db/$(KC_DB_NAME)/g config/keycloak_db/keycloak-provision.sql.tmpl > config/keycloak_db/keycloak-provision.sql
	@export PGPASSWORD=$(KC_DB_PASSWORD); psql "host=$(KC_DB_HOST) port=5432 user=$(KC_DB_USERNAME) dbname=postgres sslmode=require" -f config/keycloak_db/keycloak-provision.sql
	@echo [makefile][$@] initialized postgresdb for keycloak
ec2:
	$(info --- Configuring Orthanc on EC2 with S3 and RDS storage ---) 
	@jq '.AwsS3Storage = {ConnectionTimeout: 30, RequestTimeout: 1200, RootPath: "image_archive", StorageStructure: "legacy", BucketName: "$(S3_BUCKET)", Region: "$(S3_REGION)"} | del(.StorageDirectory) | .PostgreSQL.EnableSsl = true | .Plugins += ["/usr/share/orthanc/plugins-available/libOrthancAwsS3Storage.so"] ' config/orthanc/orthanc.json.local > config/orthanc/orthanc.json
	@yq e '.services.orthanc-auth-service.environment.SECRET_KEY = "$(AUTH_SERVICE_INTERNAL_SECRET_KEY)" | del(.services.keycloak-db, .services.orthanc-db) | .services.orthanc-service.depends_on |= map(select(. != "orthanc-db")) | .services.keycloak-service.depends_on |= map(select(. != "keycloak-db")) | .services.keycloak-service.environment.KC_DB_URL += "?ssl=true&sslmode=require" ' docker-compose.yaml.local > docker-compose.yaml
	@echo [makefile][$@] updated configuration on ec2 
done:
	$(info --- Configuration completed ---)
	@echo [makefile][$@] Bootstrapping process:
	@echo [makefile][$@]   1. Run docker compose up and grab the value for KEYCLOAK_CLIENT_SECRET from stdout
	@echo [makefile][$@]   2. Edit compose file, update value for KEYCLOAK_CLIENT_SECRET, and set ENABLE_KEYCLOAK_API_KEYS to true
	@echo [makefile][$@]   3. Restart the application: docker compose down then docker compose up
