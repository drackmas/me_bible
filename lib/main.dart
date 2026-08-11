import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/reader_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = ThemeService();
  await themeService.load();

  runApp(
    ChangeNotifierProvider.value(
      value: themeService,
      child: const BibleApp(),
    ),
  );
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  TextTheme _buildTextTheme(String family, Brightness brightness, double fontSize) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    // Apply the selected font family (null = System / platform default)
    final String? fontFamily = family == 'System' ? null : family;

    final themed = base.apply(
      fontFamily: fontFamily,
    );

    // Apply the user's chosen base font size
    return themed.copyWith(
      bodyLarge: themed.bodyLarge?.copyWith(fontSize: fontSize + 2),
      bodyMedium: themed.bodyMedium?.copyWith(fontSize: fontSize),
      bodySmall: themed.bodySmall?.copyWith(fontSize: fontSize - 2),
      titleLarge: themed.titleLarge?.copyWith(fontSize: fontSize + 6),
      titleMedium: themed.titleMedium?.copyWith(fontSize: fontSize + 2),
      titleSmall: themed.titleSmall?.copyWith(fontSize: fontSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'Bible Study',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        textTheme: _buildTextTheme(
          themeService.fontFamily,
          Brightness.light,
          themeService.fontSize,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
        textTheme: _buildTextTheme(
          themeService.fontFamily,
          Brightness.dark,
          themeService.fontSize,
        ),
      ),
      themeMode: themeService.mode,
      home: const ReaderScreen(initialBook: 'Genesis'),
    );
  }
}
