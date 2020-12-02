resource "null_resource" "block_producer_key_generation" {
  provisioner "local-exec" {
      command = "../../../scripts/generate-keys-and-ledger.sh ${var.testnet_name} true false"
  }
}

resource "null_resource" "prepare_keys_for_deployment" {
  provisioner "local-exec" {
      command = "mv ../../../keys ../../../terraform/testnets/${var.testnet_name}/keys"
  }
  depends_on  = [kubernetes_namespace.testnet_namespace, null_resource.block_producer_key_generation]
}

resource "null_resource" "block_producer_whalekey_uploads" {
  provisioner "local-exec" {
      command = "python3 ../../../scripts/testnet-keys.py k8s upload-online-whale-keys --namespace ${var.testnet_name} --cluster ${var.cluster_name} --key-dir ../../../terraform/testnets/${var.testnet_name}/keys/testnet-keys/${var.testnet_name}_online-whale-keyfiles"
  }
  depends_on  = [
    kubernetes_namespace.testnet_namespace,
    null_resource.block_producer_key_generation,
    null_resource.prepare_keys_for_deployment
  ]
}

resource "null_resource" "block_producer_fishkey_uploads" {
  provisioner "local-exec" {
      command = "python3 ../../../scripts/testnet-keys.py k8s upload-online-fish-keys --namespace ${var.testnet_name} --cluster ${var.cluster_name} --key-dir ../../../terraform/testnets/${var.testnet_name}/keys/testnet-keys/${var.testnet_name}_online-fish-keyfiles"
  }
  depends_on  = [
    kubernetes_namespace.testnet_namespace,
    null_resource.block_producer_key_generation,
    null_resource.prepare_keys_for_deployment
  ]
}
