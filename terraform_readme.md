# Terraform setup for deployment to Azure Container Instance

## 1. Install Terraform CLI and initializr Azure CLI

https://learn.microsoft.com/en-us/azure/developer/terraform/quickstart-configure

## 2. Initialize terraform repository

Create a folder which will contain infrastructure related code.

## 3. Setup pipeline for docker image generation
In our example we will host our code using github and manage CI/CD process using github actions.

For that we need to define github actions using following:
Create `.github/workflows` folder and inside that add `docker-image-build.yml` file.
```yaml
name: Create and publish a Docker image

# Configures this workflow to run every time a change is pushed to the branch called `release`.
on:
  push:
    branches: ['master']

# Defines two custom environment variables for the workflow. These are used for the Container registry domain, and a name for the Docker image that this workflow builds.
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# There is a single job in this workflow. It's configured to run on the latest available version of Ubuntu.
jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    # Sets the permissions granted to the `GITHUB_TOKEN` for the actions in this job.
    permissions:
      contents: read
      packages: write
      attestations: write
      id-token: write
      #
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      # Uses the `docker/login-action` action to log in to the Container registry registry using the account and password that will publish the packages. Once published, the packages are scoped to the account defined here.
      - name: Log in to the Container registry
        uses: docker/login-action@65b78e6e13532edd9afa3aa52ac7964289d1a9c1
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      # This step uses [docker/metadata-action](https://github.com/docker/metadata-action#about) to extract tags and labels that will be applied to the specified image. The `id` "meta" allows the output of this step to be referenced in a subsequent step. The `images` value provides the base name for the tags and labels.
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@9ec57ed1fcdbf14dcef7dfbe97b2010124a938b7
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
      # This step uses the `docker/build-push-action` action to build the image, based on your repository's `Dockerfile`. If the build succeeds, it pushes the image to GitHub Packages.
      # It uses the `context` parameter to define the build's context as the set of files located in the specified path. For more information, see "[Usage](https://github.com/docker/build-push-action#usage)" in the README of the `docker/build-push-action` repository.
      # It uses the `tags` and `labels` parameters to tag and label the image with the output from the "meta" step.
      - name: Build and push Docker image
        id: push
        uses: docker/build-push-action@f2a1d5e99d037542a71f64918e516c093c6f3fc4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```
This will build and create docker image on each push on master branch.

## 4. Create terrafrom scripts

Any terraform repository will need to have one `main.tf` file which will serve as starting point for terraform script.

Any external dependencies can be included in terraform code using `providers.tf` file

Any output variables resulting of terrafrom infrastructure generation will be defined using `outputs.tf` file.

We can reuse same infrastrucuture code by specifiying different variables using different `variables.tf` files.

### provider.tf
```terraform
terraform {
  required_version = ">=1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
   null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
  }
  
}
provider "azurerm" {
  features {}
  subscription_id = "<Azure Subscription ID>"
}
provider "null" {
  # Configuration options
}

```
### main.tf

```terraform
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_container_group" "container" {
  name                = "${var.container_group_name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label =  "${var.container_name_prefix}"
  restart_policy      = var.restart_policy
  image_registry_credential {
      username = "${var.container_registry_username}"
      password = "${var.container_registry_password}"
      server = "${var.container_registry_url}"
  }
  container {
    name   = "${var.container_name_prefix}"
    image  = var.image
    cpu    = var.cpu_cores
    memory = var.memory_in_gb
    
    ports {
      port     = var.port
      protocol = "TCP"
    }
    environment_variables = {
      PORT = 80
    }
  }
}

```

### outputs.tf
```terraform
output "container_ipv4_address" {
  value = azurerm_container_group.container.ip_address
}
```

### variables.tf
```terraform
variable "resource_group_name" {
  type        = string
  default     = "<name-of-resource-group>"
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
  default     = "<name-of-application>"
}


variable "container_name_prefix" {
  type        = string
  description = "Prefix of the container name that's combined with a random value so name is unique in your Azure subscription."
  default     = "<name-of-container>"
}

variable "image" {
  type        = string
  description = "Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials."
  default     = "<github container repository url for your project>"
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
  default     = "<github token>"
}

variable "container_registry_url" {
  type        = string
  description = "url for container registry"
  default     = "ghcr.io"
}
```

## 5. Run terrafrom script to generate infrastructure
Once code is written, you can initialize terraform providers using following command.
```bash
terraform init
```

You can preview what changes will be made by running follwoing command.

```bash
terraform plan
``` 
You can actually execute infrastructue chages by runnning following command.

```bash
 terraform apply
```
Running the code will result in output of IP address where container is deployed. 

Also you can go to azure portal to see fully qualified domain name for the application like:

 http://python-flask-server.southindia.azurecontainer.io/