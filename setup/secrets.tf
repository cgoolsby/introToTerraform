variable "access" {
  default = "AKIAJCJETRBBQR4WFRBQ"
}
variable "secret" {
  default = "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"
}

output "access" {
  value = "${var.access}"
}
output "secret" {
  value = "${var.secret}"
}
