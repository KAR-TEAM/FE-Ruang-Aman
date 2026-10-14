import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          children: [
            const Text(
              "Pusat Bantuan",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "Temukan informasi dan panduan seputar layanan RuangAman.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffD6EFE7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Butuh Penanganan Cepat?",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Hubungi Guru BK atau datangi ruang Bimbingan Konseling sekolah untuk bantuan darurat.",
                          style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xff34403D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "Pertanyaan Umum (FAQ)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkPrimary),
            ),
            const SizedBox(height: 12),

            faqItem(
              "Bagaimana cara membuat laporan?",
              "Tekan tombol tambah (+) pada halaman beranda, pilih jenis laporan, isi formulir kejadian secara lengkap, lalu lampirkan bukti foto jika ada.",
            ),
            faqItem(
              "Apakah laporan anonim saya benar-benar aman?",
              "Ya. Identitas Anda akan disembunyikan sepenuhnya dari sistem pelaporan publik dan hanya dapat ditinjau secara terbatas oleh pihak berwenang (Guru BK).",
            ),
            faqItem(
              "Bagaimana cara melihat status tindak lanjut laporan?",
              "Anda dapat melihat status laporan terkini di halaman Beranda atau masuk ke menu Laporan untuk melihat riwayat penanganan lengkap dari Guru BK.",
            ),
            faqItem(
              "Apa arti status laporan (BARU, DIPROSES, SELESAI)?",
              "• BARU: Laporan berhasil dikirim dan menunggu ditinjau.\n• DIPROSES: Laporan sedang ditindaklanjuti oleh tim BK.\n• SELESAI: Penanganan kasus telah diselesaikan.",
            ),
          ],
        ),
      ),
    );
  }

  Widget faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: primaryColor,
          collapsedIconColor: Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            question,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: darkPrimary),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xff34403D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}