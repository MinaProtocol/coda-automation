from CodaClient import Client
import metrics
from helpers import in_range
import logging
import datetime
import pytz
import json
from collections import defaultdict, Counter
from itertools import chain
import functools


#  Note: new metrics should be in the following form:
#     {
#       "name1": {"metric1": 1, "metric2": 134, "metric3": 11}
#       "name2": {"metric1": 2, "metric3": 8}
#       "name3": {"metric2": 412}
#     }

def load_blocks():
    coda_client = Client()
    query = '''
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
                snarkJobs {
                    prover
                    fee
                    workIds
                }
            }
        }
    }
    '''
    response = coda_client._send_query(query)
    return response["data"]["blocks"]["nodes"]

def create_points_report(window_times=[], windowed_metrics={}, global_metrics={}, pk_mapping={}):
    blocks = load_blocks()

    windowed_blocks = [
        block for block in blocks if in_range(block["protocolState"]["blockchainState"]["date"], window_times)
    ]

    global_metrics = collect_metrics(blocks, global_metrics)
    windowed_metrics = collect_metrics(windowed_blocks, windowed_metrics)

    report = {}
    for public_key in global_metrics.keys():
        report[public_key] = functools.reduce(
            lambda res, metrics: res.update(metrics.get(public_key, {})) or res,
            [windowed_metrics, global_metrics],
            {}
        )

    for public_key in report.keys():
        if public_key in pk_mapping:
            report[pk_mapping[public_key]] = report[public_key]
            del(report[public_key])

    return report

def collect_metrics(blocks, metrics):
    computed_metrics = {
        metric_name: metric(blocks) for metric_name, metric in metrics.items()
    }

    public_keys = functools.reduce(
        lambda keys, metric_name: set(computed_metrics[metric_name].keys()) | keys,
        computed_metrics.keys(),
        set()
    )

    return { public_key: {
        metric_name: computed_metrics[metric_name][public_key]
        for metric_name in metrics.keys()
        if public_key in computed_metrics[metric_name]
    } for public_key in public_keys }

def main():
    timezone = pytz.timezone('America/Los_Angeles')
    window_times = [
        (datetime.datetime(year=2019, month=10, day=8, hour=14, tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019, month=10, day=10, hour=17, tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019, month=10, day=12, hour=9, tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019, month=10, day=15, hour=17, tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019, month=10, day=16, hour=9, tzinfo=timezone), datetime.timedelta(hours=1))
    ]

    windowed_metrics = {
        "Blocks Produced (Windowed)": metrics.blocks_produced,
        "SNARK Fees Collected (Windowed)": metrics.snark_fees_collected,
        "Transactions Sent (Windowed)": metrics.transactions_sent,
        "Transactions Received (Windowed)": metrics.transactions_received
    }
    global_metrics = {
        "Blocks Produced (Global)": metrics.blocks_produced,
        "SNARK Fees Collected (Global)": metrics.snark_fees_collected,
        "Transactions Sent (Global)": metrics.transactions_sent,
        "Transactions Received (Global)": metrics.transactions_received,
        "Transactions Sent Echo (Global)": metrics.transactions_sent_echo
    }

    with open('known_keys.json', 'r') as f:
        known_users = json.load(f)

    report = create_points_report(window_times, windowed_metrics, global_metrics, known_users)
    print(json.dumps(report, indent=2))
    return report

if __name__ == "__main__":
    main()

