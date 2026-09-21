import 'package:flutter/material.dart';
// import 'package:ruang_aman/siswa/menu.dart';
import 'package:ruang_aman/siswa/melapor/buat_laporan.dart';
import 'package:ruang_aman/siswa/melapor/pilih_laporan.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF7FCFA),

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,

            right: 20,

            top: 25,

            bottom: 90,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,

                        backgroundColor: Colors.green.shade100,

                        child: const Icon(
                          Icons.person,

                          size: 32,

                          color: Color(0xff009B88),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            "Halo, Andi! 👋",

                            style: TextStyle(
                              decoration: TextDecoration.none,

                              fontSize: 17,

                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            "Kelas XI IPA 2",

                            style: TextStyle(
                              decoration: TextDecoration.none,

                              fontSize: 13,

                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_none,

                        size: 30,

                        color: Colors.grey,
                      ),

                      Positioned(
                        right: 2,

                        top: 2,

                        child: Container(
                          width: 8,

                          height: 8,

                          decoration: const BoxDecoration(
                            color: Colors.red,

                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // MOTIVATION CARD
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xffE9F7F1),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Setiap cerita penting.\n"
                        "Terima kasih sudah\n"
                        "berani bercerita. 🌱",

                        style: TextStyle(
                          decoration: TextDecoration.none,

                          fontSize: 14,

                          fontWeight: FontWeight.w600,

                          color: Color(0xff3B5F57),
                        ),
                      ),
                    ),

                    Icon(Icons.eco, size: 55, color: Colors.green.shade400),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PilihLaporanPage(),
                    ),
                  );
                },

                child: Container(
                  width: double.infinity,

                  height: 50,

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff35B99A), Color(0xff009B88)],
                    ),

                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: const Center(
                    child: Text(
                      "+  Buat Laporan",

                      style: TextStyle(
                        decoration: TextDecoration.none,

                        color: Colors.white,

                        fontSize: 14,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "Ringkasan Laporan Saya",

                style: TextStyle(
                  decoration: TextDecoration.none,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  summaryCard(
                    icon: Icons.description,

                    title: "Dibuat",

                    value: "2",

                    color: Colors.teal,
                  ),

                  summaryCard(
                    icon: Icons.hourglass_bottom,

                    title: "Diproses",

                    value: "1",

                    color: Colors.orange,
                  ),

                  summaryCard(
                    icon: Icons.check_circle,

                    title: "Selesai",

                    value: "1",

                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                "Laporan Terakhir",

                style: TextStyle(
                  decoration: TextDecoration.none,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),

                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "RA-2026-0012",

                      style: TextStyle(
                        decoration: TextDecoration.none,

                        fontSize: 15,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Perundungan",

                      style: TextStyle(
                        decoration: TextDecoration.none,

                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          "20 Mei 2026, 10:30",

                          style: TextStyle(
                            decoration: TextDecoration.none,

                            fontSize: 12,

                            color: Colors.grey.shade600,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,

                            vertical: 5,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,

                            borderRadius: BorderRadius.circular(15),
                          ),

                          child: const Text(
                            "Sedang Ditangani",

                            style: TextStyle(
                              decoration: TextDecoration.none,

                              fontSize: 11,

                              color: Colors.blue,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryCard({
    required IconData icon,

    required String title,

    required String value,

    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),

        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icon, size: 24, color: color),

            const SizedBox(height: 5),

            Text(
              value,

              style: const TextStyle(
                decoration: TextDecoration.none,

                fontSize: 20,

                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              title,

              style: TextStyle(
                decoration: TextDecoration.none,

                fontSize: 11,

                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
