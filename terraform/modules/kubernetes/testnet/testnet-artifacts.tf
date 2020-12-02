resource "null_resource" "block_producer_key_generation" {
  provisioner "local-exec" {
<<<<<<< HEAD
      command = "../../../scripts/generate-keys-and-ledger.sh --testnet=${var.testnet_name} --wc=${var.whale_count} --fc=${var.fish_count} --reset=true"
  }
}

resource "null_resource" "prepare_keys_for_deployment" {
  provisioner "local-exec" {
      command = "sudo chmod -R a+rwX ../../../keys"
  }
  depends_on  = [kubernetes_namespace.testnet_namespace, null_resource.block_producer_key_generation]
}

resource "null_resource" "block_producer_uploads" {
  provisioner "local-exec" {
      command = "../../../scripts/upload-keys-k8s.sh ${var.testnet_name}"
  }
  depends_on = [
    kubernetes_namespace.testnet_namespace,
    null_resource.block_producer_key_generation,
    null_resource.prepare_keys_for_deployment
  ]
=======
      command = "../../../scripts/generate-keys-and-ledger.sh ${var.testnet_name}"
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
>>>>>>> c952668... rename ci-net testnet module and secrets (now artifact generation/upload) file
}
