variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "project name"
  type        = string
  default     = "tfgo"
}

variable "stage" {
  description = "stage"
  type        = string
  default     = "dev"
}
variable "queue_name" {
  description = "queue name"
  type        = string
  default     = "Queue-A"
}

variable "topic_name" {
  description = "topic name"
  type        = string
  default     = "Topic-A"
}
