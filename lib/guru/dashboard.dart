import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ruang_aman/ipconfig.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool isLoading = true;
  String? error;

  // State menampung data sesuai backend
  Map<String, dynamic> stats = {};
  List<dynamic> recentReports = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // Mengambil data dari endpoint backend /api/bk/dashboard/stats & /api/bk/reports
  Future<void> loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // 1. Fetch Statistik Dashboard (Sesuai bkController.js: dashboardStats)
      final statsResponse = await http.get(
        Uri.parse(ApiConfig.bkDashboardStats),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      // 2. Fetch Daftar Laporan untuk Laporan Terbaru
      final reportsResponse = await http.get(
        Uri.parse(ApiConfig.bkReports),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (statsResponse.statusCode != 200 || reportsResponse.statusCode != 200) {
        throw Exception('Gagal memuat data dari server.');
      }

      final statsData = jsonDecode(statsResponse.body);
      final reportsData = jsonDecode(reportsResponse.body);

      if (!mounted) return;

      setState(() {
        // Karena bkController mengembalikan objek stats langsung (stats[0])
        stats = Map<String, dynamic>.from(statsData);
        
        // Ambil maksimal 5 laporan terbaru dari daftar laporan
        if (reportsData is List) {
          recentReports = reportsData.take(5).toList();
        }
        
        isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard Guru BK',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pantau statistik dan laporan siswa',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: isLoading ? null : loadDashboardData,
                    icon: const Icon(Icons.refresh_rounded, color: primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Loading / Error Handling
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                )
              else if (error != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                )
              else ...[
                // Bagian Statistik Grid (Sesuai properti di bkController.js)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildStatCard(
                      'Total Laporan',
                      '${stats['total_laporan'] ?? 0}',
                      Icons.description_outlined,
                      primaryColor,
                      lightGreen,
                    ),
                    _buildStatCard(
                      'Laporan Baru',
                      '${stats['jumlah_baru'] ?? 0}',
                      Icons.fiber_new_outlined,
                      Colors.orange,
                      const Color(0xffFFF4E1),
                    ),
                    _buildStatCard(
                      'Sedang Ditangani',
                      '${stats['sedang_ditangani'] ?? 0}',
                      Icons.hourglass_bottom_rounded,
                      Colors.blue,
                      const Color(0xffE8F1FF),
                    ),
                    _buildStatCard(
                      'Selesai',
                      '${stats['selesai'] ?? 0}',
                      Icons.check_circle_outline_rounded,
                      Colors.teal,
                      const Color(0xffE9F7F1),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Bagian Laporan Terbaru
                const Text(
                  'Laporan Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (recentReports.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text('Belum ada laporan masuk.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentReports.length,
                    itemBuilder: (context, index) {
                      final report = recentReports[index];
                      final jenis = report['jenis'] ?? 'Kejadian';
                      final status = report['status'] ?? 'BARU';
                      final lokasi = report['lokasi'] ?? '-';
                      final pelapor = report['pelapor']?['nama'] ?? 'Anonim';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: lightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.report_problem_outlined, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jenis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Pelapor: $pelapor • $lokasi',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'SELESAI' ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'SELESAI' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                count,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkPrimary),
          ),
        ],
      ),
    );
  }
}