variable "access" {
  default = "AWS_ID"
}
variable "secret" {
  default = "AWS_KEY"
}

output "access" {
  value = "${var.access}"
}
output "secret" {
  value = "${var.secret}"
}
