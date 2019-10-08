import abc
from CodaClient import Client
import logging

class BaseCollector(metaclass=abc.ABCMeta):
    def __init__(self, slot_times=None, coda_client=Client(graphql_host="localhost", graphql_port=3085)):
        """An Abstract Base Class representing a Coda Metric Collector"""
        self.slot_times = slot_times
        self.coda_client = coda_client
        self.logger = logging.getLogger(__name__)

    @abc.abstractmethod
    def query(self):
        """Executes a query against the GraphQL Endpoint and Returns a Response"""
        pass

    @abc.abstractmethod
    def transform(self, response):
        """Executes the transformation against a GraphQL Response and returns the result"""
        pass

    def collect(self):
        """Sends the GraphQL Request, Transforms the Response, and Returns the Metrics"""
        # Make the Query
        response = self.query()
        # Transform the Response
        metrics = self.transform(response)
        # Return formatted metrics
        return metrics
