// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_buildkite/otel_buildkite.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_buildkite-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('builds.create records CLIENT span', () async {
    await tracedBuildkite<String>(
      resource: 'builds',
      action: 'create',
      organization: 'acme',
      pipelineSlug: 'app',
      buildNumber: '42',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('buildkite builds.create')!);
    expect(a['cicd.system'], 'buildkite');
    expect(a['buildkite.organization'], 'acme');
    expect(a['buildkite.pipeline.slug'], 'app');
    expect(a['buildkite.build.number'], '42');
  });

  test('suppression skips spans', () async {
    await runWithoutBuildkiteInstrumentationAsync(() async {
      await tracedBuildkite<String>(
        resource: 'r',
        action: 'a',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('buildkite '), isEmpty);
  });
}
