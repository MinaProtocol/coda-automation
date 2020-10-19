import click
import json
import subprocess
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from google.cloud import storage
from pprint import pprint



@click.group()
@click.option('--debug/--no-debug', default=False)
def cli(debug):
    pass

@cli.group()
def keys():
  pass

@keys.command()
@click.option('--bucket-name', default="network-keypairs", help='The name of the bucket keys are stored in.')
@click.option('--blob-name', help='Required: The Google Storage Blob to download.')
@click.option('--namespace', default="default", help='The namespace this key should be deployed to.')
@click.option('--secret-name', default=None, help='Override the name of the deployed secret, defaults to Google Storage object name.')
def deploy(bucket_name, blob_name, namespace, secret_name):
  # Setup metadata 
  if secret_name == None:
    secret_name = blob_name
  # Setup google 
  storage_client = storage.Client()
  bucket = storage_client.bucket(bucket_name)
  blob = bucket.blob(blob_name)
  # Download GS Object 
  key = blob.download_as_string().decode("utf-8")

  # Extract data into dict {public_key: str, private_key: dict, nickname: str}
  payload = json.loads(key)

  # Configure k8s
  config.load_kube_config()
  v1 = client.CoreV1Api()

  # Create secret with public_key and private_key field 
  metadata = client.V1ObjectMeta(name=secret_name)
  body = client.V1Secret(string_data=payload, metadata=metadata)
  # Deploy to specified namespace
  try:
    api_response = v1.create_namespaced_secret(namespace, body)
    pprint(api_response)
  except ApiException as e:
    print("Exception when calling CoreV1Api->create_namespaced_secret: %s\n" % e)

if __name__ == "__main__":
  cli()