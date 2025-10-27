output "host_info" {
  value = {
    instances = [
      for i in range(length(module.ec2.hosts_info.instance_ids)) : {
        instance_id = module.ec2.hosts_info.instance_ids[i]
        public_ip   = module.ec2.hosts_info.public_ips[i]
        public_dns  = module.ec2.hosts_info.public_dns[i]
      }
    ]
    count = length(module.ec2.hosts_info.instance_ids)
  }
  description = "Instance IDs, Public IPs, and DNS names of EC2 instances"
}

output "server_dns" {
  value = {
    dns_names = module.ec2.hosts_info.public_dns
    count     = length(module.ec2.hosts_info.public_dns)
    services  = "HTTPS (port 443) and DICOM TLS (port 11112)"
  }
  description = "DNS names of EC2 instances with service information"
}

output "database_connection" {
  value = {
    endpoint = module.database.db_info.db_address
    port     = module.database.db_info.db_port
    database = "postgres"  # Default database name
    username = "postgres"  # Default username
    password_secret_arn = module.database.secret_info.db_secret_arn
    password_secret_name = module.database.secret_info.db_secret_name
    connection_string = "postgresql://postgres:<password>@${module.database.db_info.db_address}:${module.database.db_info.db_port}/postgres"
    password_retrieval_command = "aws secretsmanager get-secret-value --secret-id ${module.database.secret_info.db_secret_name} --query SecretString --output text | jq -r .password"
  }
  description = "Complete database connection information"
}

output "s3_bucket" {
  value       = module.storage.s3_info.bucket_domain_name
  description = "S3 bucket name for data storage"
}
output "orthanc_config_bucket" {
  value       = module.storage.s3_info.orthanc_config_bucket
  description = "S3 bucket name for orthanc configuration files"
}

output "ssh_commands" {
  value = {
    commands = [
      for i in range(length(module.ec2.hosts_info.instance_ids)) : 
      "ssh -i ${var.ec2_config.PublicKeyPath} ec2-user@${module.ec2.hosts_info.public_ips[i]}"
    ]
    count = length(module.ec2.hosts_info.instance_ids)
    key_path = var.ec2_config.PublicKeyPath
  }
  description = "SSH commands to connect to EC2 instances"
}
