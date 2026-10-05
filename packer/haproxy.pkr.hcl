packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

source "amazon-ebs" "haproxy" {
  ami_name      = "lab-2-haproxy-{{timestamp}}"
  instance_type = "t3.micro"
  region        = var.aws_region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }

    owners      = ["099720109477"]
    most_recent = true
  }

  ssh_username = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.haproxy"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y haproxy",
      "sudo systemctl enable haproxy"
    ]
  }
}
