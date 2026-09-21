import 'package:flutter/material.dart';
import 'home.dart';
import 'laporan/index.dart';
import 'profile.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomePage(),

    const LaporanPage(),

    const Center(child: Text("Bantuan")),

    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,

        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xff009B88),

        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),

            activeIcon: Icon(Icons.home),

            label: "Beranda",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),

            label: "Laporan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),

            label: "Bantuan",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),

            label: "Profil",
          ),
        ],
      ),
    );
  }
}
