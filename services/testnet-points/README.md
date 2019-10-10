## Testnet Points
A service that collects metrics from the testnet and associates them with a testnet user for points.

# Types of Metrics
A metric can be one of two types, a `Continuous Metric` or a `Windowed Metric`. Global Metrics are collected for all blocks. However, For certain challenges, we only care about metrics that are computed from blocks that were produced during a particular "window" of time, thus the win

Window Example: Only report transactions sent between 9am-10am PST and 9pm-10pm PST


## Available Metrics
- Number of Blocks Produced by Public Key
- Number of Transactions Sent to Echo Service by Public Key
- Number of Transactions Sent by Public Key
- Number of Transactions Received by Public Key
- SNARK Fees Collected by Public Key
