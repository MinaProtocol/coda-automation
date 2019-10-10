from collections import Counter
from itertools import chain

def snark_fees_collected(blocks):
    count = Counter()
    jobs = chain.from_iterable(block["snarkJobs"] for block in blocks)
    for job in jobs:
        count.update({ job["prover"]: int(job["fee"])})
    return count

def blocks_produced(blocks):
    return Counter(block["creator"] for block in blocks)

def transactions_sent(blocks):
    user_commands = chain.from_iterable(block["transactions"]["userCommands"] for block in blocks)
    return Counter(command["from"] for command in user_commands)

def transactions_sent_echo(blocks):
    echo_public_key = "tdNDk6tKpzhVXUqozR5y2r77pppsEak7icvdYNsv2dbKx6r69AGUUbQsfrHHquZipQCmMj4VRhVF3u4F5NDgdbuxxWANULyVjUYPbe85fv7bpjKRgSpGR3zo2566s5GNNKQyLRUm12wt5o"
    user_commands = chain.from_iterable(block["transactions"]["userCommands"] for block in blocks)
    return Counter(command["from"] for command in user_commands if command["to"] == echo_public_key)

def transactions_received(blocks):
    user_commands = chain.from_iterable(block["transactions"]["userCommands"] for block in blocks)
    return Counter(command["to"] for command in user_commands)