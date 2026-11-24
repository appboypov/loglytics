import 'package:loglytics/loglytics.dart';
import 'package:test/test.dart';

/// A crash reports adapter that keeps what it gets, as a reporter would.
class _Reporter implements CrashReportsInterface {
  final breadcrumbs = <String>[];
  final errors = <(Object?, StackTrace?, bool)>[];

  @override
  Future<void> log(String message) async => breadcrumbs.add(message);

  @override
  Future<void> recordError(
    exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async =>
      errors.add((exception, stack, fatal));

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

  test('an error line holds its error and its stack trace', () {
    Loglytics.setUp();
    final failure = StateError('disk full');
    final stack = StackTrace.current;

    log.error('the write failed', error: failure, stackTrace: stack);

    expect(lines.single.level, LogLevel.error);
    expect(lines.single.error, same(failure));
    expect(lines.single.stackTrace.toString(), stack.toString());
    expect(lines.single.toString(), contains('disk full'));
  });

  test('the crash reports adapter gets the recorded error and the lines before it', () async {
    final reporter = _Reporter();
    Loglytics.setUp(crashReportsInterface: reporter);
    final failure = StateError('disk full');
    final stack = StackTrace.current;

    log.info('read 3 files');
    log.fatal('the write failed', error: failure, stackTrace: stack);
    await Future<void>.delayed(Duration.zero);

    expect(reporter.errors, [(failure, stack, true)]);
    expect(reporter.breadcrumbs.first, contains('read 3 files'));
  });
}
