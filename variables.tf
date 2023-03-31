
variable "aws_region" {
  description = "Default region for provider"
  type = string
  default = "us-east-1"
}

#TODO: Add AWS account access Key here..
variable "accessKey" {
  default = ""
}

#TODO: Add AWS account secret Key here..
variable "secretKey" {
  default = ""
}

# A map of the tags to apply to various resources. The required tags are:
# 'application', name of the app;
# 'environment', the environment being created;
# 'team', team responsible for the application;
# 'customer', who the application was create for.
variable "tags" {
  type = map 
  default = {
    Application = "demo-cdc-stream"
    Environment = "dev"
    Team = "accolite/xerris"
    Customer = "brp"
  }
}

# The demo name
variable "app" {
  default = "cdc-stream-demo"
}

# The environment that is being built
variable "environment" {
  default = "test"
}

variable "lb_port" {
  default = "80"
}

variable "lb_protocol" {
  default = "HTTP"
}

variable "subnet_cidrs_public" {
  type = list
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "publicIPOnLaunch" {
  type = bool
  default = true
}

variable "availability_zones" {
  description = "AZs in this region to use"
  type = list
  default = ["us-east-1a", "us-east-1c"]
}

//RDS stuff

#Create a DB Password
variable "password" {
  default = ""
}

variable "username" {
  default = "admin"
}

variable "create_instance" {
  description = "Controls if RDS instance should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "allocated_storage" {
  default = 20
}

variable "max_allocated_storage" {
  default = 100
}

variable "engine" {
 default = "sqlserver-se"
 #default = "sqlserver-ex"
}

variable "engine_version" {
  default = "14.00.3451.2.v1"
}

variable "major_engine_version" {
  default = "14.00"
}

variable "family" {
  default = "sqlserver-se-14.0"
  #default = "sqlserver-ex-14.0"
}

variable "instance_class" {
  #default = "db.t2.micro"
  default = "db.m4.large"
}

variable "publicly_accessible" {
  default = true
}

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.SQLServer.CommonDBATasks.Collation.html
variable "character_set_name" {
  description = "SQL Server collation to use"
  type = string
  default = "SQL_Latin1_General_CP1_CI_AS"
}

variable "parameter_group_name" {
  default = "default.sqlserver-se-14.0"
  #default = "default.sqlserver-ex-14.0"
}

variable "option_group_name" {
  #default = "sqlserver-ex-14-00"
  default = "sqlserver-se-14-00"
}

variable "multi_az" {
  default = false
}

variable "storage_encrypted" {
  default = false
}

variable "timezone" {
  default = "UTC"
}

variable "port" {
  description = "The port on which to accept connections"
  type = string
  default = "1433"
}

variable "backup_retention_period" {
  description = "How long to keep backups for (in days)"
  type = number
  default = 0
}

variable "backup_window" {
  description = "When to perform DB backups"
  type        = string
  default     = "02:00-03:00"
}

variable "maintenance_window" {
  description = "When to perform DB maintenance"
  type = string
  default = "sun:05:00-sun:06:00"
}

variable "allow_major_version_upgrade" {
  default = false
}

variable "apply_immediately" {
  default = true
}

variable "auto_minor_version_upgrade" {
  default = true
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Should a final snapshot be created on cluster destroy"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier_prefix" {
  description = "The prefix name to use when creating a final snapshot on cluster destroy, appends a random 8 digits to name to ensure it's unique too."
  type        = string
  default     = "final"
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled or not."
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data."
  type        = string
  default     = ""
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether IAM Database authentication should be enabled or not. Not all versions and instances are supported. Refer to the AWS documentation to see which versions are supported."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "The interval (seconds) between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 0
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Cluster tags to snapshots."
  type        = bool
  default     = false
}

variable "license_model" {
  description = "One of license-included, bring-your-own-license, general-public-license"
  default = "license-included"
}

// Kinesis stuff

variable "shard_count" {
  type        = number
  description = "(Required) The number of shards that the stream will use. Amazon has guidelines for specifying the Stream size that should be referenced when creating a Kinesis stream."
  default     = 1
}

variable "retention_period" {
  type        = number
  description = "(Optional) Length of time data records are accessible after they are added to the stream. The maximum value of a stream's retention period is 168 hours. Minimum value is 24. Default is 24."
  default     = 24
}

variable "shard_level_metrics" {
  type        = list(string)
  description = "(Optional) A list of shard-level CloudWatch metrics which can be enabled for the stream. See Monitoring with CloudWatch for more. Note that the value ALL should not be used; instead you should provide an explicit list of metrics you wish to enable."
  default = [

  ]
}

variable "enforce_consumer_deletion" {
  type        = bool
  description = "(Optional) A boolean that indicates all registered consumers should be deregistered from the stream so that the stream can be destroyed without error. The default value is false."
  default     = false
}

variable "encryption_type" {
  type        = string
  description = " (Optional) The encryption type to use. The only acceptable values are NONE or KMS. The default value is NONE."
  default     = "KMS"
}

//DMS instance
# Instance
variable "repl_instance_allocated_storage" {
  description = "The amount of storage (in gigabytes) to be initially allocated for the replication instance. Min: 5, Max: 6144, Default: 50"
  type        = number
  default     = 5
}

variable "repl_instance_auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the replication instance during the maintenance window"
  type        = bool
  default     = true
}

variable "repl_instance_allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type        = bool
  default     = false
}

variable "repl_instance_apply_immediately" {
  description = "Indicates whether the changes should be applied immediately or during the next maintenance window"
  type        = bool
  default     = true
}

variable "repl_instance_availability_zone" {
  description = "The EC2 Availability Zone that the replication instance will be created in"
  type        = string
  default     = "us-east-1a"
}

variable "repl_instance_engine_version" {
  description = "The [engine version](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_ReleaseNotes.html) number of the replication instance"
  type        = string
  default     = "3.4.7"
}

variable "repl_instance_kms_key_arn" {
  description = "The Amazon Resource Name (ARN) for the KMS key that will be used to encrypt the connection parameters"
  type        = string
  default     = null
}

variable "repl_instance_multi_az" {
  description = "Specifies if the replication instance is a multi-az deployment. You cannot set the `availability_zone` parameter if the `multi_az` parameter is set to `true`"
  type        = bool
  default     = false
}

variable "repl_instance_preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC)"
  type = string
  default = "sun:05:00-sun:06:00"
}

variable "repl_instance_publicly_accessible" {
  description = "Specifies the accessibility options for the replication instance"
  type        = bool
  default     = true
}

variable "repl_instance_class" {
  description = "The compute and memory capacity of the replication instance as specified by the replication instance class"
  type        = string
  default     = "dms.t2.micro"
}

variable "repl_instance_id" {
  description = "The replication instance identifier. This parameter is stored as a lowercase string"
  type        = string
  default     = "test-dms-replication-instance-tf"
}

variable "source_db" {
  description = "Source DB Name"
  type = string
  default = "cdc_demo"
}

variable "target_db" {
  description = "Target DB Name"
  type = string
  default = "cdc-stream"
}