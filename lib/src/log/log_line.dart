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
    this.stackLinesInText,
  });

  /// The moment of the line, in UTC.
  final DateTime time;

  /// How much the line matters.
  final LogLevel level;

  /// The part of the program that writes the line.
  final String location;

  /// What the line tells.
  final String message;

  /// An optional tag that groups lines across locations.
  final String? tag;

  /// The error of an error line.
  final Object? error;

  /// The whole stack trace of an error line.
  final StackTrace? stackTrace;

  /// How many lines of [stackTrace] the text shows: all of them when null and none when 0.
  final int? stackLinesInText;

  /// The level, location and tag in front of the message and the error in the text.
  String get _prefix => '${level.iconTag} [$location] ${tag != null ? '[$tag] ' : ''}';

  @override
  String toString() {
    final stackLines = '${stackTrace ?? ''}'.trimRight().split('\n').where((l) => l.isNotEmpty);
    return [
      '$_prefix$message',
      if (error != null) '$_prefix$error',
      ...switch (stackLinesInText) {
        null => stackLines,
        final count => stackLines.take(count),
      },
    ].join('\n');
  }
}
