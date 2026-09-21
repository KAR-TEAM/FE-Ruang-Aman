import 'package:flutter/material.dart';
import 'dashboard.dart';

class MainPageguru extends StatefulWidget {
  const MainPageguru({super.key});

  @override
  State<MainPageguru> createState() => _MainPageguruState();
}

class _MainPageguruState extends State<MainPageguru> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),

    Center(
      child: Text(
        "Laporan",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),

    Center(
      child: Text(
        "Siswa",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),

    Center(
      child: Text(
        "Akun",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F9F8),

      body: pages[currentIndex],

      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: "Dashboard",
              ),

              navItem(
                index: 1,
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: "Laporan",
              ),

              navItem(
                index: 2,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: "Siswa",
              ),

              navItem(
                index: 3,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: "Akun",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            currentIndex = index;
          });
        },
        child: SizedBox(
          height: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive
                    ? const Color(0xff009688)
                    : const Color(0xffB0B5B3),
              ),

              const SizedBox(height: 5),

              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? const Color(0xff009688)
                      : const Color(0xffB0B5B3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
