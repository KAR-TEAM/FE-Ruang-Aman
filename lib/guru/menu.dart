import 'package:flutter/material.dart';
import 'package:ruang_aman/guru/dashboard.dart';
import 'package:ruang_aman/guru/reports.dart';
import 'package:ruang_aman/guru/students.dart';
import 'package:ruang_aman/guru/profile.dart';

class MainPageguru extends StatefulWidget {
  const MainPageguru({super.key});

  @override
  State<MainPageguru> createState() => _MainPageguruState();
}

class _MainPageguruState extends State<MainPageguru> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    // HALAMAN DASHBOARD
    DashboardPage(),

    // HALAMAN LAPORAN
    LaporanMasukPage(),

    // HALAMAN SISWA
    DataSiswaPage(),

    // HALAMAN AKUN
    ProfileGuruPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7FCFA),

      // MENAMPILKAN HALAMAN SESUAI MENU
      body: IndexedStack(index: currentIndex, children: pages),

      // BOTTOM NAVIGATION BAR (DISESUAIKAN DENGAN STANDAR SUPERADMIN)
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
          indicatorColor: const Color(0xffE9F7F1), // Kapsul hijau muda aktif
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              currentIndex = index;
            });
          },
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
              icon: Icon(Icons.assignment_outlined, color: Colors.grey),
              selectedIcon: Icon(
                Icons.assignment_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.grey),
              selectedIcon: Icon(
                Icons.people_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Siswa',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: Color(0xff009B88),
              ),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}