part of '../loglytics/loglytics.dart';

/// One line that a [Log] writes, with its time, level, location and, for an error, the error and
/// its stack trace.
///
/// [toString] renders the line as text, with the error and the stack trace on the lines after it.
class LogLine {
  const LogLine({
    required this.time,
    required this.level,
    required this.location,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  /// When the line was written, in UTC.
  final DateTime time;

  /// How much the line matters.
  final LogLevel level;

  /// The part of the program that wrote the line.
  final String location;

  /// What happened.
  final String message;

  /// An optional tag that groups lines across locations.
  final String? tag;

  /// The error of an error line.
  final Object? error;

  /// The stack trace of an error line.
  final StackTrace? stackTrace;

  @override
  String toString() => [
        '${level.iconTag} [$location] ${tag != null ? '[$tag] ' : ''}$message',
        if (error != null) '$error',
        if (stackTrace != null) '$stackTrace'.trimRight(),
      ].join('\n');
}
