#! /bin/bash
echo "Entering userdata2 script"

runuser -l ec2-user -c "
  # Download orthanc-config from S3
  echo 'Downloading orthanc-config from S3...'
  
  # Create the orthanc-config directory
  mkdir -p ~/orthanc-config
  
  # Download all files from S3 recursively
  aws s3 sync s3://${orthanc_config_bucket}/ ~/orthanc-config/
  if [ \$? -ne 0 ]; then
    echo 'ERROR: Failed to download orthanc-config from S3'
    echo 'Please ensure the orthanc-config files exist in s3://${orthanc_config_bucket}/'
    exit 1
  fi
  
  # Verify the directory has content
  if [ ! \"\$(ls -A ~/orthanc-config)\" ]; then
    echo 'ERROR: orthanc-config directory is empty after download'
    exit 1
  fi
  
  # Change to the orthanc-config directory for further processing
  cd ~/orthanc-config
  echo 'Successfully downloaded orthanc-config from S3'
"

runuser -l ec2-user -c '
  DBSecret=$(aws secretsmanager get-secret-value --secret-id ${sec_name} --query SecretString --output text)
  DBUserName=$(echo $DBSecret | jq -r .username)
  DBPassword=$(echo $DBSecret | jq -r .password)
  ConfigDir="orthanc-config"

  if [ -n "${site_name}" ]; then
    sed -i "/^SITE_NAME/c\SITE_NAME=${site_name}" $ConfigDir/.env
  else
    TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    ServerComName=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname`
    sed -i "/^SITE_NAME/c\SITE_NAME=$ServerComName" $ConfigDir/.env
  fi
  sed -i "/^ORTHANC_DB_HOST/c\ORTHANC_DB_HOST=${db_address}" $ConfigDir/.env
  sed -i "/^ORTHANC_DB_USERNAME/c\ORTHANC_DB_USERNAME=$DBUserName" $ConfigDir/.env
  sed -i "/^ORTHANC_DB_PASSWORD/c\ORTHANC_DB_PASSWORD=$DBPassword" $ConfigDir/.env
  sed -i "/^KC_DB_HOST/c\KC_DB_HOST=${db_address}" $ConfigDir/.env
  sed -i "/^KC_DB_USERNAME/c\KC_DB_USERNAME=$DBUserName" $ConfigDir/.env
  sed -i "/^KC_DB_PASSWORD/c\KC_DB_PASSWORD=$DBPassword" $ConfigDir/.env
  echo \# S3STORAGE >> $ConfigDir/.env
  echo S3_BUCKET=${s3_bucket} >> $ConfigDir/.env
  echo S3_REGION=${aws_region} >> $ConfigDir/.env

  cd $ConfigDir
  ${init_command}
' 

## Configure Docker daemon

if [ "${cw_docker_log}" == "true" ]; then
  cat <<EOF >/etc/docker/daemon.json
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-region": "${aws_region}",
    "awslogs-group": "/${resource_prefix}/orthweb/containers"
  }
}
EOF
fi

systemctl restart docker

# Start the containers as ec2-user after Docker daemon is configured
runuser -l ec2-user -c "
  cd ~/orthanc-config
  echo 'Starting Docker containers...'
  docker compose up -d
  
  # Wait a moment for containers to download and start
  sleep 60
  
  # Check container status
  echo 'Container status:'
  docker compose ps
"

echo "Leaving userdata2 script"
