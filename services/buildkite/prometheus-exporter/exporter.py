from datetime import datetime, timedelta
import json
import os
import time

from python_graphql_client import GraphqlClient
from prometheus_client import start_http_server
from prometheus_client.core import CounterMetricFamily, GaugeMetricFamily, REGISTRY


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

MAX_ARTIFACTS_COUNT = os.getenv("BUILDKITE_MAX_ARTIFACT_COUNT", 500)

EXPORTER_SCAN_INTERVAL = os.getenv("BUILDKITE_EXPORTER_SCAN_INTERVAL", 3600)

AGENT_METRICS_PORT = os.getenv("AGENT_METRICS_PORT", 8000)


class Exporter(object):
    """Represents a (Coda) Buildkite pipeline exporter"""

    def __init__(self, client, api_key=API_KEY, org_slug=ORG_SLUG, pipeline_slug=PIPELINE_SLUG, branch=BRANCH, interval=EXPORTER_SCAN_INTERVAL):
        self.api_key = api_key
        self.org_slug = org_slug
        self.pipeline_slug = pipeline_slug
        self.branch = branch
        self.interval = interval

        self.ql_client = client

    def collect(self):
        print("Collecting...")

        # The metrics we want to export.
        metrics = {}
        metrics['job'] = {
            'runtime':
                GaugeMetricFamily('job_runtime', 'Total job runtime',
                labels=['branch', 'exitStatus', 'state', 'passed', 'job', 'agentName', 'agentRules']),
            'waittime':
                GaugeMetricFamily('job_waittime', 'Total time job waited to start (from time scheduled)',
                labels=['branch', 'exitStatus', 'state', 'passed', 'job', 'agentName', 'agentRules']),
            'status':
                CounterMetricFamily('job_status', 'Count of in-progress job statuses over <scan-interval>',
                labels=['branch', 'state', 'job']),
            'exit_status':
                CounterMetricFamily('job_exit_status', 'Count of job exit statuses over <scan-interval>',
                labels=['branch', 'exitStatus', 'softFailed', 'state', 'passed', 'job', 'agentName', 'agentRules']),
            'artifact_size':
                GaugeMetricFamily('job_artifact_size', 'Total size of uploaded artifact (bytes)',
                labels=['branch', 'exitStatus', 'state', 'path', 'downloadURL', 'mimeType', 'job', 'agentName', 'agentRules']),
        }
        metrics['agent'] = {
            'total_count':
                CounterMetricFamily('agent_total_count', 'Count of active Buildkite agents within <org>',
                labels=['version', 'versionHasKnownIssues','os', 'isRunning', 'metadata', 'connectionState'])
        }

        self.collect_job_data(metrics)
        self.collect_agent_data(metrics)

        for category in ['job', 'agent']:
            for m in metrics[category].values():
                yield m

        print("Metrics collected.")

    def collect_job_data(self, metrics):
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
                                        agent {
                                            hostname
                                        }
                                        agentQueryRules
                                        command
                                        exitStatus
                                        startedAt
                                        finishedAt
                                        runnableAt
                                        scheduledAt
                                        softFailed
                                        passed
                                        state
                                        artifacts(first: %s) {
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
                    job,
                    MAX_ARTIFACTS_COUNT
                )

            data = self.ql_client.execute(query=query, variables={})
            for d in data['data']['pipeline']['builds']['edges']:
                if len(d['node']['jobs']['edges']) > 0:
                    for j in d['node']['jobs']['edges']:
                        # Completed job metrics
                        if j['node']['state'] == 'FINISHED':
                            scheduled_time = datetime.strptime(j['node']['scheduledAt'], '%Y-%m-%dT%H:%M:%S.%fZ')
                            start_time = datetime.strptime(j['node']['startedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')
                            end_time = datetime.strptime(j['node']['finishedAt'], '%Y-%m-%dT%H:%M:%S.%fZ')

                            metrics['job']['runtime'].add_metric(
                                labels=[
                                    d['node']['branch'],
                                    j['node']['exitStatus'],
                                    j['node']['state'],
                                    str(j['node']['passed']),
                                    job,
                                    j['node']['agent']['hostname'],
                                    ','.join(j['node']['agentQueryRules'])
                                ],
                                value=(end_time - start_time).seconds
                            )

                            metrics['job']['waittime'].add_metric(
                                labels=[
                                    d['node']['branch'],
                                    j['node']['exitStatus'],
                                    j['node']['state'],
                                    str(j['node']['passed']),
                                    job,
                                    j['node']['agent']['hostname'],
                                    ','.join(j['node']['agentQueryRules'])
                                ],
                                value=(start_time - scheduled_time).seconds
                            )

                            metrics['job']['exit_status'].add_metric(
                                labels=[
                                    d['node']['branch'],
                                    j['node']['exitStatus'],
                                    str(j['node']['softFailed']),
                                    j['node']['state'],
                                    str(j['node']['passed']),
                                    job,
                                    j['node']['agent']['hostname'],
                                    ','.join(j['node']['agentQueryRules'])
                                ],
                                value=1
                            )

                            if len(j['node']['artifacts']['edges']) > 0:
                                for a in j['node']['artifacts']['edges']:
                                    # Emit artifact upload size and metadata if applicable
                                    metrics['job']['artifact_size'].add_metric(
                                        labels=[
                                            d['node']['branch'],
                                            j['node']['exitStatus'],
                                            a['node']['state'],
                                            a['node']['path'],
                                            a['node']['downloadURL'],
                                            a['node']['mimeType'],
                                            job ,
                                            j['node']['agent']['hostname'],
                                            ','.join(j['node']['agentQueryRules'])
                                        ],
                                        value=a['node']['size']
                                    )
                        else:
                            # In-progress/incomplete Job metrics
                            metrics['job']['status'].add_metric(
                                labels=[
                                    d['node']['branch'],
                                    j['node']['state'],
                                    job
                                ],
                                value=1
                            )

    def collect_agent_data(self, metrics):
        query = '''
            query {
                organization(slug: "%s") {
                    agents(first: %s) {
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
            metrics['agent']['total_count'].add_metric(
                labels=[
                    d['node']['version'],
                    str(d['node']['versionHasKnownIssues']),
                    d['node']['operatingSystem']['name'],
                    str(d['node']['isRunningJob']),
                    ','.join(d['node']['metaData']),
                    d['node']['connectionState']
                ],
                value=1
            )

def main():
    headers = {
        'Authorization': 'Bearer {api_key}'.format(api_key=API_KEY),
        'Content-Type': 'application/json'
    }
    client = GraphqlClient(endpoint=API_URL, headers=headers)

    REGISTRY.register(Exporter(client))
    start_http_server(AGENT_METRICS_PORT)
    print("Metrics on Port {}".format(AGENT_METRICS_PORT))

    while True:
        time.sleep(5)


if __name__ == "__main__":
    print("Starting up...")
    main()
