/// Used to format the time in each log.
extension on DateTime {
  String get hourMinuteSecond => '${hour < 10 ? '0$hour' : hour}:'
      '${minute < 10 ? '0$minute' : minute}:'
      '${second < 10 ? '0$second' : second}';
}

/// The local time of [moment] as it shows in front of a log line.
String timeOf(DateTime moment) => '[${moment.toLocal().hourMinuteSecond}]';
