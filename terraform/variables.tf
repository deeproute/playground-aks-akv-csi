variable "location" {
    type          = string
    default       = "westeurope"
    description   = "Location of the resource group."
}

variable resource_group_name {
    type    = string
    default = "azure-k8stest"
}

variable cluster_name {
    type    = string
    default = "k8stest"
}

variable private_cluster_enabled {
    type    = bool
    default = false
}

variable kubernetes_version {
    type    = string
}

variable "node_count" {
    type    = number
    default = 1
}

variable vm_size {
    type    = string
    default = "Standard_B2s"
}

