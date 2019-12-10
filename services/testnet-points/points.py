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
from LeaderboardUpload import upload, sheets
from LeaderboardUpload.metrics import latest, no_update, max_metric, add
import requests
import sys

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


def load_blocks_gareth():
    response = requests.get(
        "https://codaexplorer.garethtdavies.com/api/blocks?limit=8000").json()
    return response["blocks"]["nodes"]


def create_points_report(window_times=[],
                         windowed_metrics={},
                         global_metrics={},
                         pk_mapping={}):
    logger = logging.Logger(__name__)

    blocks = load_blocks_gareth()
    logger.debug(f"Loaded {len(blocks)} Blocks")

    windows = []
    for i, window_time in enumerate(window_times):
        window = [
            block for block in blocks
            if in_range(block["dateTime"], [window_time])
        ]
        windowed_metrics_modified = dict(
            map(lambda key: (key + str(i + 1), windowed_metrics[key]),
                windowed_metrics.keys()))
        windows.append((window, windowed_metrics_modified))
        logger.debug(f"Filtered out {len(window)} Windowed Blocks")

    global_metrics = collect_metrics(blocks, global_metrics)

    windowed_metrics = [
        collect_metrics(window, metrics) for (window, metrics) in windows
    ]

    metrics = [global_metrics] + windowed_metrics
    print(metrics)
    public_keys = set(
        chain.from_iterable([metric.keys() for metric in metrics]))
    logger.debug(f"Observed {len(public_keys)} Public Keys")

    report = defaultdict(dict)
    for public_key in public_keys:
        for metric in metrics:
            report[public_key].update(metric.get(public_key, {}))

    for public_key, user in pk_mapping.items():
        if public_key in report:
            report[user] = report[public_key]
            del (report[public_key])
        else:
            logger.debug(f"Did not find user={user} public_key={public_key}")

    return report


def collect_metrics(blocks, metrics_dict):
    computed_metrics = {
        metric_name: metric(blocks)
        for metric_name, metric in metrics_dict.items()
    }

    public_keys = set(
        chain.from_iterable(metric.keys()
                            for metric in computed_metrics.values()))

    return {
        public_key: {
            metric_name: computed_metrics[metric_name][public_key]
            for metric_name in metrics_dict.keys()
            if public_key in computed_metrics[metric_name]
        }
        for public_key in public_keys
    }


def main():
    logger = logging.Logger(__name__)
    logger.setLevel(logging.DEBUG)

    timezone = pytz.timezone('America/Los_Angeles')
    window_times = [
        # (datetime.datetime(year=2019, month=10, day=8, hour=14, tzinfo=timezone), datetime.timedelta(hours=1)),
        # (datetime.datetime(year=2019, month=10, day=10, hour=17, tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019,
                           month=11,
                           day=14,
                           hour=21,
                           tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019,
                           month=11,
                           day=16,
                           hour=9,
                           tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019,
                           month=11,
                           day=19,
                           hour=21,
                           tzinfo=timezone), datetime.timedelta(hours=1)),
        (datetime.datetime(year=2019,
                           month=11,
                           day=20,
                           hour=9,
                           tzinfo=timezone), datetime.timedelta(hours=1)),
    ]
    logger.debug(f"Using these windows: {window_times}")

    windowed_metrics = {
        "Blocks Produced - Window #": metrics.blocks_produced,
        "SNARK Fees Collected - Window #": metrics.snark_fees_collected,
        "Transactions Sent - Window #": metrics.transactions_sent,
        #"Transactions Received (Windowed)": metrics.transactions_received
    }
    logger.debug(
        f"Running with these windowed metrics: {windowed_metrics.keys()}")

    global_metrics = {
        "Blocks Produced (Global)": metrics.blocks_produced,
        #"SNARK Fees Collected (Global)": metrics.snark_fees_collected,
        #"Transactions Sent (Global)": metrics.transactions_sent,
        #"Transactions Received (Global)": metrics.transactions_received,
        #"Transactions Sent Echo (Global)": metrics.transactions_sent_echo
    }
    logger.debug(
        f"Running with these windowed metrics: {global_metrics.keys()}")

    with open('known_keys.json', 'r') as f:
        known_users = json.load(f)

    report = create_points_report(window_times, windowed_metrics,
                                  global_metrics, known_users)
    print(json.dumps(report, indent=2))

    SHEET_ID = '1CLX9DF7oFDWb1UiimQXgh_J6jO4fVLJEcEnPVAOfq24'

    combine_fns = {
        "Blocks Produced - Window #1": latest,
        "Blocks Produced - Window #2": latest,
        "Blocks Produced - Window #3": latest,
        "Blocks Produced - Window #4": latest,
        "Blocks Produced - Window #5": latest,
        "Blocks Produced - Window #6": latest,
        "SNARK Fees Collected - Window #1": latest,
        "SNARK Fees Collected - Window #2": latest,
        "SNARK Fees Collected - Window #3": latest,
        "SNARK Fees Collected - Window #4": latest,
        "SNARK Fees Collected - Window #5": latest,
        "Transactions Sent - Window #1": latest,
        "Transactions Sent - Window #2": latest,
        "Transactions Sent - Window #3": latest,
        "Transactions Sent - Window #4": latest,
        "Transactions Sent - Window #5": latest,
        "Blocks Produced (Global)": latest,
        "Transactions Sent Echo (Global)": latest
    }
    credentials = sheets.get_credentials()
    uploaded_metrics = upload.upload_metrics(credentials, SHEET_ID,
                                             "Metrics2.4-Windows", combine_fns,
                                             report)

    print(json.dumps(uploaded_metrics, indent=2))
    return uploaded_metrics


if __name__ == "__main__":
    main()
