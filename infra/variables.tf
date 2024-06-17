variable "env" {
    description = "The environment"
}

variable "bucket_name" {
    description = "The name of the S3 bucket to store Terraform state"
} 

variable "api_gateway_name" {
    description = "The name of the API Gateway"
}

variable "runtime" {
    description = "The runtime for the Lambda function"
}

variable "timeout" {
    description = "The amount of time the Lambda function has to run in seconds"
}

variable "memory_size" {
    description = "The amount of memory the Lambda function has access to in MB"
}