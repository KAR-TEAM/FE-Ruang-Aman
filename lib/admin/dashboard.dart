import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool loading = true;
  String? error;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> recentReports = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final statsResponse = await http.get(
        Uri.parse(ApiConfig.adminStats),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final reportsResponse = await http.get(
        Uri.parse(ApiConfig.adminReports),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (statsResponse.statusCode == 200 && reportsResponse.statusCode == 200) {
        final statsDecoded = jsonDecode(statsResponse.body);
        final reportsDecoded = jsonDecode(reportsResponse.body);

        List<Map<String, dynamic>> parsedReports = [];
        if (reportsDecoded is List) {
          parsedReports = reportsDecoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }

        if (mounted) {
          setState(() {
            stats = statsDecoded is Map<String, dynamic> ? statsDecoded : {};
            recentReports = parsedReports;
            loading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data dashboard dari server.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceFirst('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  String formatTanggal(dynamic raw) {
    if (raw == null) return '-';
    final input = raw.toString();
    final date = DateTime.tryParse(input);
    if (date == null) return input.split('T')[0];

    final local = date.toLocal();
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${local.day} ${bulan[local.month - 1]} ${local.year}';
  }

  Color statusColor(String status) {
    final normalized = status.toUpperCase();
    if (normalized.contains('SELESAI')) return const Color(0xff16A66A);
    if (normalized.contains('PROSES') || normalized.contains('DITANGANI')) return const Color(0xff3B82F6);
    return const Color(0xffF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    final totalSiswa = stats['total_siswa']?.toString() ?? '0';
    final totalGuruBk = stats['total_guru_bk']?.toString() ?? '0';
    final laporanSelesai = stats['laporan_selesai']?.toString() ?? '0';
    final laporanProses = stats['laporan_proses']?.toString() ?? '0';
    final totalLaporan = recentReports.length.toString();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            children: [
              // HEADER GAYA SUPERADMIN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Sekolah',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ringkasan statistik dan laporan masuk',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 1,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      onTap: loadDashboardData,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.refresh_rounded, size: 18, color: primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),

              // SUMMARY STATISTIK (GAYA KARTU BERSIH ALA SUPERADMIN)
              loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: primaryColor)))
                  : Column(
                      children: [
                        Row(
                          children: [
                            statCard('Total Siswa', totalSiswa, Icons.school_outlined, primaryColor),
                            const SizedBox(width: 12),
                            statCard('Guru BK', totalGuruBk, Icons.support_agent_rounded, const Color(0xff3B82F6)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            statCard('Total Laporan', totalLaporan, Icons.description_outlined, const Color(0xff8B5CF6)),
                            const SizedBox(width: 12),
                            statCard('Dalam Proses', laporanProses, Icons.hourglass_top_rounded, const Color(0xffF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            statCard('Selesai', laporanSelesai, Icons.check_circle_outline_rounded, const Color(0xff16A66A)),
                            const SizedBox(width: 12),
                            Expanded(child: SizedBox.shrink()), // Penyeimbang grid
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 25),
              const Text(
                'Laporan Terbaru',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
              ),
              const SizedBox(height: 12),

              // DAFTAR LAPORAN TERBARU
              loading
                  ? const SizedBox.shrink()
                  : recentReports.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Center(
                            child: Text('Belum ada laporan masuk', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                          ),
                        )
                      : Column(
                          children: recentReports.take(4).map((report) {
                            final status = report['status']?.toString() ?? 'BARU';
                            final tanggal = formatTanggal(report['tanggal']);
                            final pelapor = report['nama_pelapor'] ?? 'Siswa';
                            final colorStatus = statusColor(status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorStatus.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.assignment_outlined, color: colorStatus, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pelapor,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: darkPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tanggal,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorStatus.withAlpha(15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(fontSize: 10, color: colorStatus, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}