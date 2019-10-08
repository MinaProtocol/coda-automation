from TestnetPoints.collectors.transactions import TransactionsSentGlobalCollector
from CodaClient import Client

if __name__ == "__main__":
    collect = TransactionsSentGlobalCollector(coda_client=Client(graphql_port=8080))
    print(collect.collect())