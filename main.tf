###############################################################################
# 
# Programador: Francisco E. Galeana G.
# 
# Fecha Creación: 25-oct-2024
# Fecha Modificación: 26-oct-2024 
# 
###############################################################################

#Proveedor
provider "aws" {
  access_key = var.AWS_Key
  secret_key = var.AWS_Secret
  region = var.Region_AWS
}

#Crear VPC
resource "aws_vpc" "VPC10" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC-Actividad010a"
  }
}

#Crear subred publica 1
resource "aws_subnet" "SubredPublica01" {
  vpc_id = aws_vpc.VPC10.id
  cidr_block = "10.0.0.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "SubredPublica01"
  }
}

#Crear subred publica 2
resource "aws_subnet" "SubredPublica02" {
  vpc_id = aws_vpc.VPC10.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "SubredPublica02"
  }
}

#Crear subred privada 1
resource "aws_subnet" "SubredPrivada01" {
  vpc_id = aws_vpc.VPC10.id
  cidr_block = "10.0.128.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "SubredPrivada01"
  }
}

#Crear subred privada 2
resource "aws_subnet" "SubredPrivada02" {
  vpc_id = aws_vpc.VPC10.id
  cidr_block = "10.0.144.0/20"
  availability_zone = "us-east-1b"

  tags = {
    Name = "SubredPrivada02"
  }
}

#Crear InternetGateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.VPC10.id
  tags = {
    Name = "InternetGatewayPrincipal"
  }
}

#Crear tabla de ruteo
resource "aws_route_table" "TablaRuteo" {
  vpc_id = aws_vpc.VPC10.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }

  tags = {
    Name = "Tabla de Ruteo predeterminada"
  }
}

#Asociar tabla de ruteo a subred publica 1
resource "aws_route_table_association" "AsociacionTRSRPub1" {
  subnet_id = aws_subnet.SubredPublica01.id
  route_table_id = aws_route_table.TablaRuteo.id
}

#Asociar tabla de ruteo a subred publica 2
resource "aws_route_table_association" "AsociacionTRSRPub2" {
  subnet_id = aws_subnet.SubredPublica02.id
  route_table_id = aws_route_table.TablaRuteo.id
}

#Asociar tabla de ruteo a subred privada 1
resource "aws_route_table_association" "AsociacionTRSRPriv1" {
  subnet_id = aws_subnet.SubredPrivada01.id
  route_table_id = aws_route_table.TablaRuteo.id
}

#Asociar tabla de ruteo a subred privada 2
resource "aws_route_table_association" "AsociacionTRSRPriv2" {
  subnet_id = aws_subnet.SubredPrivada02.id
  route_table_id = aws_route_table.TablaRuteo.id
}

#Definir grupos de seguridad para las redes
resource "aws_security_group" "SG-VPC10" {
  vpc_id = aws_vpc.VPC10.id

  #SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #RDP
  ingress {
    from_port = 3389
    to_port = 3389
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ICMP
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #winrm http
  ingress {
  from_port   = 5985
  to_port     = 5985
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  #winrm https
  ingress {
  from_port   = 5986
  to_port     = 5986
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Permitir-SSH-HTTP-RDP"
  }
}

#Crear par de claves en AWS
resource "aws_key_pair" "AWSLlaves" {
  key_name = "Windows&Ubuntu"
  public_key = file("C:/Users/franc/.ssh/id_rsa.pub")
}

#Instancia EC2 Ubuntu 20.04
resource "aws_instance" "InstnaciaUbuntu" {
  ami = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.SubredPublica02.id
  vpc_security_group_ids = [ aws_security_group.SG-VPC10.id ]
  key_name = aws_key_pair.AWSLlaves.key_name
  associate_public_ip_address = true

  tags = {
    Name = "UbuntuServer"
  }
}

#Instancia EC2 Windows
resource "aws_instance" "InstanciaWindows" {
  ami = "ami-0324a83b82023f0b3"
  instance_type = "t2.medium"
  subnet_id = aws_subnet.SubredPublica01.id
  vpc_security_group_ids = [ aws_security_group.SG-VPC10.id ]
  key_name = aws_key_pair.AWSLlaves.key_name
  associate_public_ip_address = true

  tags = {
    Name = "WindowsServer"
  }
}

#Output para IP privada de Ubuntu
output "IPPrivadaUbuntu" {
  value = aws_instance.InstnaciaUbuntu.private_ip
  description = "Direccion IP privada de la instancia Ubuntu"
}

#Output para IP publica de Ubuntu
output "IPPublicaUbuntu" {
  value = aws_instance.InstnaciaUbuntu.public_ip
  description = "Direccion IP publica de la instancia Ubuntu"
}

#Output para ID de la instancia Ubuntu
output "IDUbuntu" {
  value = aws_instance.InstnaciaUbuntu.id
  description = "ID de la instancia Ubuntu"
}

#Output para IP Privada de Windows
output "IPPrivadaWindows" {
  value = aws_instance.InstanciaWindows.private_ip
  description = "Direccion IP privada de la instancia Windows"
}

#Output para IP Publica de Windows
output "IPPublicaWindows" {
  value = aws_instance.InstanciaWindows.public_ip
  description = "Direcion IP publica de la instancia Windows"
}

#Output para ID de la instancia de Windows
output "IDWindows" {
  value = aws_instance.InstanciaWindows.id
  description = "ID de la instancia de Windows"
}