resource "null_resource" "block_producer_key_generation" {
  provisioner "local-exec" {
      command = "../../../scripts/generate-keys-and-ledger.sh --testnet=${var.testnet_name} --reset=false"
  }
}

resource "null_resource" "prepare_keys_for_deployment" {
  provisioner "local-exec" {
      command = "mv ../../../keys ../../../terraform/testnets/${var.testnet_name} && sudo chmod -R a+rwX ../../../terraform/testnets/${var.testnet_name}/keys"
  }
  depends_on  = [kubernetes_namespace.testnet_namespace, null_resource.block_producer_key_generation]
}

resource "null_resource" "block_producer_uploads" {
  provisioner "local-exec" {
      command = "CLUSTER=${var.cluster_name} ../../../scripts/upload-keys-k8s.sh ${var.testnet_name} terraform/testnets/${var.testnet_name}/"
  }
  depends_on = [
    kubernetes_namespace.testnet_namespace,
    null_resource.block_producer_key_generation,
    null_resource.prepare_keys_for_deployment
  ]
}

