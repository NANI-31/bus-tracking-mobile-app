import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileOutput extends LogOutput {
  late File file;

  FileOutput();

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    file = File('${directory.path}/app_logs.txt');
  }

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      file.writeAsStringSync(
        '${DateTime.now()}: $line\n',
        mode: FileMode.append,
      );
    }
  }
}

class AppLogger {
  static final FileOutput _fileOutput = FileOutput();
  static late Logger _logger;

  static Future<void> init() async {
    await _fileOutput.init();
    _logger = Logger(
      filter: ProductionFilter(), // Log everything in production too for now
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: MultiOutput([ConsoleOutput(), _fileOutput]),
    );
  }

  // Fallback logger if init() hasn't been called yet
  static Logger get logger {
    try {
      return _logger;
    } catch (e) {
      return Logger(printer: PrettyPrinter());
    }
  }

  /// Log a debug message (Cyan)
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message (Blue)
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message (Orange)
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message (Red)
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a verbose message (Grey)
  static void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a WTF message (Pink)
  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
  }
}
