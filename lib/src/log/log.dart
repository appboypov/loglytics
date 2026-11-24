part of '../loglytics/loglytics.dart';

/// Pure logger class to facilitate logging.
class Log {
  Log({
    String? location,
    String? tag,
    int? maxLinesStackTrace,
  })  : _tag = tag,
        _location = location ?? 'Log',
        _maxLinesStackTrace = maxLinesStackTrace;

  /// Used to indicate the tag of the log, can also be specified per method.
  final String? _tag;

  /// Used to toggle logging of time on or off.
  static bool logTime = false;

  /// Used to set the log level of the [Loglytics].
  static LogLevel level = LogLevel.info;

  /// Used to indicate the current location of the log.
  final String _location;

  /// Used to determine the max lines of the stack trace.
  final int? _maxLinesStackTrace;

  /// Used to properly handle chronological processing of events.
  late final EventBus _eventBus = EventBus();

  /// Used to toggle broadcasting logs on or off.
  static bool broadcastLogs = false;

  /// Receives each [LogLine] that a [Log] writes. The process sets it once at its start, such as
  /// to write lines to a file. It is [printLine] when nothing is set.
  static void Function(LogLine line) output = printLine;

  /// Prints [line] as text to standard output, after its time when [logTime] is true.
  static void printLine(LogLine line) => print('${logTime ? '${timeOf(line.time)} ' : ''}$line');

  /// Used to expose all crash reports logs.
  static final StreamController<String> crashReportsObserver = StreamController.broadcast();

  /// Used to expose all analytics logs.
  static final StreamController<String> analyticsObserver = StreamController.broadcast();

  // --------------- REGULAR --------------- REGULAR --------------- REGULAR --------------- \\

