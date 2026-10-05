resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  content         = <<-EOT
    [web]
    ${aws_instance.server.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(path.module)}/devsecops-key.pem
  EOT
}