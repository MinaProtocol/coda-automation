from CodaClient import Client
import os
import schedule
import time
import urllib3
import random
from requests.exceptions import ConnectionError
from prometheus_client import Counter, start_http_server

CODA_PUBLIC_KEY = os.getenv("CODA_PUBLIC_KEY", "4vsRCVyVkSRs89neWnKPrnz4FRPmXXrWtbsAQ31hUTSi41EkbptYaLkzmxezQEGCgZnjqY2pQ6mdeCytu7LrYMGx9NiUNNJh8XfJYbzprhhJmm1ZjVbW9ZLRvhWBXRqes6znuF7fWbECrCpQ").strip()
CODA_PRIVKEY_PASS = os.getenv("CODA_PRIVKEY_PASS", "naughty blue worm")
AGENT_MAX_FEE = os.getenv("AGENT_MAX_FEE", random.randint(2, 20))
AGENT_MAX_TX = os.getenv("AGENT_MAX_TX", random.randint(2,100))
AGENT_SEND_EVERY_MINS = os.getenv("AGENT_SEND_EVERY_MINS", random.randint(1, 5))
AGENT_METRICS_PORT = os.getenv("AGENT_METRICS_PORT", 8000)


CODA_CLIENT_ARGS = {
    "graphql_host":  os.getenv("CODA_HOST", "localhost"),
    "graphql_port": os.getenv("CODA_PORT", "3085")
} 


## Prometheus Metrics

TRANSACTIONS_SENT = Counter('transactions_sent', 'Number of transactions agent has sent since boot.')
TRANSACTION_ERRORS = Counter('transaction_errors', 'Number of errors that occurred while sending transactions.')

class Agent(object):
    """Represents a generic agent that operates on the coda blockchain"""

    def __init__(self, client_args, public_key, privkey_pass, max_tx_amount=AGENT_MAX_TX, max_fee_amount=AGENT_MAX_FEE):
        self.coda = Client(**client_args)
        self.public_key = public_key
        self.privkey_pass = privkey_pass
        self.max_fee_amount = max_fee_amount
        self.max_tx_amount = max_tx_amount
        self.to_account = None

    def get_to_account(self):
        if not self.to_account:
            print("Getting new wallet to send to...")
            response = self.coda.create_wallet(self.privkey_pass)
            self.to_account = response["createAccount"]["publicKey"]
            print("Public Key: {}".format(self.to_account))
        return self.to_account

    def unlock_wallet(self):
        response = self.coda.unlock_wallet(self.public_key, self.privkey_pass)
        print("Unlocked Wallet!")
        return response

    def send_transaction(self):
        print("---Sending Transaction---")
        try: 
            to_account = self.get_to_account()
            print("Trying to unlock Wallet!")
            self.unlock_wallet()
        except ConnectionError:
            print("Transaction Failed due to connection error... is the Daemon running?")
            TRANSACTION_ERRORS.inc()
            return None
        except Exception as e: 
            print("Error unlocking wallet...")
            print(e)
            return None
        
        tx_amount = random.randint(2, self.max_tx_amount) * 1000000000
        fee_amount = random.randint(2, self.max_fee_amount) * 1000000000
        try: 
            response = self.coda.send_payment(to_account, self.public_key, tx_amount, fee_amount, memo="BeepBoop")
        except Exception as e: 
            print("Error sending transaction...", e)
            TRANSACTION_ERRORS.inc()
            return None
        if not response.get("errors", None):
            print("Sent a Transaction {}".format(response))
            TRANSACTIONS_SENT.inc()
        else: 
            print("Error sending transaction: Request: {} Response: {}".format(self.public_key, response))
            TRANSACTION_ERRORS.inc()
        return response

def main():
    agent = Agent(CODA_CLIENT_ARGS, CODA_PUBLIC_KEY, CODA_PRIVKEY_PASS)
    schedule.every(AGENT_SEND_EVERY_MINS).minutes.do(agent.send_transaction)
    print("Sending a transaction every {} minutes.".format(AGENT_SEND_EVERY_MINS))
    while True:
        schedule.run_pending()
        sleep_time = 10
        print("Sleeping for {} seconds...".format(sleep_time))
        time.sleep(sleep_time)

if __name__ == "__main__":
    print("Starting up...")
    start_http_server(AGENT_METRICS_PORT)
    print("Metrics on Port {}".format(AGENT_METRICS_PORT))
    print("Sleeping for 20 minutes...")
    time.sleep(60*20)
    main()
