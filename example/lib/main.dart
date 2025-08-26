import 'package:flutter/material.dart';
import 'screens/device_list_screen.dart';

void main() {
  runApp(const OnvifApp());
}

class OnvifApp extends StatelessWidget {
  const OnvifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONVIF Camera Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: DeviceListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
