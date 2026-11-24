import 'dart:async';

import 'package:loglytics/loglytics.dart';
import 'package:test/test.dart';

/// A crash reports adapter that keeps what it gets in order, as a reporter would.
class _Reporter implements CrashReportsInterface {
  _Reporter({this.fails = false});

  /// Whether each call fails, as a reporter that cannot be reached does.
  final bool fails;

  /// The breadcrumbs as text and the recorded errors as `(error, stack, fatal)`, in order.
  final events = <Object?>[];

  @override
  Future<void> log(String message) async {
    if (fails) throw StateError('unreachable');
    events.add(message);
  }

  @override
  Future<void> recordError(
    exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    if (fails) throw StateError('unreachable');
    events.add((exception, stack, fatal));
  }

  @override
  Future<void> setCustomKey(String key, String? value) async {}

  @override
  Future<void> setUserIdentifier(String identifier) async {}
}

void main() {
  late List<LogLine> lines;
  late Log log;

  setUp(() {
    lines = [];
    Log.output = lines.add;
    log = Log(location: 'Sync');
  });

  tearDown(() async {
    Log.output = Log.printLine;
    await Loglytics.disposeMe();
  });

  test('the output gets each line at or above the level and none below it', () {
    Loglytics.setUp(logLevel: LogLevel.warning);

    log.debug('read 3 files');
    log.info('read 3 files');
    log.warning('a file could not be read');
    log.error('the read failed');

    expect(
      lines.map((line) => (line.level, line.location)),
      [(LogLevel.warning, 'Sync'), (LogLevel.error, 'Sync')],
    );
  });

  test('an error line holds its error and its whole stack trace, and its text shows both', () {
    Loglytics.setUp(maxLinesStackTrace: 1);
    final failure = StateError('disk full');
    final stack = StackTrace.current;

    log.error('the write failed', error: failure, stackTrace: stack);
    final printed = <String>[];
    runZoned(
      () => Log.printLine(lines.single),
      zoneSpecification: ZoneSpecification(print: (_, __, ___, text) => printed.add(text)),
    );

    expect(lines.single.error, same(failure));
    expect(lines.single.stackTrace, same(stack));
    expect(
      printed.single,
      allOf(contains('$failure'), contains('$stack'.split('\n').first)),
    );
  });

  test('the crash report gets the lines before it and then the recorded error', () async {
    final reporter = _Reporter();
    Loglytics.setUp(crashReportsInterface: reporter);
    final failure = StateError('disk full');
    final stack = StackTrace.current;

    log.info('read 3 files');
    log.fatal('the write failed', error: failure, stackTrace: stack);
    await Future<void>.delayed(Duration.zero);

    expect(reporter.events, [
      contains('read 3 files'),
      contains('the write failed'),
      (failure, stack, true),
    ]);
  });

  test('a reporter that fails stops neither the log nor the process', () async {
    final uncaught = <Object>[];

    await runZonedGuarded(() async {
      Loglytics.setUp(crashReportsInterface: _Reporter(fails: true));
      log.info('read 3 files');
      log.error('the write failed', error: StateError('disk full'));
      await Future<void>.delayed(Duration.zero);
    }, (error, _) => uncaught.add(error));

    expect(uncaught, isEmpty);
    expect(lines.map((line) => line.level), [LogLevel.info, LogLevel.error]);
  });
}
