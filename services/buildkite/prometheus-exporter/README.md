<p><img src="https://cdn.worldvectorlogo.com/logos/prometheus.svg" alt="Prometheus logo" title="prometheus" align="left" height="60" /></p>
<p><img src="https://buildkite.com/docs/assets/integrations/github_enterprise/buildkite-square-58030b96d33965fef1e4ea8c6d954f6422a2489e25b6b670b521421fcaa92088.png" alt="buildkite logo" title="buildkite" align="right" height="100" /></p>

# Buildkite :cloud: Exporter

A prometheus exporter providing metrics for Buildkite pipeline job and agent statistics via Buildkite's GraphQL API to a Prometheus compatible endpoint.

## Environment Variables

The application can be run in a number of ways though the main launching point is the Docker hub image `codaprotocol/buildkite-exporter`.

**Required**
* `BUILDKITE_API_KEY`                   - Buildkite GraphQL API access key

**Optional**

* `BUILDKITE_ORG_SLUG`                  - organization's Buildkite SLUG identifier
* `BUILDKITE_PIPELINE_SLUG`             - SLUG identifier of pipeline to query
* `BUILDKITE_BRANCH`                    - Pipeline branch to filter query

* `BUILDKITE_JOBS`                      - comma-separated list of jobs to filter job queries
* `BUILDKITE_MAX_JOB_COUNT`             - maximum amount of jobs to consider while processing job queries
* `BUILDKITE_EXPORTER_SCAN_INTERVAL`    - length of time to scan during job/build metrics processing and export

* `BUILDKITE_POLL_INTERVAL`             - frequency of metrics polling and export

* `MAX_AGENT_COUNT`                     - maximum amount of agents to consider while processing job queries

* `BUILDKITE_API_URL`                   - GraphQL API URL to issue queries

## Install and deploy

Build manually:
```
make build
```

Run from Docker Hub:
```
docker run -d -e BUILDKITE_API_KEY="XXXXXXXX" -p 8000:8000 codaprotocol/buildkite-exporter:<tag>
```

Scrape Builkite pipeline job and agent metrics over last `1hr` every `30 seconds`:
```
docker run --rm --detach --env BUILDKITE_API_KEY="XXXXXXXX" \
           --env BUILDKITE_EXPORTER_SCAN_INTERVAL=3600 \
           --env POLL_INTERVAL=30 \
           --publish 8000:8000 \
           codaprotocal/buildkite-exporter:<tag>
```

## Metrics

Metrics will be made available on port `8000` by default, or you can pass environment variable ```METRICS_PORT``` to override this. An example printout of the metrics you should expect to see can be found in [METRICS.md](https://github.com/CodaProtocol/coda-automation/blob/master/services/buildkite/prometheus-exporter/METRICS.md).
