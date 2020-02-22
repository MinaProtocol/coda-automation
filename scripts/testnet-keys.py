import docker
import os
import subprocess
from pathlib import Path
import click
import glob
import json
import csv
import natsort 

client = docker.from_env()
CODA_DAEMON_IMAGE = "codaprotocol/coda-daemon:0.0.11-beta1-release-0.0.12-beta-493b4c6"
SCRIPT_DIR = Path(__file__).parent.absolute()

# A list of services to add and the percentage of total stake they should be allocated
DEFAULT_SERVICES = {
    "faucet": 0.05,
    "echo": 0.00005
}
@click.group()
@click.option('--debug/--no-debug', default=False)
def cli(debug):
    pass

@cli.group()
def keys():
  pass

@cli.group()
def ledger():
  pass

@cli.group()
def aws():
  pass

@cli.group()
def k8s():
  pass

### 
# Commands for generating Coda Keypairs 
###

@keys.command()
@click.option('--keyset-name', default="testnet-keys", help='The name of the keyset to generate.')
@click.option('--privkey-pass', default="naughty blue worm", help='The password to use when generating keys.')
@click.option('--num-fish-producers', default=1, help='The number of Fish Producer keys to generate.')
@click.option('--num-whale-producers', default=1, help='The number of Whale Producer keys to generate.')
@click.option('--num-seed-nodes', default=2, help='The number of Seed Node LibP2P Keys to generate')
@click.option('--service-name', multiple=True, default=["faucet", "echo"], help='The name(s) of one or more Services.')
def generate_keyset(keyset_name, privkey_pass, num_fish_producers, num_whale_producers, num_seed_nodes, service_name):
    """Generate Public and Private Keys for an entire Testnet."""
    # Create Keyset Directory
    keyset_dir = Path(SCRIPT_DIR / keyset_name)
    keyset_dir.mkdir(parents=True, exist_ok=True)
    fish_producer_dir = keyset_dir / "fish_producers"
    whale_producer_dir = keyset_dir / "whale_producers"
    service_dir = keyset_dir / "services"
    seed_nodes_dir = keyset_dir / "seed_nodes"

    block_producer_keypairs = {
        "whale": {
            "online": {},
            "offline": {}
        },
        "fish": {
            "online": {},
            "offline": {}
        },
    }
    # Generate Block Producer Keys
    for type in ("online", "offline"):
        for name in ("whale", "fish"):
            for producer_number in range(1, num_fish_producers+1 if name == "fish" else num_whale_producers+1):   
                producer_name = "{}_{}_producer_{}".format(type, name, producer_number)         
                print("Processing {}".format(producer_name))
                key_path = keyset_dir / "{}_{}_producers".format(type, name) 
                # key outputted to file
                pubkey = client.containers.run(
                    CODA_DAEMON_IMAGE,
                    entrypoint="bash -c",  
                    command=["CODA_PRIVKEY_PASS='{}' coda client-old generate-keypair -privkey-path /keys/{}".format(privkey_pass, producer_name)], 
                    volumes={ key_path.absolute(): {'bind': '/keys', 'mode': 'rw'} }
                )
                
                producer_keypair = {}
                # Load private key
                with open((key_path / producer_name).absolute()) as f:
                    sk_raw = f.readline().strip()
                    sk = json.loads(sk_raw)
                    producer_keypair["private-key"] = sk

                with open((key_path / (producer_name + ".pub")).absolute()) as f:
                    pk_raw = f.readline().strip()
                    producer_keypair["public-key"] = pk_raw
                
                block_producer_keypairs[name][type][producer_name] = producer_keypair
    #print(json.dumps(block_producer_keypairs, indent=3))

    service_keypairs = {}
    # Generate Service Keys
    for name in service_name:
        print("Processing {} Service".format(name))
        key_path = (service_dir / "{}".format(name))
        # key outputted to file
        pubkey = client.containers.run(
            CODA_DAEMON_IMAGE,
            entrypoint="bash -c",  
            command=["CODA_PRIVKEY_PASS='{}' coda client-old generate-keypair -privkey-path /keys/{}".format(privkey_pass, name)], 
            volumes={key_path.absolute() : {'bind': '/keys', 'mode': 'rw'}}
        )
        
        service_keypair = {}
        # Load private key
        with open((key_path / "{}".format(name)).absolute()) as f:
            sk_raw = f.readline().strip()
            sk = json.loads(sk_raw)
            service_keypair["private-key"] = sk

        with open((key_path / "{}".format(name + ".pub")).absolute()) as f:
            pk_raw = f.readline().strip()
            service_keypair["public-key"] = pk_raw
        
        service_keypairs[name] = service_keypair
    #print(json.dumps(service_keypairs, indent=3))

    seed_keys = {}
    seed_nodes_dir.mkdir(parents=True, exist_ok=True)
    for seed_number in range(1, num_seed_nodes+1):
        seed_keys["seed_{}".format(seed_number)] = {}
        # Key outputted to stdout
        key_raw = client.containers.run(CODA_DAEMON_IMAGE, entrypoint="bash -c", command=["coda advanced generate-libp2p-keypair"])
        key_parsed = str(key_raw).split("\\n")[1]
        all_key_file = open(seed_nodes_dir / "seed_{}_libp2p.txt".format(seed_number), "w")

        client_id = key_parsed.split(",")[2]
        client_id_file = open(seed_nodes_dir / "seed_{}_client_id.txt".format(seed_number), "w")
        # Write Key to file
        all_key_file.write(key_parsed)
        client_id_file.write(client_id)
        print(client_id)

        seed_keys["seed_{}".format(seed_number)]["libp2p"] = key_parsed
        seed_keys["seed_{}".format(seed_number)]["client_id"] = client_id
    #print(json.dumps(seed_keys, indent=2))

    output_payload = {
        "seed_keys": seed_keys,
        "service_keypairs": service_keypairs,
        "block-producer_keypairs": block_producer_keypairs
    }
    with open(keyset_dir / "{}.json".format(keyset_name), "w") as f:
        f.write(json.dumps(output_payload, indent=2))
        f.close()



if __name__ == "__main__": 
    cli()