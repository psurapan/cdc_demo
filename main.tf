# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  access_key = var.accessKey
  secret_key = var.secretKey
}


resource "aws_db_subnet_group" "rds_subnet" {
  name        = var.app
  description = "Subnet group for ${var.app}"
  subnet_ids  = [for subnet in aws_subnet.public_subnet : subnet.id]

  tags = var.tags
}

##### Create VPC ######

resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}


# create IG

resource "aws_internet_gateway" "demo_ig" {
  vpc_id = aws_vpc.rds_vpc.id
  tags = var.tags
}

# 3. Create RT

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.rds_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demo_ig.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.demo_ig.id
    }

    tags = var.tags
}

##### Create Subnets ######
resource "aws_subnet" "public_subnet" {
  count = "${length(var.subnet_cidrs_public)}"

  vpc_id = aws_vpc.rds_vpc.id
  cidr_block = "${var.subnet_cidrs_public[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"
  #map_public_ip_on_launch = var.publicIPOnLaunch

  tags = merge (
    "${var.tags}",
    {
      Name = "public"
    },
  )
}

# Associate Subnets with RT 
resource "aws_route_table_association" "public_rt_association" {
  count = "${length(var.subnet_cidrs_public)}"

  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}

###### CREATE RDS MS SQL SERVER -- 13 min #####
## TODO: CREATE DB SCRIPTS TO create DB and turn on CDC
resource "aws_db_instance" "rds_instance" {
  identifier = var.app
  count = var.create_instance ? 1 : 0
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  # TODO Add support for io1 and iops
  storage_type = "gp2"
  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  publicly_accessible = var.publicly_accessible
 # character_set_name = var.character_set_name
  username = var.username
  password = var.password
  parameter_group_name = var.parameter_group_name
  #option_group_name = var.option_group_name
  multi_az = var.multi_az
  # TODO Later on add support for kms keys
  storage_encrypted = var.storage_encrypted
  timezone = var.timezone
  port = var.port
  backup_retention_period = var.backup_retention_period
  backup_window = var.backup_window
  maintenance_window = var.maintenance_window
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier_prefix
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  performance_insights_enabled = var.performance_insights_enabled
 # performance_insights_kms_key_id = var.performance_insights_kms_key_id
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  # TODO Add AD support: domain, domain_iam_role_name
 # monitoring_role_arn = ""
 # monitoring_interval = var.monitoring_interval
  tags = var.tags
  copy_tags_to_snapshot = var.copy_tags_to_snapshot
  license_model = var.license_model
  db_subnet_group_name = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.nsg_rds_in.id]

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
 
}

# data "aws_iam_policy_document" "monitoring_rds_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["monitoring.rds.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "rds_enhanced_monitoring" {
#   count = var.create_instance && var.create_monitoring_role && var. f > 0 ? 1 : 0
#   name               = "rds-enhanced-monitoring-${var.name}"
#   assume_role_policy = data.aws_iam_policy_document.monitoring_rds_assume_role.json
#   permissions_boundary = var.permissions_boundary
#   tags = merge(var.tags, {
#     Name = "sqlserver-${var.name}"
#   })
# }

# resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
#   count = var.create_instance && var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0
#   role       = local.rds_enhanced_monitoring_name
#   policy_arn = "arn:${var.iam_partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
# }


# Ingress rules to allow RDS connections. TODO: Replace the cidr-block to subnet instead of personal
resource "aws_security_group_rule" "nsg_rds_ingress_rule" {
  type              = "ingress"
  description       = "Ingress rule for RDS Security Group"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  #cidr_blocks       = ["70.121.101.40/32"]
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nsg_rds_in.id
}

# security group for RDS-Ingress
resource "aws_security_group" "nsg_rds_in" {
  name        = "${var.app}-${var.environment}-rds"
  description = "Allow connections from external resources while limiting connections from ${var.app}-${var.environment}-rds to internal resources"
  vpc_id      = aws_vpc.rds_vpc.id

  tags = "${var.tags}"
}

