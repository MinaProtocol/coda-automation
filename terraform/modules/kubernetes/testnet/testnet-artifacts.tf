resource "null_resource" "block_producer_key_generation" {
  provisioner "local-exec" {
      command = "../../../scripts/generate-keys-and-ledger.sh ${var.testnet_name} true false"
  }
}

resource "null_resource" "block_producer_whalekey_uploads" {
  provisioner "local-exec" {
      command = "python3 ../../../scripts/testnet-keys.py k8s upload-online-whale-keys --namespace ${var.testnet_name} --cluster ${var.cluster_name} --key-dir keys/testnet-keys/${var.testnet_name}_online-whale-keyfiles"
  }
  depends_on  = [null_resource.block_producer_key_generation]
}

resource "null_resource" "block_producer_fishkey_uploads" {
  provisioner "local-exec" {
      command = "python3 ../../../scripts/testnet-keys.py k8s upload-online-fish-keys --namespace ${var.testnet_name} --cluster ${var.cluster_name} --key-dir keys/testnet-keys/${var.testnet_name}_online-fish-keyfiles"
  }
  depends_on  = [null_resource.block_producer_key_generation]
}
