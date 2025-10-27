variable "public_key" {
  type      = string
  sensitive = true
}
variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    vpc_id                    = string
    public_subnet_cidr_blocks = list(string)
    public_subnet_ids         = map(string)
    web_cli_cidrs             = list(string)
    dcm_cli_cidrs             = list(string)
  })
}
variable "s3_bucket_name" {
  type = string
}
variable "orthanc_config_bucket" {
  type = string
  description = "S3 bucket name for orthanc-config files"
}
variable "role_name" {
  type = string
}
variable "db_info" {
  type = object({
    db_address             = string
    db_port                = string
    db_instance_identifier = string
    db_instance_arn        = string
  })

}
variable "secret_info" {
  type = object({
    db_secret_arn  = string
    db_secret_name = string
  })
}
variable "custom_key_arn" {
  type = string
}
variable "deployment_options" {
  type = map(any)
}
variable "ec2_config" {
  type = object({
    InstanceType = string
  })
}
variable "resource_prefix" {
  type        = string
  description = "Uniq prefix of each resource"
}
variable "admin_ips" {
  type        = list(string)
  description = "List of IP addresses or CIDR blocks allowed to SSH to the EC2 instances"
}
variable "orthanc_config_files_uploaded" {
  type        = any
  description = "S3 objects for orthanc-config files - used to ensure files are uploaded before EC2 creation"
}
