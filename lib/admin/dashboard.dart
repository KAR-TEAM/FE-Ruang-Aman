
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/admin/admin_sekolah.dart';

class DashboardSuperadmin extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardSuperadmin({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DashboardSuperadmin> createState() =>
      _DashboardSuperadminState();
}

class _DashboardSuperadminState extends State<DashboardSuperadmin> {
  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // ============================================================
  // STATE
  // ============================================================

  bool loading = true;
  String? error;

  Map<String, dynamic> stats = {};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  // ============================================================
  // AMBIL STATISTIK SUPERADMIN
  // GET /api/superadmin/schools-stats
  // ============================================================

  Future<void> loadStats() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // AMBIL TOKEN LOGIN
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      // REQUEST API
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools-stats',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      // PARSING JSON
      final dynamic result;

      try {
        result = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respons backend bukan JSON yang valid',
        );
      }

      // VALIDASI RESPONSE
      if (response.statusCode == 401) {
        throw Exception(
          'Sesi login tidak valid atau sudah kedaluwarsa.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses ditolak. Akun harus memiliki role Superadmin.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = result is Map
            ? result['message']?.toString()
            : null;

        throw Exception(
          message ??
              'Gagal mengambil statistik (${response.statusCode})',
        );
      }

      if (result is Map && result['success'] == false) {
        throw Exception(
          result['message']?.toString() ??
              'Gagal mengambil statistik',
        );
      }

      // AMBIL DATA
      dynamic data = result;

      if (result is Map && result.containsKey('data')) {
        data = result['data'];
      }

      if (data is! Map) {
        throw Exception(
          'Format data statistik tidak sesuai',
        );
      }

      if (!mounted) return;

      setState(() {
        stats = Map<String, dynamic>.from(data);
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

  // ============================================================
  // AMBIL NILAI STATISTIK
  // ============================================================

  String value(List<String> keys) {
    for (final key in keys) {
      final data = stats[key];

      if (data != null) {
        return data.toString();
      }
    }

    // Jika key API belum sesuai
    return '—';
  }

  // ============================================================
  // HEADER DASHBOARD
  // ============================================================

  Widget buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pantau seluruh sistem RuangAman',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Refresh statistik',
            onPressed: loading ? null : loadStats,
            icon: const Icon(
              Icons.refresh_rounded,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang, Superadmin 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pantau perkembangan sistem, kelola sekolah, '
                  'dan atur pengguna dalam satu aplikasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff55736D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(
            Icons.admin_panel_settings_outlined,
            size: 48,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD STATISTIK
  // ============================================================

  Widget statisticCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            count,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xff1E2926),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xff34403D),
            ),
          ),

          const SizedBox(height: 4),

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
  // GRID STATISTIK RESPONSIVE
  // ============================================================

  Widget buildStatisticGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 900) {
          columns = 4;
        } else if (constraints.maxWidth >= 320) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 165,
          children: [
            statisticCard(
              title: 'Total Sekolah',
              count: value([
                'total_sekolah',
                'totalSchools',
                'total_schools',
              ]),
              subtitle: 'Sekolah terdaftar',
              icon: Icons.school_outlined,
              iconColor: primaryColor,
              iconBackground: lightGreen,
            ),

            statisticCard(
              title: 'Total Siswa',
              count: value([
                'total_siswa',
                'totalStudents',
                'total_students',
              ]),
              subtitle: 'Akun siswa aktif',
              icon: Icons.people_outline,
              iconColor: const Color(0xff3B82F6),
              iconBackground: const Color(0xffE8F1FF),
            ),

            statisticCard(
              title: 'Total Guru BK',
              count: value([
                'total_guru_bk',
                'totalTeachers',
                'total_guru',
              ]),
              subtitle: 'Guru konseling',
              icon: Icons.support_agent_outlined,
              iconColor: const Color(0xffF59E0B),
              iconBackground: const Color(0xffFFF4E1),
            ),

            statisticCard(
              title: 'Admin Sekolah',
              count: value([
                'total_admin',
                'total_admins',
                'totalAdmins',
              ]),
              subtitle: 'Akun pengelola',
              icon: Icons.admin_panel_settings_outlined,
              iconColor: const Color(0xff8B5CF6),
              iconBackground: const Color(0xffF1EBFF),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CARD MENU
  // ============================================================

  Widget menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: primaryColor,
        ),
      ),
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
          onRefresh: loadStats,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20, 25, 20, 30,
            ),
            children: [
              // HEADER
              buildHeader(),

              const SizedBox(height: 25),

              // WELCOME
              buildWelcomeCard(),

              const SizedBox(height: 28),

              // RINGKASAN
              const Text(
                'Ringkasan Sistem',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1F2937),
                ),
              ),

              const SizedBox(height: 15),

              // LOADING
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                ),

              // ERROR
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDECEC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // STATISTIK
              if (!loading)
                buildStatisticGrid(),

              const SizedBox(height: 28),

              // MANAJEMEN SISTEM
              const Text(
                'Manajemen Sistem',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1F2937),
                ),
              ),

              const SizedBox(height: 15),

              menuCard(
                title: 'Manajemen Sekolah',
                subtitle:
                    'Tambah, edit, cari, dan hapus sekolah',
                icon: Icons.school_outlined,
                onTap: () {
                  widget.onNavigate(1);
                },
              ),

              menuCard(
                title: 'Admin Sekolah',
                subtitle:
                    'Buat akun admin sekolah baru',
                icon: Icons.person_add_alt_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AdminSekolahPage(),
                    ),
                  );
                },
              ),

              menuCard(
                title: 'Manajemen Pengguna',
                subtitle:
                    'Kelola siswa, Guru BK, dan admin',
                icon: Icons.people_outline,
                onTap: () {
                  widget.onNavigate(2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
