# HELP python_gc_objects_collected_total Objects collected during gc
# TYPE python_gc_objects_collected_total counter
python_gc_objects_collected_total{generation="0"} 277.0
python_gc_objects_collected_total{generation="1"} 308.0
python_gc_objects_collected_total{generation="2"} 0.0
# HELP python_gc_objects_uncollectable_total Uncollectable object found during GC
# TYPE python_gc_objects_uncollectable_total counter
python_gc_objects_uncollectable_total{generation="0"} 0.0
python_gc_objects_uncollectable_total{generation="1"} 0.0
python_gc_objects_uncollectable_total{generation="2"} 0.0
# HELP python_gc_collections_total Number of times this generation was collected
# TYPE python_gc_collections_total counter
python_gc_collections_total{generation="0"} 76.0
python_gc_collections_total{generation="1"} 6.0
python_gc_collections_total{generation="2"} 0.0
# HELP python_info Python platform information
# TYPE python_info gauge
python_info{implementation="CPython",major="3",minor="8",patchlevel="2",version="3.8.2"} 1.0
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
process_virtual_memory_bytes 4.103168e+08
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes 3.1997952e+07
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1.59841056792e+09
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 2.33
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
process_open_fds 8.0
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
process_max_fds 1024.0
# HELP job_runtime Total job runtime
# TYPE job_runtime gauge
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 7.0
job_runtime{branch="develop",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 5.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 5.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 6.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 15.0
job_runtime{branch="develop",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 16.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 13.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 14.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 191.0
job_runtime{branch="develop",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 189.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 403.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 319.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 36.0
job_runtime{branch="develop",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 7.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 16.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 6.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 38.0
job_runtime{branch="develop",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 4.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 3.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 7.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 303.0
job_runtime{branch="develop",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 340.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 186.0
job_runtime{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-types",passed="False",state="FINISHED"} 525.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 234.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 227.0
job_runtime{branch="develop",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 372.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 322.0
job_runtime{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-binable",passed="False",state="FINISHED"} 526.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 196.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 43.0
job_runtime{branch="develop",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 112.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 12.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 20.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 365.0
job_runtime{branch="develop",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 336.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 488.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 352.0
job_runtime{branch="preprocess-curl-operations",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 640.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 370.0
job_runtime{branch="develop",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 71.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 96.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 8.0
job_runtime{branch="develop",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 22.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 61.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 8.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 22.0
job_runtime{branch="develop",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 141.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 157.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 22.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 894.0
job_runtime{branch="develop",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 932.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 1026.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 856.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 1034.0
job_runtime{branch="develop",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 1291.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 113.0
job_runtime{branch="rosetta/submit",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 953.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 1099.0
job_runtime{branch="develop",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 84.0
job_runtime{branch="develop",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1829.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1862.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1752.0
job_runtime{branch="develop",exitStatus="1",job="_UnitTest-unit-test-dev",passed="False",state="FINISHED"} 1820.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1945.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 617.0
job_runtime{branch="develop",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 431.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 472.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 642.0
job_runtime{branch="preprocess-curl-operations",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 437.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 623.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1060.0
job_runtime{branch="develop",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1105.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 843.0
job_runtime{branch="preprocess-curl-operations",exitStatus="100",job="_ArchiveNode-build-client-sdk",passed="False",state="FINISHED"} 212.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1112.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 16.0
job_runtime{branch="develop",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 12.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 12.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 12.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 389.0
job_runtime{branch="develop",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 354.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 668.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-client-sdk-build-unittests",passed="False",state="FINISHED"} 221.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 341.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 206.0
job_runtime{branch="develop",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 212.0
job_runtime{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 353.0
job_runtime{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-prepublish-client-sdk",passed="False",state="FINISHED"} 217.0
job_runtime{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 343.0
# HELP job_status_total Count of in-progress job statuses over <scan-interval>
# TYPE job_status_total counter
job_status_total{branch="rosetta/fix-hacky-encoding",job="_UnitTest-unit-test-dev",state="RUNNING"} 3.0
# HELP job_status_created Count of in-progress job statuses over <scan-interval>
# TYPE job_status_created gauge
job_status_created{branch="rosetta/fix-hacky-encoding",job="_UnitTest-unit-test-dev",state="RUNNING"} 1.5984105756404333e+09
# HELP job_exit_status_total Count of job exit statuses over <scan-interval>
# TYPE job_exit_status_total counter
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-types",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-binable",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="develop",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 6.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="develop",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 9.0
job_exit_status_total{branch="develop",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 12.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="develop",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="develop",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 9.0
job_exit_status_total{branch="develop",exitStatus="1",job="_UnitTest-unit-test-dev",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="develop",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 6.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="100",job="_ArchiveNode-build-client-sdk",passed="False",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 12.0
job_exit_status_total{branch="develop",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="develop",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-client-sdk-build-unittests",passed="False",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 6.0
job_exit_status_total{branch="develop",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 15.0
job_exit_status_total{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 3.0
job_exit_status_total{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-prepublish-client-sdk",passed="False",state="FINISHED"} 6.0
job_exit_status_total{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 3.0
# HELP job_exit_status_created Count of job exit statuses over <scan-interval>
# TYPE job_exit_status_created gauge
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 1.5984105692591026e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 1.5984105692592487e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 1.5984105692594554e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_prepare-monorepo",passed="True",state="FINISHED"} 1.5984105692601156e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 1.5984105699842644e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 1.598410569984446e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 1.5984105699850361e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_monorepo-triage-cmds",passed="True",state="FINISHED"} 1.5984105699857807e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 1.5984105703089423e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 1.5984105703090394e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 1.5984105703091805e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_OCaml-check",passed="True",state="FINISHED"} 1.5984105703095176e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 1.5984105706995122e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 1.598410570699622e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 1.598410570699781e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Rust-lint-trace-tool",passed="True",state="FINISHED"} 1.5984105707002685e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 1.59841057101755e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 1.59841057101812e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 1.5984105710183618e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Fast-lint",passed="True",state="FINISHED"} 1.5984105710190248e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 1.5984105713883576e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 1.5984105713885179e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 1.5984105713887572e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-types",passed="False",state="FINISHED"} 1.5984105713892415e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-types",passed="True",state="FINISHED"} 1.5984105713893743e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 1.5984105717295356e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 1.5984105717296717e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 1.5984105717299104e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="1",job="_Fast-lint-optional-binable",passed="False",state="FINISHED"} 1.598410571730406e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Fast-lint-optional-binable",passed="True",state="FINISHED"} 1.598410571730527e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 1.5984105723836253e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 1.5984105723838224e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 1.5984105723840683e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_TraceTool-build-trace-tool",passed="True",state="FINISHED"} 1.598410572384777e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 1.5984105728664076e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 1.5984105728665066e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 1.5984105728666465e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 1.5984105728668451e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="2",job="_CompareSignatures-compare-test-signatures",passed="False",state="FINISHED"} 1.5984105728669844e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_CompareSignatures-compare-test-signatures",passed="True",state="FINISHED"} 1.5984105728671107e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 1.5984105732248597e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_ValidationService-test",passed="True",state="FINISHED"} 1.5984105732253006e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 1.5984105739039946e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 1.5984105739040968e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 1.5984105739042394e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_CheckDhall-check",passed="True",state="FINISHED"} 1.5984105739045908e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 1.598410574512065e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 1.598410574512167e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 1.5984105745123098e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Artifact-libp2p-helper",passed="True",state="FINISHED"} 1.5984105745126536e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 1.5984105748795207e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 1.5984105748796198e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 1.5984105748797932e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_Artifact-artifacts-build",passed="True",state="FINISHED"} 1.5984105748802366e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 1.5984105752589808e+09
job_exit_status_created{branch="develop",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 1.5984105752590785e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 1.598410575259219e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="1",job="_Artifact-docker-artifact",passed="False",state="FINISHED"} 1.5984105752595592e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 1.5984105752596397e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_Artifact-docker-artifact",passed="True",state="FINISHED"} 1.5984105752597623e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1.5984105756406598e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1.5984105756408443e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1.5984105756409802e+09
job_exit_status_created{branch="develop",exitStatus="1",job="_UnitTest-unit-test-dev",passed="False",state="FINISHED"} 1.598410575641116e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-dev",passed="True",state="FINISHED"} 1.598410575641249e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 1.5984105759636147e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 1.5984105759637287e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 1.598410575963874e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 1.598410575964063e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="1",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="False",state="FINISHED"} 1.5984105759641948e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_UnitTest-unit-test-nonconsensus_medium_curves",passed="True",state="FINISHED"} 1.5984105759642754e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1.5984105763284817e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1.5984105763285868e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1.598410576328748e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="100",job="_ArchiveNode-build-client-sdk",passed="False",state="FINISHED"} 1.5984105763290665e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_ArchiveNode-build-client-sdk",passed="True",state="FINISHED"} 1.598410576329155e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 1.5984105766474302e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 1.5984105766475315e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 1.5984105766476758e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-install-yarn-deps",passed="True",state="FINISHED"} 1.5984105766480224e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 1.598410577368996e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 1.5984105773691442e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 1.5984105773693535e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-client-sdk-build-unittests",passed="False",state="FINISHED"} 1.5984105773697262e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-client-sdk-build-unittests",passed="True",state="FINISHED"} 1.5984105773699665e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 1.5984105782198822e+09
job_exit_status_created{branch="develop",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 1.5984105782200286e+09
job_exit_status_created{branch="preprocess-curl-operations",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 1.5984105782202435e+09
job_exit_status_created{branch="rosetta/fix-hacky-encoding",exitStatus="2",job="_ClientSdk-prepublish-client-sdk",passed="False",state="FINISHED"} 1.5984105782205372e+09
job_exit_status_created{branch="rosetta/submit",exitStatus="0",job="_ClientSdk-prepublish-client-sdk",passed="True",state="FINISHED"} 1.5984105782207687e+09
# HELP agents_total Count of active Buildkite agents within <org>
# TYPE agents_total counter
agents_total{connectionState="connected",isRunning="False",metadata="size=large",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 48.0
agents_total{connectionState="connected",isRunning="False",metadata="size=medium",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 24.0
agents_total{connectionState="connected",isRunning="False",metadata="size=small",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 40.0
agents_total{connectionState="connected",isRunning="False",metadata="size=xlarge",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 10.0
agents_total{connectionState="connected",isRunning="True",metadata="size=xlarge",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 2.0
# HELP agents_created Count of active Buildkite agents within <org>
# TYPE agents_created gauge
agents_created{connectionState="connected",isRunning="False",metadata="size=large",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 1.5984105786952362e+09
agents_created{connectionState="connected",isRunning="False",metadata="size=medium",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 1.598410578695476e+09
agents_created{connectionState="connected",isRunning="False",metadata="size=small",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 1.5984105786955934e+09
agents_created{connectionState="connected",isRunning="False",metadata="size=xlarge",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 1.5984105786957908e+09
agents_created{connectionState="connected",isRunning="True",metadata="size=xlarge",os="Ubuntu 18.04.4",version="3.22.1",versionHasKnownIssues="False"} 1.598410578696301e+09
