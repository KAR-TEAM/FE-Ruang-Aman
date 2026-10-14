import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';

class DashboardSuperadmin extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardSuperadmin({super.key, required this.onNavigate});

  @override
  State<DashboardSuperadmin> createState() => _DashboardSuperadminState();
}

class _DashboardSuperadminState extends State<DashboardSuperadmin> {
  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ============================================================
  // STATE
  // ============================================================

  bool loading = true;
  String? error;

  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> recentSchools = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  // ============================================================
  // AMBIL DATA DASHBOARD (STATISTIK & SEKOLAH TERBARU)
  // ============================================================

  Future<void> loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // 1. Ambil Statistik
      final statsResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools-stats'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final statsResult = jsonDecode(statsResponse.body);
      if (statsResponse.statusCode != 200) {
        throw Exception(statsResult['message'] ?? 'Gagal mengambil statistik');
      }

      // 2. Ambil Daftar Sekolah Terbaru (Limit 3)
      final schoolsResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/superadmin/search'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final schoolsResult = jsonDecode(schoolsResponse.body);
      List<Map<String, dynamic>> schoolList = [];
      if (schoolsResponse.statusCode == 200) {
        dynamic data = schoolsResult;
        if (data is Map && data.containsKey('data')) data = data['data'];
        if (data is Map) data = data['schools'] ?? data['sekolah'] ?? [];
        if (data is List) {
          schoolList = data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (!mounted) return;

      setState(() {
        stats = Map<String, dynamic>.from(statsResult['data'] ?? statsResult);
        recentSchools = schoolList.take(3).toList();
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String value(List<String> keys) {
    for (final key in keys) {
      final data = stats[key];
      if (data != null) return data.toString();
    }
    return '0';
  }

  // ============================================================
  // HEADER & BANNER SAMBUTAN (SESUAI GAMBAR)
  // ============================================================

  Widget buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Halo, Superadmin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
            IconButton(
              onPressed: loadDashboardData,
              icon: const Icon(Icons.notifications_none_rounded, color: darkPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola data sekolah dan pengguna\npada platform RuangAman.',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
        ),
        const SizedBox(height: 18),
        // Banner Ilustrasi / Info Card Hijau
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
                      'RuangAman',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Mendukung lingkungan\nsekolah yang aman,\nnyaman, dan terpercaya.',
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
              // Icon Ilustrasi Sekolah
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.school_rounded,
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

  // ============================================================
  // STATISTIK CARD (DIPERBAIKI AGAR TIDAK OVERFLOW)
  // ============================================================

  Widget statisticCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mengatur jarak merata secara vertikal
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID STATISTIK 2x2
  // ============================================================

  Widget buildStatisticGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 122, // Dinaikkan sedikit dari 115 ke 122 agar sangat pas
      children: [
        statisticCard(
          title: 'Total Sekolah',
          count: value(['total_sekolah', 'totalSchools', 'total_schools']),
          subtitle: 'Sekolah terdaftar',
          icon: Icons.school_outlined,
          iconColor: primaryColor,
          iconBg: lightGreen,
        ),
        statisticCard(
          title: 'Total Pengguna',
          count: value(['total_users', 'totalUsers']),
          subtitle: 'Semua akun aktif',
          icon: Icons.people_outline,
          iconColor: const Color(0xff3B82F6),
          iconBg: const Color(0xffE8F1FF),
        ),
        statisticCard(
          title: 'Total Siswa',
          count: value(['total_siswa', 'totalStudents', 'total_students']),
          subtitle: 'Akun siswa aktif',
          icon: Icons.person_outline,
          iconColor: const Color(0xff10B981),
          iconBg: const Color(0xffE6F7F2),
        ),
        statisticCard(
          title: 'Total Guru BK',
          count: value(['total_guru_bk', 'totalTeachers', 'total_guru']),
          subtitle: 'Guru konseling',
          icon: Icons.support_agent_outlined,
          iconColor: const Color(0xffF59E0B),
          iconBg: const Color(0xffFFF4E1),
        ),
      ],
    );
  }
  
  // ============================================================
  // DAFTAR SEKOLAH TERBARU SECTION
  // ============================================================

  Widget buildRecentSchoolsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Sekolah Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(1), // Navigasi ke Tab Sekolah (Index 1)
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentSchools.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Belum ada data sekolah', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        else
          ...recentSchools.map((school) {
            final nama = '${school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah'}';
            final alamat = '${school['alamat'] ?? '-'}';

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
                    child: const Icon(Icons.school_outlined, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                alamat,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            );
          }),
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
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboardData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              // BANNER SAMBUTAN
              buildWelcomeSection(),

              const SizedBox(height: 22),

              // LOADING / ERROR HANDLE
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              else ...[
                // STATISTIK GRID 2x2
                buildStatisticGrid(),

                const SizedBox(height: 24),

                // DAFTAR SEKOLAH TERBARU
                buildRecentSchoolsSection(),
              ],

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}