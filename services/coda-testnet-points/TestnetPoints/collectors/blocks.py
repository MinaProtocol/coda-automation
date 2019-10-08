from TestnetPoints.collectors.base import BaseCollector

class BlocksProducedCollector(BaseCollector):
    def query(self):
        graphql_query = '''
        {
            blocks {
                nodes {
                    creator
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
            creator = block["creator"]
            if creator not in metrics:
                metrics[creator] = 1
            else:
                metrics[creator] += 1
        return metrics