#Egress Rules for RDSsg_rds
resource "aws_security_group_rule" "nsg_rds_egress_rule" {
 # security_group_id = aws_security_group.nsg_rds_out.id
  description = ""
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "all"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nsg_rds_in.id
}

# SecurityGroup for RDS-Egress
# security group for RDS 
# resource "aws_security_group" "nsg_rds_out" {
#   name        = "${var.app}-${var.environment}-rds-out"
#   description = "Allow connections from external resources while limiting connections from ${var.app}-${var.environment}-rds to internal resources"
#   vpc_id      = aws_vpc.rds_vpc.id

#   tags = "${var.tags}"
# }


###### CREATE DMS ######

resource "aws_iam_role" "dms_vpc_role" {
  name        = "dms-vpc-role"
  description = "Allows DMS to manage VPC"
  assume_role_policy = <<EOF
  {
    "Version" : "2012-10-17",
      "Statement" : [
        {
        "Action" : "sts:AssumeRole",
        "Principal" : {
            "Service" : "dms.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role_policy_attachement" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

// Create a new replication subnet group

resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  replication_subnet_group_description = "cdc demo replication subnet group"
  replication_subnet_group_id          = var.app

  subnet_ids = [for subnet in aws_subnet.public_subnet : subnet.id]

  tags = {
    Name = "dms-cdc-subnet-group"
  }

  # explicit depends_on is needed since this resource doesn't reference the role or policy attachment
  depends_on = [aws_iam_role_policy_attachment.dms_vpc_role_policy_attachement]
}

// Instance -- takes about 11 min

resource "aws_dms_replication_instance" "dms_instance" {
  allocated_storage            = var.repl_instance_allocated_storage
  auto_minor_version_upgrade   = var.repl_instance_auto_minor_version_upgrade
  allow_major_version_upgrade  = var.repl_instance_allow_major_version_upgrade
  apply_immediately            = var.repl_instance_apply_immediately
  availability_zone            = var.repl_instance_availability_zone
  engine_version               = var.repl_instance_engine_version
#  kms_key_arn                  = var.repl_instance_kms_key_arn
  multi_az                     = var.repl_instance_multi_az
  preferred_maintenance_window = var.repl_instance_preferred_maintenance_window
  publicly_accessible          = var.repl_instance_publicly_accessible
  replication_instance_class   = var.repl_instance_class
  replication_instance_id      = var.repl_instance_id
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms_subnet_group.replication_subnet_group_id
  vpc_security_group_ids       = [aws_security_group.nsg_rds_in.id]

  tags = merge(
    {
      Name = format("%s-dms-instance", var.app)
    },
    var.tags
  )

  depends_on = [aws_db_instance.rds_instance]
}

// EndPoints - source and target
resource "aws_dms_endpoint" "dms_endpoint_source" {
  database_name = var.source_db
  endpoint_id = aws_db_instance.rds_instance[0].identifier
  endpoint_type = "source"
  engine_name = "sqlserver"
  username = var.username
  password = var.password
  port = 1433
  server_name = "${aws_db_instance.rds_instance[0].identifier}.cxsg5ghvy818.us-east-1.rds.amazonaws.com"
}


#Add a rule to allow DMS replication instance to access 1433 within EC2/RDS SG
resource "aws_security_group_rule" "add_dms_replication_ip_to_sg" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [join("", [element(aws_dms_replication_instance.dms_instance.replication_instance_public_ips, 0), "/32"])]
  security_group_id = aws_security_group.nsg_rds_in.id
}

output "RDS_Endpoint" {
  value = aws_dms_endpoint.dms_endpoint_source.server_name
}

resource "aws_dms_endpoint" "dms_endpoint_target" {
  database_name = var.target_db
  endpoint_id = aws_kinesis_stream.demo_kds.name
  endpoint_type = "target"
  engine_name = "kinesis"
  kinesis_settings {
    stream_arn = aws_kinesis_stream.demo_kds.arn
    service_access_role_arn = aws_iam_role.dms_role.arn
  }
}

//Migration Tasks
resource "aws_dms_replication_task" "rds_to_kinesis" {
  replication_task_id       = "rds-to-kinesis"
  migration_type            = "cdc"
  replication_instance_arn  = aws_dms_replication_instance.dms_instance.replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.dms_endpoint_source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.dms_endpoint_target.endpoint_arn
 # replication_task_settings = file("replication_task_settings.json")
 #TODO: enable cloud watch logs, overriding default log level
  table_mappings            = file("table_mappings.json")

   tags = merge(
    {
      Name = format("%s-replication-task", var.app)
    },
    var.tags
  )
}


###### CREATE KDS ######
resource "aws_kinesis_stream" "demo_kds" {
  name             = "${var.app}-stream"
  shard_count      = var.shard_count
  retention_period = var.retention_period

  shard_level_metrics       = var.shard_level_metrics
  enforce_consumer_deletion = var.enforce_consumer_deletion
 # encryption_type           = var.encryption_type #tfsec:ignore:AWS024

 # kms_key_id = var.kms_key_id
  tags = merge(
    {
      Name = format("%s-stream", var.app)
    },
    var.tags
  )
}

resource "aws_iam_role" "dms_role" {
  name="dms-role-to-write-kds-stream"
  assume_role_policy = <<EOF
  {
    "Version" : "2012-10-17",
      "Statement" : [
        {
        "Action" : "sts:AssumeRole",
        "Principal" : {
            "Service" : "dms.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
        }
      ]
    }
  EOF
}

resource "aws_iam_policy" "iam_policy_to_write_kinesis" {
 
 name         = "aws-iam-policy-for-dms-write-kinesis"
 path         = "/"
 description  = "AWS IAM Policy for write to Kinesis Streams"
 policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "kinesis:*"
     ],
     "Resource": "arn:aws:kinesis:*:*:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

# Attach IAM Policy to IAM Role

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_dms" {
 role        = aws_iam_role.dms_role.name
 policy_arn  = aws_iam_policy.iam_policy_to_write_kinesis.arn
}

# # Kinesis Firehose 
# resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
#   name        = "terraform-kinesis-firehose-extended-s3-test-stream"
#   destination = "extended_s3"

#   extended_s3_configuration {
#     role_arn   = aws_iam_role.firehose_role.arn
#     bucket_arn = aws_s3_bucket.bucket.arn

#     # processing_configuration {
#     #   enabled = "true"

#     #   processors {
#     #     type = "Lambda"

#     #     parameters {
#     #       parameter_name  = "LambdaArn"
#     #       parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
#     #     }
#     #   }
#     # }
#   }
# }

# # S3 for kinesis streams
# resource "aws_s3_bucket" "bucket" {
#   bucket = "tf-brp-cdc-poc"
# }

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "public"
# }

# resource "aws_iam_role" "firehose_assume_role" {
#   name        = "firehose-assume-role"
#   description = "Allows DMS to manage VPC"
#   assume_role_policy = <<EOF
#   {
#     "Version" : "2012-10-17",
#       "Statement" : [
#         {
#         "Action" : "sts:AssumeRole",
#         "Principal" : {
#             "Service" : "firehose.amazonaws.com"
#         },
#         "Effect" : "Allow",
#         "Sid" : ""
#         }
#       ]
#     }
#   EOF
# }
#   resource "aws_iam_policy" "iam_policy_to_write_s3" {
 
#     name         = "aws-iam-policy-for-kinesisFH-write-S3"
#     path         = "/"
#     description  = "AWS IAM Policy for write to S3"
#     policy = <<EOF
#     {
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Action": [
#           "S3:*"
#         ],
#         "Resource": "arn:aws:S3:*:*:*",
#         "Effect": "Allow"
#       }
#     ]
#     }
#     EOF
#   }

# # Attach IAM Policy to IAM Role

# resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role_dms" {
#  role        = aws_iam_role.firehose_assume_role.name
#  policy_arn  = aws_iam_policy.iam_policy_to_write_s3.arn
# }

#TODO: Add delivery stream (s3) and logs