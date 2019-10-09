## Testnet Points
A service that collects metrics from the testnet and associates them with a testnet user for points.

# Types of Metrics
A metric can be one of two types, a `Continuous Metric` or a `Slot Metric`. This essentially means that a `Collector` can be configured to report metrics continuously or instead only report metrics during one or more `slots` on a daily basis.

Slot Example: Only report transactions sent between 9am-10am PST and 9pm-10pm PST

- Continuous Metrics
  - Metrics that get reported continuously
- Slot Metrics
  - Metrics that only get reported during a slot of time with a `start_time` and `end_time`


## Available Collectors
- Number of Blocks Produced by Public Key
- Number of Transactions Sent to Echo Service by Public Key
- Number of Transactions Sent by Public Key
- Number of Accepted SNARK Works by Public Key
- TPS (Sum of Transactions per Slot / Seconds per Slot)

# Architecture
This service lays out a generic `Collector` class that can be used to rapidly build out new metrics. A `Collector` consists of a GraphQL Query, optional `transformation` code that can extract metrics from the query response, and an optional `slot_time` that is used to decide if metrics should be reported or not.

Adding new metrics is as easy as sub-classing `CodaTestnetPoints.collectors.BaseCollector`.