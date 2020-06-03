variable "credentials" {
  description = "Location of the credentials keyfile."
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "node_pools" {
  type = list(map(string))
}