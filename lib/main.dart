import 'package:flutter/material.dart';
import 'package:things_map/core/init_setup.dart';
import 'package:things_map/view/page/items_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSetup();
  runApp(const ThingsMapApp());
}

class ThingsMapApp extends StatelessWidget {
  const ThingsMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unforget',
      theme: ThemeData(
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: ItemsView(),
    );
  }
}
