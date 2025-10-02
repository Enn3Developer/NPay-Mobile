import 'package:flutter/material.dart';

import 'pages/login.dart';
import 'utils/npay_color.dart';

void main() {
  init();
  // const duration = Duration(seconds: 5);
  // Timer.periodic(duration, (timer) {
  //   FLog.exportLogs();
  // });
  try {
    runApp(const MyApp());
  } catch (e) {
    // log("Main error", exception: e);
  }
}

void init() {
  // LogsConfig config = FLog.getDefaultConfigurations()
  //   ..isDevelopmentDebuggingEnabled = true
  //   ..timestampFormat = TimestampFormat.TIME_FORMAT_FULL_3
  //   ..formatType = FormatType.FORMAT_CUSTOM
  //   ..fieldOrderFormatCustom = [
  //     FieldName.TIMESTAMP,
  //     FieldName.LOG_LEVEL,
  //     FieldName.CLASSNAME,
  //     FieldName.METHOD_NAME,
  //     FieldName.TEXT,
  //     FieldName.EXCEPTION,
  //     FieldName.STACKTRACE
  //   ];
  //
  // FLog.applyConfigurations(config);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPay',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: blueColor,
        fontFamily: "Verdana",
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: blueColor,
        fontFamily: "Verdana",
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            if (states.contains(WidgetState.selected)) {
              return blueColor;
            }
            return null;
          }),
        ),
      ),
      home: const LoginPage(autoLogin: true),
    );
  }
}
