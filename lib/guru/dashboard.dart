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

  Map<String, dynamic> stats = {};
  List<dynamic> recentReports = [];

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

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

      final statsResponse = await http.get(
        Uri.parse(ApiConfig.bkDashboardStats),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

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
        stats = Map<String, dynamic>.from(statsData);
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

  // ============================================================
  // BANNER SAMBUTAN GAYA AWWWARDS
  // ============================================================
  Widget buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Halo, Guru BK!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : loadDashboardData,
              icon: const Icon(Icons.notifications_none_rounded, color: darkPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Pantau statistik laporan siswa dan\nberikan pendampingan terbaik.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RuangAman Konseling',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Menciptakan lingkungan\nsekolah yang aman, nyaman,\ndan responsif terhadap siswa.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xff34403D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 40,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATISTIK CARD (2 x 2 GRID)
  // ============================================================
  Widget _buildStatCard(String title, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              count,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget buildStatisticGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 122,
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
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              buildWelcomeSection(),
              const SizedBox(height: 22),

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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                )
              else ...[
                buildStatisticGrid(),
                const SizedBox(height: 24),

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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Belum ada laporan masuk.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  )
                else
                  ...recentReports.map((report) {
                    final jenis = report['jenis'] ?? 'Kejadian';
                    final status = report['status'] ?? 'BARU';
                    final lokasi = report['lokasi'] ?? '-';
                    final pelapor = report['pelapor']?['nama'] ?? 'Anonim';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(12),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: darkPrimary),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Pelapor: $pelapor • $lokasi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'SELESAI' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
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
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}