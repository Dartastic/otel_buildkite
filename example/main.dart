// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_buildkite/otel_buildkite.dart';

/// Traces Buildkite calls with OpenTelemetry.
///
/// `otel_buildkite` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Buildkite call in
/// [tracedBuildkite]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'buildkite-example');

  // Wraps a Buildkite REST API call in a CLIENT span.
  final buildkiteId = await tracedBuildkite<String>(
    resource: 'Order',
    action: 'example',
    organization: 'example',
    pipelineSlug: 'example',
    buildNumber: 'example',
    jobId: 'job_8f3a2c',
    invoke: () async {
      // Make the Buildkite call here, then report what it returned.
      return 'buildkite_8f3a2c';
    },
  );
  OTelLog.info('tracedBuildkite returned $buildkiteId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBuildkiteInstrumentationAsync.
  await runWithoutBuildkiteInstrumentationAsync(
    () => tracedBuildkite<String>(
      resource: 'Order',
      action: 'example',
      organization: 'example',
      pipelineSlug: 'example',
      buildNumber: 'example',
      jobId: 'job_8f3a2c',
      invoke: () async {
        return 'buildkite_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
