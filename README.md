# Infrastructure Setup with Terraform and Ansible
This repository contains a Terraform configuration to create an AWS infrastructure and use Ansible to configure servers. The setup includes creating a Virtual Private Cloud (VPC) with both public and private subnets, security groups, EC2 instances (Ubuntu and Windows), and configuring web servers (Apache for Ubuntu and IIS for Windows) using Ansible.

## Terraform Setup
### Provider Configuration
The AWS provider is configured using the AWS Access Key, Secret Key, and the region. These values are passed as variables through a .tfvars file

### VPC and Subnets
A VPC is created with CIDR block 10.0.0.0/16, along with four subnets:
- Two public subnets for internet-facing instances.
- Two private subnets for internal use only.

### Internet Gateway and Route Table
An Internet Gateway is created for internet access and attached to the VPC. A route table is also configured with a default route to the Internet Gateway, allowing communication from the public subnets.

### EC2 Instances
Two EC2 instances are provisioned:
- A Ubuntu instance in a public subnet.
- A Windows instance in another public subnet. Both instances are configured with a security group to allow SSH, HTTP, RDP, and WinRM access.

### Security Group Configuration
A Security Group is created for allowing necessary traffic like SSH, HTTP, RDP, and ICMP (for testing). For Windows instances, WinRM (for remote management) is also enabled.

### Key Pair and SSH Configuration
An AWS key pair is generated to securely access the instances via SSH. The key is used to connect to both Ubuntu and Windows instances.

### Outputs
Outputs are defined to return the private and public IP addresses of both Ubuntu and Windows instances for easy access


## Ansible Configuration
### Windows Instance Configuration
Before using Ansible to configure the Windows instance, several steps need to be followed:
1. Convert the RSA key to .pem format to access Windows instances.
```cmd
ssh-keygen -p -m PEM -f "C:/key/path/id_rsa"
```

2. Decrypt the Windows instance password using the AWS CLI:
```cmd
aws ec2 get-password-data --instance-id "instance_id" --priv-launch-key "path_to_rsa_key" --region "aws_region"
```

3. Activate ICMP to enable ping on the Windows instance:
```powershell
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"
```

4. Configure WinRM to allow Ansible to communicate with the Windows instance by running the following commands:
```powershell
# Enable PowerShell remoting
Enable-PSRemoting -Force

# Set WinRM service to start automatically
Set-Service WinRM -StartupType 'Automatic'

# Configure WinRM service
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $true
Set-Item -Path 'WSMan:\localhost\Service\Auth\Basic' -Value $true
Set-Item -Path 'WSMan:\localhost\Service\Auth\CredSSP' -Value $true

# Create a self-signed certificate and configure the HTTPS listener
$cert = New-SelfSignedCertificate -DnsName $(Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/public-hostname) -CertStoreLocation "cert:\LocalMachine\My"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname="$(Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/public-hostname)";CertificateThumbprint="$($cert.Thumbprint)"}"

# Create a firewall rule to allow incoming HTTPS traffic for WinRM
New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow

# Configure TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Set local account token filter policy
New-ItemProperty -Name LocalAccountTokenFilterPolicy -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -PropertyType DWord -Value 1 -Force

# Set execution policy to unrestricted
Set-ExecutionPolicy Unrestricted -Force

# Restart WinRM service
Restart-Service WinRM
```

### Ansible Configuration
On the Ubuntu instance, Apache is installed using an Ansible playbook (apache.yml).

### Windows Instance Configuration
For the Windows instance, IIS is installed via an Ansible playbook (iis.yml).

## Running playbooks
After configuring the Windows instance, you can run the following Ansible commands to configure Apache and IIS respectively:

- For the Ubuntu instance:
```bash
ansible-playbook apache.yml -l Ubuntu
```

- For the Windows instance:
```
ansible-playbook iis.yml -l Windows
```

## Final Outcome
Once the playbooks are executed successfully, you can access the default Apache page on the Ubuntu instance and the IIS page on the Windows instance by navigating to their public IPs.
