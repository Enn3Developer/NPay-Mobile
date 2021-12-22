import 'dart:async';

import 'package:f_logs/model/flog/flog.dart';
import 'package:f_logs/model/flog/flog_config.dart';
import 'package:f_logs/utils/formatter/field_name.dart';
import 'package:f_logs/utils/formatter/formate_type.dart';
import 'package:f_logs/utils/timestamp/timestamp_format.dart';
import 'package:flutter/material.dart';

import 'pages/login.dart';
import 'utils/npay_color.dart';

void main() {
  init();
  const duration = Duration(seconds: 5);
  Timer.periodic(duration, (timer) {
    FLog.exportLogs();
  });
  try {
    runApp(const MyApp());
  } catch (e) {
    FLog.fatal(text: "Main error", exception: e);
  }
}

init() {
  LogsConfig config = FLog.getDefaultConfigurations()
    ..isDevelopmentDebuggingEnabled = true
    ..timestampFormat = TimestampFormat.TIME_FORMAT_FULL_3
    ..formatType = FormatType.FORMAT_CUSTOM
    ..fieldOrderFormatCustom = [
      FieldName.TIMESTAMP,
      FieldName.LOG_LEVEL,
      FieldName.CLASSNAME,
      FieldName.METHOD_NAME,
      FieldName.TEXT,
      FieldName.EXCEPTION,
      FieldName.STACKTRACE
    ]
    ..customOpeningDivider = "{"
    ..customClosingDivider = "}";

  FLog.applyConfigurations(config);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPay',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: blueColor,
        toggleableActiveColor: blueColor,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: blueColor,
        toggleableActiveColor: blueColor,
      ),
      home: const LoginPage(autoLogin: true),
    );
  }
}
