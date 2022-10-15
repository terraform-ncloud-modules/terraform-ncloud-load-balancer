variable "name" {
  description = "(Required) See the description in the readme"
  type        = string
}

variable "description" {
  description = "(Required) See the description in the readme"
  type        = string
  default     = ""
}

variable "type" {
  description = "(Optional) See the description in the readme"
  type        = string
}

variable "network_type" {
  description = "(Optional) See the description in the readme"
  type        = string
  default     = "PUBLIC"
}

variable "vpc_name" {
  description = "(Required) See the description in the readme"
  type        = string
  default     = null
}

variable "subnet_names" {
  description = "(Required) See the description in the readme"
  type        = list(any)
  default     = null
}


variable "subnet_no_list" {
  description = "(Required) See the description in the readme"
  type        = list(any)
  default     = null
}

variable "throughput_type" {
  description = "(Optional) See the description in the readme"
  type        = string
  default     = "SMALL"
}

variable "idle_timeout" {
  description = "(Required) See the description in the readme"
  type        = number
  default     = 60
}

variable "listeners" {
  description = "(Required) See the description in the readme"
  type        = list(any)
  default     = []
}
