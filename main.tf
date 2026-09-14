provider "aws" {
  region = "eu-west-3"
}

# Récupère automatiquement la dernière image Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Crée une instance EC2
resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "devsecops-server"
  }
}

# Affiche l'IP publique après création
output "public_ip" {
  value = aws_instance.server.public_ip
}
