packer {
  required_plugins {
    ibmcloud = {
      version = ">=v3.0.0"
      source  = "github.com/IBM/ibmcloud"
    }
  }
}

variable "ibmcloud_api_key" {
  type = string
  default = "${env("IBMCLOUD_API_KEY")}"
}

variable "region" {
  type = string
  default = "${env("IBMCLOUD_REGION")}"
}

variable "resource_group_name" {
  type = string
  default = "${env("RESOURCE_GROUP_NAME")}"
}

variable "subnet_id" {
  type = string
  default = "${env("SUBNET_ID")}"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  name      = "dev-${local.timestamp}"
}

source "ibmcloud-vpc" "dev" {
  api_key = "${var.ibmcloud_api_key}"
  region  = "${var.region}"

  subnet_id          = "${var.subnet_id}"
  resource_group_name  = "${var.resource_group_name}"
  security_group_id  = ""
  vsi_base_image_name  = "ibm-ubuntu-22-04-4-minimal-amd64-1"
  vsi_profile        = "cx2-2x4"
  vsi_interface      = "public"
  vsi_user_data_file = ""

  image_name   = "${local.name}"
  communicator = "ssh"
  ssh_username = "root"
  ssh_port     = 22
  ssh_timeout  = "15m"

  timeout = "30m"
}

build {
  name = "vpc-packer-builder"
  sources = [
    "source.ibmcloud-vpc.dev"
  ]

  provisioner "file" {
    source      = "./init.sh"
    destination = "/opt/init.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    environment_vars = [
      "REGION=${var.region}",
      "PACKER_TEMPLATE=${local.name}"

    ]
    inline = [
      "chmod +x /opt/init.sh",
      "/opt/init.sh"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
