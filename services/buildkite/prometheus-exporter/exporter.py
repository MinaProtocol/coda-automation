from datetime import datetime, timedelta
import json
import os
import time

from python_graphql_client import GraphqlClient
from prometheus_client import Counter, Gauge, start_http_server


API_KEY = os.getenv("BUILDKITE_API_KEY")
API_URL = os.getenv("BUILDKITE_API_URL", "https://graphql.buildkite.com/v1")

ORG_SLUG = os.getenv("BUILDKITE_ORG_SLUG", "o-1-labs-2")
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
MAX_JOB_COUNT = os.getenv("BUILDKITE_MAX_JOB_COUNT", 500)

MAX_AGENT_COUNT = os.getenv("BUILDKITE_MAX_AGENT_COUNT", 500)

EXPORTER_SCAN_INTERVAL = os.getenv("BUILDKITE_EXPORTER_SCAN_INTERVAL", 3600)
POLL_INTERVAL = os.getenv("BUILDKITE_POLL_INTERVAL", 10)

AGENT_METRICS_PORT = os.getenv("AGENT_METRICS_PORT", 8000)

## Prometheus Metrics

# -- job metrics

JOB_RUNTIME = Gauge(
    'job_runtime', 'Total job runtime',
    ['branch', 'exitStatus', 'state', 'passed', 'job']
)
JOB_STATUS = Counter(
    'job_status', 'Count of in-progress job statuses over <scan-interval>',
    ['branch', 'state', 'job']
)
JOB_EXIT_STATUS = Counter(
    'job_exit_status', 'Count of job exit statuses over <scan-interval>',
    ['branch', 'exitStatus', 'state', 'passed', 'job']
)
JOB_ARTIFACT_SIZE = Gauge(
    'artifact_size', 'Total size of uploaded artifact (bytes)',
    ['branch', 'exitStatus', 'state', 'path', 'downloadURL', 'mimeType', 'job']
)

# -- agent metrics

TOTAL_AGENT_COUNT = Counter(
    'agents_total', 'Count of active Buildkite agents within <org>',
    ['version', 'versionHasKnownIssues','os', 'isRunning', 'metadata', 'connectionState']
)


class Exporter(object):
    """Represents a (Coda) Buildkite pipeline exporter"""

    def __init__(self, client, api_key=API_KEY, org_slug=ORG_SLUG, pipeline_slug=PIPELINE_SLUG, branch=BRANCH, interval=EXPORTER_SCAN_INTERVAL):
        self.api_key = api_key
        self.org_slug = org_slug
        self.pipeline_slug = pipeline_slug
        self.branch = branch
        self.interval = interval

        self.ql_client = client

    def collect_job_data(self):
        scan_from = datetime.now() - timedelta(seconds=self.interval)
        for job in JOBS.split(','):
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
                    self.pipeline_slug,
                    scan_from.isoformat(),
                    self.branch,
                    MAX_JOB_COUNT,
                    job
                )

            data = self.ql_client.execute(query=query, variables={})
            for d in data['data']['pipeline']['builds']['edges']:
                if len(d['node']['jobs']['edges']) > 0:
                    for j in d['node']['jobs']['edges']:
                        # Completed job metrics
                        if j['node']['state'] == 'FINISHED':
                            end_time = datetime.strptime(j['node']['finishedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')
                            start_time = datetime.strptime(j['node']['startedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')

                            JOB_RUNTIME.labels(
                                branch=d['node']['branch'],
                                exitStatus=j['node']['exitStatus'],
                                state=j['node']['state'],
                                passed=j['node']['passed'],
                                job=job
                            ).set((end_time - start_time).seconds)

                            JOB_EXIT_STATUS.labels(
                                branch=d['node']['branch'],
                                exitStatus=j['node']['exitStatus'],
                                state=j['node']['state'],
                                passed=j['node']['passed'],
                                job=job
                            ).inc()

                            # Emit artifact upload size and metadata if applicable
                            if len(j['node']['artifacts']['edges']) > 0:
                                for a in j['node']['artifacts']['edges']:
                                    JOB_ARTIFACT_SIZE.labels(
                                        branch=d['node']['branch'],
                                        exitStatus=j['node']['exitStatus'],
                                        state=a['node']['state'],
                                        path=a['node']['path'],
                                        downloadURL=a['node']['downloadURL'],
                                        mimeType=a['node']['mimeType'],
                                        job=job 
                                    ).set(a['node']['size'])

                        # In-progress/incomplete Job metrics
                        else:
                            JOB_STATUS.labels(
                                branch=d['node']['branch'],
                                state=d['node']['jobs']['edges'][0]['node']['state'],
                                job=job
                            ).inc()

    def collect_agent_data(self):
        query = '''
            query {
                organization(slug: "%s") {
                    agents(first:%s) {
                    edges {
                        node {
                        name
                        hostname
                        ipAddress
                        operatingSystem {
                        name
                        }
                        userAgent
                        version
                        versionHasKnownIssues
                        createdAt
                        connectedAt
                        connectionState
                        heartbeatAt
                        isRunningJob
                        pid
                        public
                        metaData
                        userAgent
                        }
                    }
                    }
                }
            }
        ''' % (
                self.org_slug,
                MAX_AGENT_COUNT,
            )

        data = self.ql_client.execute(query=query, variables={})
        for d in data['data']['organization']['agents']['edges']:
            TOTAL_AGENT_COUNT.labels(
                version=d['node']['version'],
                versionHasKnownIssues=d['node']['versionHasKnownIssues'],
                os=d['node']['operatingSystem']['name'],
                isRunning=d['node']['isRunningJob'],
                metadata=','.join(d['node']['metaData']),
                connectionState=d['node']['connectionState']
            ).inc()

def main():
    headers = {
        'Authorization': 'Bearer {api_key}'.format(api_key=API_KEY),
        'Content-Type': 'application/json'
    }

    client = GraphqlClient(endpoint=API_URL, headers=headers)
    exporter = Exporter(client)
    while True:
        print("Collecting...")
        exporter.collect_job_data()
        exporter.collect_agent_data()

        print("Sleeping for {pollInterval} seconds...".format(pollInterval=POLL_INTERVAL))
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    print("Starting up...")
    start_http_server(AGENT_METRICS_PORT)
    print("Metrics on Port {}".format(AGENT_METRICS_PORT))
    main()
