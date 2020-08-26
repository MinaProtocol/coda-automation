from datetime import datetime, timedelta
import json
import os
import time

from python_graphql_client import GraphqlClient
from prometheus_client import Counter, Gauge, start_http_server


API_URL = os.getenv("BUILDKITE_API_URL", "https://graphql.buildkite.com/v1")
API_KEY = os.getenv("BUILDKITE_API_KEY")

PIPELINE_SLUG = os.getenv("BUILDKITE_PIPELINE_SLUG", "o-1-labs-2/coda").strip()
BRANCH = os.getenv("BUILDKITE_BRANCH", "*")

_monitored_jobs = [
    "_prepare-monorepo",
    "_monorepo-triage-cmds",
    "_OCaml-check",
    "_Rust-lint-trace-tool",
    "_Fast-lint",
    "_Fast-lint-optional-types",
    "_Fast-lint-optional-binable",
    "_TraceTool-build-trace-tool",
    "_CompareSignatures-compare-test-signatures",
    "_ValidationService-test",
    "_CheckDhall-check",
    "_Artifact-libp2p-helper",
    "_Artifact-artifacts-build",
    "_Artifact-docker-artifact",
    "_UnitTest-unit-test-dev",
    "_UnitTest-unit-test-nonconsensus_medium_curves",
    "_ArchiveNode-build-client-sdk",
    "_ClientSdk-install-yarn-deps,",
    "_ClientSdk-client-sdk-build-unittests,",
    "_ClientSdk-prepublish-client-sdk"
]
JOBS = os.getenv("BUILDKITE_JOBS", ','.join(_monitored_jobs))
MAX_JOB_COUNT = os.getenv("BUILDKITE_MAX_JOB_COUNT", 100)

EXPORTER_SCAN_INTERVAL = os.getenv("BUILDKITE_EXPORTER_SCAN_INTERVAL", 3600)
POLL_INTERVAL = os.getenv("BUILDKITE_POLL_INTERVAL", 60)

AGENT_METRICS_PORT = os.getenv("AGENT_METRICS_PORT", 8000)

## Prometheus Metrics

JOB_RUNTIME = Gauge('job_runtime', 'Total job runtime.', ['branch', 'exitStatus', 'state', 'passed', 'job'])
JOB_STATUS = Counter('job_status', 'Count of in-progress job statuses', ['branch', 'state', 'job'])
JOB_EXIT_STATUS = Counter('job_exit_status', 'Count of job exit statuses', ['branch', 'exitStatus', 'state', 'passed', 'job'])

class Exporter(object):
    """Represents a (Coda) Buildkite pipeline exporter"""

    def __init__(self, api_key=API_KEY, pipeline_slug=PIPELINE_SLUG, branch=BRANCH, interval=EXPORTER_SCAN_INTERVAL):
        self.api_key = api_key
        self.pipeline_slug = pipeline_slug
        self.branch = branch
        self.interval = interval

    def collect_job_data(self):
        headers = {
            'Authorization': 'Bearer {api_key}'.format(api_key=API_KEY),
            'Content-Type': 'application/json'
            }
        scan_from = datetime.now() - timedelta(seconds=EXPORTER_SCAN_INTERVAL)

        client = GraphqlClient(endpoint=API_URL, headers=headers)
        for j in JOBS.split(','):
            query = '''
                query {
                    pipeline(slug: "%s") {
                        builds(createdAtFrom: "%s", branch: "%s") {
                        edges {
                            node {
                            id
                            branch
                            commit
                            state
                            startedAt
                            finishedAt
                            message
                            jobs(first: %s, , step: { key: "%s" }) {
                                edges {
                                    node {
                                    __typename
                                    ... on JobTypeCommand {
                                        label
                                        step {
                                            key
                                        }
                                        command
                                        exitStatus
                                        startedAt
                                        finishedAt
                                        passed
                                        state
                                        artifacts(first: 5) {
                                            edges {
                                                node {
                                                    path
                                                    downloadURL
                                                    size
                                                    state
                                                    mimeType
                                                    sha1sum
                                                }
                                            }
                                        }
                                    }
                                    }
                                }
                                }
                            }
                        }
                        }
                    }
                }
            ''' % (
                    PIPELINE_SLUG,
                    scan_from.isoformat(),
                    BRANCH,
                    MAX_JOB_COUNT,
                    j
                )

            data = client.execute(query=query, variables={})
            # print(json.dumps(data))

            for d in data['data']['pipeline']['builds']['edges']:
                if len(d['node']['jobs']['edges']) > 0:
                    # Completed job metrics
                    if d['node']['jobs']['edges'][0]['node']['state'] == 'FINISHED':
                        end_time = datetime.strptime(d['node']['jobs']['edges'][0]['node']['finishedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')
                        start_time = datetime.strptime(d['node']['jobs']['edges'][0]['node']['startedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')

                        JOB_RUNTIME.labels(
                            branch=d['node']['branch'],
                            exitStatus=d['node']['jobs']['edges'][0]['node']['exitStatus'],
                            state=d['node']['jobs']['edges'][0]['node']['state'],
                            passed=d['node']['jobs']['edges'][0]['node']['passed'],
                            job=j
                        ).set((end_time - start_time).seconds)

                        JOB_EXIT_STATUS.labels(
                            branch=d['node']['branch'],
                            exitStatus=d['node']['jobs']['edges'][0]['node']['exitStatus'],
                            state=d['node']['jobs']['edges'][0]['node']['state'],
                            passed=d['node']['jobs']['edges'][0]['node']['passed'],
                            job=j
                        ).inc()
                    # In-progress Job metrics
                    else:
                        JOB_STATUS.labels(
                            branch=d['node']['branch'],
                            state=d['node']['jobs']['edges'][0]['node']['state'],
                            job=j
                        ).inc()

def main():
    exporter = Exporter()
    while True:
        exporter.collect_job_data()
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    start_http_server(AGENT_METRICS_PORT)
    main()
