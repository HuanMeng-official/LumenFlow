import 'package:intl/intl.dart';

/// 时间工具类，为模型提供当前时间、时间戳和格式化时间的功能。
class TimeUtils {
  TimeUtils._();

  static DateTime now() => DateTime.now();
  static int timestamp() => now().millisecondsSinceEpoch;

  static String format({String pattern = 'yyyy-MM-dd HH:mm:ss', DateTime? time}) {
    final dateTime = time ?? now();
    return DateFormat(pattern).format(dateTime);
  }
}
