import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'schools.dart';
import 'users.dart';
import 'profile.dart';

class MenuSuperadmin extends StatefulWidget {
  const MenuSuperadmin({super.key});

  @override
  State<MenuSuperadmin> createState() =>
      _MenuSuperadminState();
}

class _MenuSuperadminState extends State<MenuSuperadmin> {
  int selectedIndex = 0;

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardSuperadmin(
        onNavigate: changePage,
      ),
      const SekolahSuperadmin(),
      const PenggunaSuperadmin(),
      const ProfilSuperadmin(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF7FCFA),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: const Color(0xffE9F7F1), // Warna kapsul hijau muda aktif
          selectedIndex: selectedIndex,
          onDestinationSelected: changePage,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined, color: Colors.grey),
              selectedIcon: Icon(
                Icons.school_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Sekolah',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.grey),
              selectedIcon: Icon(
                Icons.people_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Pengguna',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}