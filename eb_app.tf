terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # required
      version = "~> 3.27"       # required
    }
  }

  backend "s3" {
    bucket = "eb-qrts-app"  # S3 bucket name
    key    = "path/to/my/key" # S3 key name
    region = "ap-southeast-1"      # S3 region
  }
}

# AWS Provider configuration
provider "aws" {
  profile = "default"   # AWS profile 
  region  = "ap-southeast-1" # AWS region
}


variable "create_bucket" {
  description = "Set to true if you want to create the S3 bucket, false otherwise."
  type        = bool
  default     = false
}

# Create S3 bucket for Python Flask app
resource "aws_s3_bucket" "eb_bucket" {
  count = var.create_bucket ? 1 : 0
  bucket = "eb-qrts-app" # Name of S3 bucket to create for Flask app deployment needs to be unique 
}

# Define App files to be uploaded to S3
#resource "aws_s3_bucket_object" "eb_bucket_obj" {
  #bucket = aws_s3_bucket.eb_bucket.id
  #key    = "beanstalk/tg_query_api.jar" # S3 Bucket path to upload app files
  #source = "tg_query_api.jar"           # Name of the file on GitHub repo to upload to S3
#}

# Define Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = "eb-qrts-app"   # Name of the Elastic Beanstalk application
  description = "qrts app" # Description of the Elastic Beanstalk application
}

# Create Elastic Beanstalk environment for application with defining environment settings
resource "aws_elastic_beanstalk_application_version" "eb_app_ver" {
  bucket      = aws_s3_bucket.eb_bucket.id                    # S3 bucket name
  #key         = aws_s3_bucket_object.eb_bucket_obj.id         # S3 key path 
  key         = "beanstalk/tg_query_api.jar"         # S3 key path 
  application = aws_elastic_beanstalk_application.eb_app.name # Elastic Beanstalk application name
  name        = "eb-qrts-app-version-lable"                # Version label for Elastic Beanstalk application
}

resource "aws_elastic_beanstalk_environment" "tfenv" {
  name                = "eb-qrts-app-env"
  application         = aws_elastic_beanstalk_application.eb_app.name             # Elastic Beanstalk application name
  solution_stack_name = "Corretto 17 running on 64bit Amazon Linux 2023"         # Define current version of the platform
  description         = "environment for qrts app"                               # Define environment description
  version_label       = aws_elastic_beanstalk_application_version.eb_app_ver.name # Define version label

  setting {
    namespace = "aws:autoscaling:launchconfiguration" # Define namespace
    name      = "IamInstanceProfile"                  # Define name
    value     = "aws-elasticbeanstalk-ec2-role"       # Define value
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = "database-1.c7qq28y8u55e.ap-southeast-1.rds.amazonaws.com"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PORT"
    value     = "5432"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_DB_NAME"
    value     = "afcdb_tg"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = "postgres"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = "postgres"
  }

}