  /// Logs a trace [message] with [LogLevel.trace] to [Log.output].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void trace(
    String message, {
    bool addToCrashReports = true,
    String? location,
    String? tag,
  }) {
    const logLevel = LogLevel.trace;
    if (level.skipLog(logLevel)) return;
    _logMessage(
      message: message,
      logLevel: logLevel,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
    );
  }

  /// Logs a debug [message] with [LogLevel.debug] to [Log.output].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void debug(
    String message, {
    bool addToCrashReports = true,
    String? location,
    String? tag,
  }) {
    if (level.skipLog(LogLevel.debug)) return;
    _logMessage(
      message: message,
      logLevel: LogLevel.debug,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
    );
  }

  /// Logs an info [message] with [LogLevel.info] to [Log.output].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void info(
    String message, {
    bool addToCrashReports = true,
    String? location,
    String? tag,
  }) {
    const logLevel = LogLevel.info;
    if (level.skipLog(logLevel)) return;
    _logMessage(
      message: message,
      logLevel: logLevel,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
    );
  }

  /// Logs an analytic [name] with [LogLevel.analytic] to [Log.output].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void analytic({
    required String name,
    String? value,
    bool addToCrashReports = true,
    String? location,
    Map<String, Object?>? parameters,
    String? tag,
  }) {
    const logLevel = LogLevel.analytic;
    if (level.skipLog(logLevel)) return;
    var message = '$name${value != null ? ': $value' : ''}'
        '${parameters != null ? ': $parameters' : ''}';
    _logMessage(
      message: message,
      logLevel: logLevel,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
    );
    if (broadcastLogs) analyticsObserver.add(message);
  }

  /// Logs a warning [message] with [LogLevel.warning] to [Log.output].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void warning(
    String message, {
    bool addToCrashReports = true,
    String? location,
    String? tag,
  }) {
    const logLevel = LogLevel.warning;
    if (level.skipLog(logLevel)) return;
    _logMessage(
      message: message,
      logLevel: logLevel,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
    );
  }

  /// Logs an error [message] with [LogLevel.error] to [Log.output], with its [error] and its
  /// stack trace when [printStack] is true.
  ///
  /// Also tries to send the log with optional [error], [stackTrace] and [fatal] boolean to your
  /// [CrashReportsInterface] implementation should you have configured one with the
  /// [Loglytics.setUp] method.
  void error(
    String message, {
    String? location,
    Object? error,
    StackTrace? stackTrace,
    bool fatal = false,
    bool printStack = true,
    bool addToCrashReports = true,
    bool forceRecordError = false,
    String? tag,
  }) {
    var logLevel = fatal ? LogLevel.fatal : LogLevel.error;
    if (level.skipLog(logLevel)) return;
    StackTrace localStackTrace;
    try {
      localStackTrace = stackTrace ??
          StackTrace.fromString(
            StackTrace.current.toString().split('\n').sublist(1).join('\n'),
          );
    } catch (error) {
      localStackTrace = StackTrace.current;
    }
    _logMessage(
      message: message,
      logLevel: logLevel,
      addToCrashReports: addToCrashReports,
      location: location,
      tag: tag,
      error: error,
      stackTrace: localStackTrace,
      stackLinesInText: printStack ? _maxLinesStackTrace : 0,
    );
    if (error != null || forceRecordError) {
      _eventBus.tryAddCrashReport(
        Loglytics._crashReportsInterface?.recordError(
          error,
          localStackTrace,
          fatal: fatal,
        ),
      );
    }
  }

  /// Logs a fatal [message] with [LogLevel.fatal] to [Log.output].
  ///
  /// Also tries to send the log with optional [error], [stackTrace] and [fatal] boolean to your
  /// [CrashReportsInterface] implementation should you have configured one with the
  /// [Loglytics.setUp] method.
  void fatal(
    String message, {
    String? location,
    Object? error,
    StackTrace? stackTrace,
    bool printStack = true,
    bool addToCrashReports = true,
    bool forceRecordError = false,
    String? tag,
  }) =>
      this.error(
        message,
        location: location,
        error: error,
        stackTrace: stackTrace,
        fatal: true,
        printStack: printStack,
        addToCrashReports: addToCrashReports,
        forceRecordError: forceRecordError,
        tag: tag,
      );

  // --------------- PRINTERS --------------- PRINTERS --------------- PRINTERS --------------- \\

  /// Used under the hood to log a [message] with [logLevel].
  ///
  /// Also tries to send the log to your [CrashReportsInterface] implementation should you have
  /// configured one with the [Loglytics.setUp] method.
  void _logMessage({
    required String message,
    required LogLevel logLevel,
    bool addToCrashReports = true,
    String? location,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    int? stackLinesInText,
  }) {
    final localTag = tag ?? _tag;
    if (addToCrashReports) {
      _tryLogCrashReportMessage(message, logLevel, localTag);
    }
    final line = LogLine(
      time: DateTime.now().toUtc(),
      level: logLevel,
      location: location ?? _location,
      message: message,
      tag: localTag,
      error: error,
      stackTrace: stackTrace,
      stackLinesInText: stackLinesInText,
    );
    if (broadcastLogs) {
      final time = Log.logTime ? '${timeOf(line.time)} ' : '';
      crashReportsObserver.add('$time${line._prefix}$message');
      if (error != null) crashReportsObserver.add('$time${line._prefix}$error');
    }
    output(line);
  }

  // --------------- CRASH REPORTS --------------- CRASH REPORTS --------------- CRASH REPORTS --------------- \\

  /// Used under the hood to try and log a crashlytics [message] with [logLevel].
  void _tryLogCrashReportMessage(
    String message,
    LogLevel logLevel,
    String? tag,
  ) =>
      _eventBus.tryAddCrashReport(
        Loglytics._crashReportsInterface?.log(
          '${Loglytics._crashReportType.parseLogLevel(location: _location, logLevel: logLevel)} '
          '${tag != null ? '[$tag] ' : ''}'
          '$message',
        ),
      );
}
