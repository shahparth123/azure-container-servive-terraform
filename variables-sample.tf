variable "resource_group_name" {
  type        = string
  default     = "oxford-session"
  description = "Location for all resources."
}

variable "resource_group_location" {
  type        = string
  default     = "southindia"
  description = "Location for all resources."
}

variable "container_group_name_prefix" {
  type        = string
  description = "Prefix of the container group name that's combined with a random value so name is unique in your Azure subscription."
  default     = "flask-app"
}


variable "container_name_prefix" {
  type        = string
  description = "Prefix of the container name that's combined with a random value so name is unique in your Azure subscription."
  default     = "python-flask-server"
}

variable "image" {
  type        = string
  description = "Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials."
  default     = "ghcr.io/shahparth123/flask-docker-azure:master"
}

variable "port" {
  type        = number
  description = "Port to open on the container and the public IP address."
  default     = 80
}

variable "cpu_cores" {
  type        = number
  description = "The number of CPU cores to allocate to the container."
  default     = 1
}

variable "memory_in_gb" {
  type        = number
  description = "The amount of memory to allocate to the container in gigabytes."
  default     = 1
}

variable "restart_policy" {
  type        = string
  description = "The behavior of Azure runtime if container has stopped."
  default     = "Always"
  validation {
    condition     = contains(["Always", "Never", "OnFailure"], var.restart_policy)
    error_message = "The restart_policy must be one of the following: Always, Never, OnFailure."
  }
}

variable "container_registry_username" {
  type        = string
  description = "Username for container registry"
  default     = "shahparth123"
}

variable "container_registry_password" {
  type        = string
  description = "password for container registry"
  default     = ""
}

variable "container_registry_url" {
  type        = string
  description = "url for container registry"
  default     = "ghcr.io"
}


