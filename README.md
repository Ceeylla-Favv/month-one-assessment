# TechCorp AWS Infrastructure — Month 1 Assessment

A production-grade AWS infrastructure built with Terraform, featuring a
VPC with public/private subnets, Application Load Balancer, bastion host,
web servers, and a PostgreSQL database. Passwords are stored in
AWS Secrets Manager — never in code or scripts.

## Architecture

```
Internet
    │
    ▼
Application Load Balancer (public subnets, both AZs)
    │
    ├──► Web Server 1 (private subnet, AZ-a)
    │
    └──► Web Server 2 (private subnet, AZ-b)

Your Laptop ──SSH──► Bastion Host (public subnet, AZ-a)
                          │
                          ├──SSH──► Web Server 1
                          ├──SSH──► Web Server 2
                          └──SSH──► Database Server (private subnet, AZ-a)
```

## Prerequisites

Before you begin you need:

1. **An AWS account** with an IAM user that has AdministratorAccess
2. **AWS CLI installed and configured** (`aws configure`)
3. **Terraform >= 1.5.0 installed**
4. **An SSH key pair created in AWS Console** → EC2 → Key Pairs
   - Name it `techcorp-key`
   - Download the `.pem` file
   - Run: `chmod 400 ~/.ssh/techcorp-key.pem`

## Deployment

### 1. Clone and configure

```bash
git clone https://github.com/Ceeylla-Favv/month-one-assessment.git
cd month-one-assessment

# Create your personal variables file (never committed to git)
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in:
- `my_ip` — run `curl ifconfig.me` and add `/32` e.g. `105.112.34.56/32`
- `key_pair_name` — the name of your key pair in AWS
- `web_server_password` — minimum 12 characters
- `db_password` — minimum 12 characters

### 2. Initialise Terraform

```bash
terraform init
```

Downloads the AWS provider plugin into `.terraform/`.

### 3. Preview what will be built

```bash
terraform plan
```

Read through the output. You should see approximately 30+ resources to create.
Screenshot this for your evidence.

### 4. Build the infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Takes approximately 10 minutes — NAT Gateways
are the slowest part. Screenshot the completed output showing your outputs.

### 5. Wait for servers to initialise

After `terraform apply` completes, the servers still need ~5 minutes to
run their user_data scripts (install Apache, PostgreSQL, fetch passwords).

---

## Accessing the Infrastructure

### View the web application

Copy the `load_balancer_dns` output and paste it into your browser.
Refresh several times — the instance ID should alternate between two
different values, proving load balancing is working.

### SSH to the Bastion Host

```bash
ssh -i ~/.ssh/techcorp-key.pem ec2-user@<bastion_public_ip>
```

The `bastion_public_ip` is in your Terraform output.
There is also a ready-to-run command in the `ssh_bastion_command` output.

### SSH from Bastion to Web Servers

Once inside the bastion:

```bash
ssh webuser@<web_1_private_ip>
# Password: whatever you set in web_server_password
```

### SSH from Bastion to Database Server

```bash
ssh dbuser@<db_private_ip>
# Password: whatever you set in db_password
```

### Connect to PostgreSQL

Once SSH'd into the database server:

```bash
psql -U techcorp -d techcorp_db -h localhost
# Password: whatever you set in db_password
# You will see: techcorp_db=#
# Type \q to exit
```

---

## Debugging

If web servers aren't responding after 10 minutes, SSH to the server
and check the setup log:

```bash
cat /var/log/user-data.log
```

---

## Cleanup — Run This When Done

**Important:** NAT Gateways cost approximately $0.045/hour each.
Two of them running for a day costs about $2.20. Destroy when finished.

```bash
terraform destroy
```

Type `yes`. This deletes every resource and stops all billing.

---

## Security Design Decisions

| Decision | Why |
|---|---|
| Password security | Passwords are declared as Terraform variables (`sensitive = true`) and injected into server scripts at deploy time
| Private subnets for web/DB servers | Internet cannot initiate connections to them |
| Bastion as single SSH entry point | One door to audit, not four |
| Security groups using `security_groups` not `cidr_blocks` | Only specific resources can connect, not entire IP ranges |
| IMDSv2 enforced (`http_tokens = required`) | Prevents SSRF attacks leaking instance credentials |
| IAM policy scoped to specific secret ARNs | Servers can only read their own secrets, nothing else |