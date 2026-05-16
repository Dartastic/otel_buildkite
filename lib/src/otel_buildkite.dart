// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_buildkite_suppression.dart';

const _tracerName = 'dartastic_otel_libs_buildkite';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Buildkite REST API call in a CLIENT span.
Future<T> tracedBuildkite<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? organization,
  String? pipelineSlug,
  String? buildNumber,
  String? jobId,
}) async {
  if (buildkiteInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cicd.system': 'buildkite',
    'buildkite.resource': resource,
    'buildkite.action': action,
    'buildkite.operation': '$resource.$action',
  };
  if (organization != null) m['buildkite.organization'] = organization;
  if (pipelineSlug != null) m['buildkite.pipeline.slug'] = pipelineSlug;
  if (buildNumber != null) m['buildkite.build.number'] = buildNumber;
  if (jobId != null) m['buildkite.job.id'] = jobId;

  final span = _tracer().startSpan(
    'buildkite $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
