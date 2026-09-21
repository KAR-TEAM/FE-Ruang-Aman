import 'package:flutter/material.dart';
import 'package:ruang_aman/Auth/splascreeen.dart';

void main() {
  runApp(const RuangAmanApp());
}

class RuangAmanApp extends StatelessWidget {
  const RuangAmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Ruang Aman",

      theme: ThemeData(
        fontFamily: "Poppins",

        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.black,

            fontSize: 14,

            decoration: TextDecoration.none,
          ),

          bodyMedium: TextStyle(
            color: Colors.black,

            fontSize: 14,

            decoration: TextDecoration.none,
          ),

          bodySmall: TextStyle(
            color: Colors.grey,

            fontSize: 12,

            decoration: TextDecoration.none,
          ),

          titleMedium: TextStyle(
            color: Colors.black,

            decoration: TextDecoration.none,
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
