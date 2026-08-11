import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    TextTheme themed;

    if (family == 'System') {
      // Use the platform's default font
      themed = base;
    } else {
      switch (family) {
        case 'Roboto':
          themed = GoogleFonts.robotoTextTheme(base);
          break;
        case 'Open Sans':
          themed = GoogleFonts.openSansTextTheme(base);
          break;
        case 'Lato':
          themed = GoogleFonts.latoTextTheme(base);
          break;
        case 'Source Sans 3':
          themed = GoogleFonts.sourceSans3TextTheme(base);
          break;
        case 'Merriweather':
          themed = GoogleFonts.merriweatherTextTheme(base);
          break;
        case 'Lora':
          themed = GoogleFonts.loraTextTheme(base);
          break;
        case 'Noto Serif':
          themed = GoogleFonts.notoSerifTextTheme(base);
          break;
        case 'Inter':
        default:
          themed = GoogleFonts.interTextTheme(base);
      }
    }

    // Apply the chosen base font size
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
