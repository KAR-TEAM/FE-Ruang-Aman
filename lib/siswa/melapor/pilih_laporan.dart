import 'package:flutter/material.dart';

import 'buat_laporan_anonim.dart';
import 'buat_laporan_data.dart';

class PilihLaporanPage extends StatelessWidget {
  const PilihLaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF7FCFA),

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,

            right: 20,

            top: 30,

            bottom: 40,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: const Icon(Icons.arrow_back, size: 24),
                  ),

                  const Text(
                    "Buat Laporan",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const Icon(Icons.help_outline, color: Color(0xff009B88)),
                ],
              ),

              const SizedBox(height: 35),

              // TITLE
              const Text(
                "Bagaimana kamu ingin melapor?",

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                "Pilih metode laporan yang membuat kamu merasa aman dan nyaman.",

                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 30),

              // SAFETY CARD
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xffE9F7F1),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 45,

                      height: 45,

                      decoration: BoxDecoration(
                        color: const Color(0xff009B88).withOpacity(.15),

                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.shield_outlined,

                        color: Color(0xff009B88),
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        "Setiap laporan akan ditangani secara aman dan rahasia oleh Guru BK.",

                        style: TextStyle(
                          fontSize: 13,

                          color: Color(0xff355B53),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ANONIM
              reportOption(
                context,

                icon: Icons.visibility_off_outlined,

                title: "Laporan Anonim",

                description:
                    "Identitas kamu tidak akan ditampilkan kepada pihak sekolah.",

                color: const Color(0xff009B88),

                anonim: true,
              ),

              const SizedBox(height: 18),

              // DATA DIRI
              reportOption(
                context,

                icon: Icons.person_outline,

                title: "Menggunakan Data Diri",

                description:
                    "Nama dan informasi diri digunakan untuk proses tindak lanjut.",

                color: Colors.blue,

                anonim: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget reportOption(
    BuildContext context, {

    required IconData icon,

    required String title,

    required String description,

    required Color color,

    required bool anonim,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) => anonim
                ? const BuatLaporanAnonimPage()
                : const BuatLaporanDataPage(),
          ),
        );
      },

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),

              blurRadius: 12,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 55,

              height: 55,

              decoration: BoxDecoration(
                color: color.withOpacity(.15),

                borderRadius: BorderRadius.circular(16),
              ),

              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    description,

                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            Container(
              width: 30,

              height: 30,

              decoration: BoxDecoration(
                color: const Color(0xffF0F7F5),

                borderRadius: BorderRadius.circular(10),
              ),

              child: const Icon(
                Icons.arrow_forward_ios,

                size: 14,

                color: Color(0xff009B88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
