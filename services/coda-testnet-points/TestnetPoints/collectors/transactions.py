from TestnetPoints.collectors.base import BaseCollector

class TransactionsSentGlobalCollector(BaseCollector):
    def query(self):
        graphql_query = '''
        {
            blocks {
                nodes {
                    creator
                    transactions {
                        userCommands {
                            from
                            to
                        }
                    }
                }
            }
        }
        '''
        blocks = self.coda_client._send_query(graphql_query)
        return blocks["data"]

    def transform(self, response):
        # Count the Number of Blocks created by Public Key
        metrics = {}
        nodes = response["blocks"]["nodes"]
        for block in nodes:
            for transaction in block["transactions"]["userCommands"]:
                sender = transaction["from"]
                if sender not in metrics:
                    metrics[sender] = 1
                else:
                    metrics[sender] += 1
        return metrics

class TransactionsSentEchoCollector(BaseCollector):
    def query(self):
        graphql_query = '''
        {
            blocks {
                nodes {
                    creator
                    transactions {
                        userCommands {
                            from
                            to
                        }
                    }
                    protocolState {
                        blockchainState {
                            date
                        }
                    }
                }
            }
        }
        '''
        blocks = self.coda_client._send_query(graphql_query)
        return blocks["data"]

    def transform(self, response):
        # Iterate over each block
        # Compare timestamp of block with the time slot(s)
            # if it fits the slot, record it
        pass
