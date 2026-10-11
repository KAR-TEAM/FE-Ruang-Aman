
import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'sekolah.dart';
import 'pengguna.dart';
import 'profil.dart';

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

      bottomNavigationBar: NavigationBar(
        height: 75,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffE9F7F1),
        selectedIndex: selectedIndex,

        onDestinationSelected: changePage,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard,
              color: Color(0xff009B88),
            ),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(
              Icons.school,
              color: Color(0xff009B88),
            ),
            label: 'Sekolah',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(
              Icons.people,
              color: Color(0xff009B88),
            ),
            label: 'Pengguna',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: Color(0xff009B88),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
