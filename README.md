# Lab 2 — Infrastructure as Code

This project demonstrates an Infrastructure as Code workflow using **Packer and Terraform** on AWS.

The infrastructure uses an **Auto Scaling Group** to maintain multiple HAProxy nodes and an **Application Load Balancer** to distribute HTTP traffic between them.

## Architecture

```text
                         Internet
                            │
                            ▼
                    ┌───────────────┐
                    │      ALB      │
                    │   HTTP : 80   │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ Target Group  │
                    │ Health checks │
                    └───────┬───────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ HAProxy  │  │ HAProxy  │  │ HAProxy  │
        │  node 1  │  │  node 2  │  │  node 3  │
        └──────────┘  └──────────┘  └──────────┘
              ▲             ▲             ▲
              └─────────────┼─────────────┘
                            │
                    Auto Scaling Group
                            ▲
                            │
                     Launch Template
                            ▲
                            │
                    Custom HAProxy AMI
                            ▲
                            │
                          Packer
```

The Auto Scaling Group maintains the desired number of HAProxy nodes. The Application Load Balancer sends requests only to healthy nodes.

## Tools

* AWS
* Packer
* Terraform
* Ubuntu 24.04
* HAProxy

## Project structure

```text
lab-2/
├── README.md
├── packer/
│   └── haproxy.pkr.hcl
└── terraform/
    ├── provider.tf
    ├── network.tf
    ├── compute.tf
    ├── load_balancer.tf
    ├── variables.tf
    └── outputs.tf
```

## 1. Configure AWS access

Log in to the TalTech AWS account using AWS SSO:

```bash
export AWS_PROFILE=taltech
aws sso login --profile taltech
```

Verify that the credentials work:

```bash
aws sts get-caller-identity
```

## 2. Build the AMI

Initialize the Packer plugins:

```bash
packer init packer/haproxy.pkr.hcl
```

Validate the Packer configuration:

```bash
packer validate packer/haproxy.pkr.hcl
```

Build the AMI:

```bash
packer build packer/haproxy.pkr.hcl
```

The resulting AMI contains Ubuntu 24.04 with HAProxy installed and enabled.

Copy the resulting AMI ID into `terraform/compute.tf`.

## 3. Create the infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Terraform creates:

* A security group for the Application Load Balancer
* A security group for the HAProxy nodes
* A Launch Template using the custom AMI
* An Auto Scaling Group
* A Target Group with HTTP health checks
* An Application Load Balancer
* An HTTP listener

The number of HAProxy nodes can be changed using the `node_count` variable in `variables.tf`. The default value is `3`.

The Auto Scaling Group maintains the configured number of nodes.

## 4. Test the load balancer

Send a request to the load balancer:

```bash
curl http://$(terraform output -raw load_balancer_dns)
```

The response identifies the HAProxy node that handled the request:

```text
Hello from HAProxy node: ip-172-31-0-201
```

Send multiple requests to observe the load balancing:

```bash
for i in {1..10}; do curl -s http://$(terraform output -raw load_balancer_dns); echo; done
```

The responses should show different HAProxy node hostnames, demonstrating that the Application Load Balancer distributes requests between the healthy nodes.

The Target Group health status can be checked in the AWS console.

## 5. Clean up

When finished, destroy the infrastructure:

```bash
terraform destroy
```

This removes the Application Load Balancer, Target Group, Auto Scaling Group, Launch Template, security groups, and EC2 instances.

The custom AMI remains and can be reused.

## Workflow summary

```text
Packer    → builds the HAProxy machine image
Terraform → creates the AWS infrastructure
ASG       → maintains the HAProxy node fleet
ALB       → distributes traffic between healthy nodes
```

Infrastructure can be recreated from code without manually configuring AWS resources or servers.
