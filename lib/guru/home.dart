import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const Color highColor = Color(0xffEF5350);
  static const Color mediumColor = Color(0xffF4A340);
  static const Color lowColor = Color(0xff35B99A);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool isLoading = true;
  String? error;

  Map<String, dynamic> stats = {};
  Map<String, dynamic> riskData = {};
  List<Map<String, dynamic>> activities = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // ============================================================
  // PEMBACA DATA JSON
  // ============================================================

  dynamic firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source[key] != null) {
        return source[key];
      }
    }
    return null;
  }

  Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String statValue(List<String> keys) {
    final value = firstValue(stats, keys);
    return value?.toString() ?? '—';
  }

  double? asNumber(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  double? riskValue(List<String> keys) {
    return asNumber(firstValue(riskData, keys));
  }

  // ============================================================
  // GET /api/bk/dashboard/stats
  // ============================================================

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // TOKEN JWT DARI LOGIN
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // API DASHBOARD GURU BK
      final response = await http
          .get(
            Uri.parse(ApiConfig.bkDashboardStats),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      dynamic result;

      try {
        result = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respons backend bukan JSON yang valid.');
      }

      // CEK STATUS API
      if (response.statusCode == 401) {
        throw Exception('Sesi login sudah kedaluwarsa. Silakan login kembali.');
      }

      if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Endpoint hanya untuk Guru BK.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Map && result['success'] == false)) {
        final message = result is Map ? result['message']?.toString() : null;

        throw Exception(
          message ?? 'Gagal mengambil dashboard (${response.statusCode})',
        );
      }

      // AMBIL DATA UTAMA
      final root = asMap(result);

      if (root == null) {
        throw Exception('Format data dashboard tidak valid.');
      }

      final data = asMap(root['data']) ?? root;

      // STATISTIK:
      // Mendukung data langsung atau nested.
      final nestedStats = asMap(
        firstValue(data, [
          'stats',
          'statistics',
          'statistik',
          'summary',
          'ringkasan',
        ]),
      );

      final parsedStats = {...data, if (nestedStats != null) ...nestedStats};

      // RISIKO:
      // Hanya digunakan jika backend menyediakan angka.
      final parsedRisk =
          asMap(
            firstValue(data, [
              'risk',
              'risks',
              'riskDistribution',
              'risk_distribution',
              'prioritas_risiko',
              'prioritasRisiko',
            ]),
          ) ??
          asMap(
            firstValue(parsedStats, [
              'risk',
              'riskDistribution',
              'risk_distribution',
            ]),
          ) ??
          <String, dynamic>{};

      // AKTIVITAS:
      // Hanya digunakan jika backend mengirim list.
      dynamic rawActivities = firstValue(data, [
        'activities',
        'activity',
        'recentActivities',
        'recent_activities',
        'aktivitas_terbaru',
        'aktivitas',
      ]);

      if (rawActivities == null && nestedStats != null) {
        rawActivities = firstValue(nestedStats, [
          'activities',
          'recentActivities',
          'aktivitas_terbaru',
        ]);
      }

      final parsedActivities = rawActivities is List
          ? rawActivities
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        stats = parsedStats;
        riskData = parsedRisk;
        activities = parsedActivities;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
      });
    } on http.ClientException {
      if (!mounted) return;

      setState(() {
        error = 'Tidak dapat terhubung ke server API.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // HEADER
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
                'Pantau laporan siswa',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10),
            ],
          ),
          child: IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
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
                  'Selamat datang, Guru BK 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pantau kondisi siswa dan tindak lanjuti '
                  'laporan yang membutuhkan perhatian.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff55736D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          Icon(Icons.health_and_safety_outlined, size: 48, color: primaryColor),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIK CARD
  // ============================================================

  Widget buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
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
            child: Icon(icon, size: 21, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xff1E2926),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID STATISTIK
  // ============================================================

  Widget buildStatisticGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 320
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 165,
          children: [
            buildStatCard(
              title: 'Total Laporan',
              value: statValue([
                'total_laporan',
                'totalLaporan',
                'total_reports',
                'totalReports',
                'total',
              ]),
              subtitle: 'Semua laporan',
              icon: Icons.description_outlined,
              iconBackground: lightGreen,
              iconColor: primaryColor,
            ),

            buildStatCard(
              title: 'Sedang Ditangani',
              value: statValue([
                'sedang_ditangani',
                'sedangDitangani',
                'diproses',
                'in_progress',
                'inProgress',
                'processing',
                'total_diproses',
              ]),
              subtitle: 'Sedang diproses',
              icon: Icons.hourglass_bottom_rounded,
              iconBackground: const Color(0xffFFF4E1),
              iconColor: const Color(0xffF59E0B),
            ),

            buildStatCard(
              title: 'Selesai',
              value: statValue([
                'selesai',
                'total_selesai',
                'totalSelesai',
                'completed',
                'resolved',
              ]),
              subtitle: 'Telah diselesaikan',
              icon: Icons.check_circle_outline_rounded,
              iconBackground: const Color(0xffE8F1FF),
              iconColor: const Color(0xff3B82F6),
            ),

            buildStatCard(
              title: 'Risiko Tinggi',
              value: statValue([
                'risiko_tinggi',
                'risikoTinggi',
                'high_risk',
                'highRisk',
                'total_risiko_tinggi',
              ]),
              subtitle: 'Butuh perhatian',
              icon: Icons.warning_amber_rounded,
              iconBackground: const Color(0xffFDECEC),
              iconColor: const Color(0xffEF4444),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LEGEND RISIKO
  // ============================================================

  Widget riskLegend({
    required Color color,
    required String label,
    required double value,
    required double total,
  }) {
    final percentage = total == 0 ? 0.0 : (value / total) * 100;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 3),
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GRAFIK PRIORITAS RISIKO
  // ============================================================

  Widget buildRiskCard() {
    final tinggi = riskValue(['tinggi', 'high', 'highRisk', 'high_risk']);

    final sedang = riskValue(['sedang', 'medium', 'mediumRisk', 'medium_risk']);

    final rendah = riskValue(['rendah', 'low', 'lowRisk', 'low_risk']);

    // Grafik membutuhkan data risiko yang lengkap.
    if (tinggi == null || sedang == null || rendah == null) {
      return emptyCard('Distribusi risiko belum tersedia dari API.');
    }

    if (tinggi < 0 || sedang < 0 || rendah < 0) {
      return emptyCard('Data distribusi risiko tidak valid.');
    }

    final total = tinggi + sedang + rendah;

    if (total <= 0) {
      return emptyCard('Belum ada data risiko untuk ditampilkan.');
    }

    final chart = SizedBox(
      width: 135,
      height: 135,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 3,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              sections: [
                if (tinggi > 0)
                  PieChartSectionData(
                    value: tinggi,
                    color: highColor,
                    radius: 17,
                    title: '',
                  ),
                if (sedang > 0)
                  PieChartSectionData(
                    value: sedang,
                    color: mediumColor,
                    radius: 17,
                    title: '',
                  ),
                if (rendah > 0)
                  PieChartSectionData(
                    value: rendah,
                    color: lowColor,
                    radius: 17,
                    title: '',
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
              const Text(
                'Laporan',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Column(
      children: [
        riskLegend(
          color: highColor,
          label: 'Tinggi',
          value: tinggi,
          total: total,
        ),
        const SizedBox(height: 14),
        riskLegend(
          color: mediumColor,
          label: 'Sedang',
          value: sedang,
          total: total,
        ),
        const SizedBox(height: 14),
        riskLegend(
          color: lowColor,
          label: 'Rendah',
          value: rendah,
          total: total,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 430) {
            return Column(
              children: [chart, const SizedBox(height: 22), legend],
            );
          }

          return Row(
            children: [
              chart,
              const SizedBox(width: 20),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // AKTIVITAS TERBARU
  // ============================================================

  Widget buildActivityCard() {
    if (activities.isEmpty) {
      return emptyCard('Aktivitas terbaru belum tersedia dari API.');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < activities.length; i++) ...[
            buildActivityItem(activities[i]),

            if (i != activities.length - 1)
              const Divider(height: 1, color: Color(0xffEEEEEE)),
          ],
        ],
      ),
    );
  }

  Widget buildActivityItem(Map<String, dynamic> item) {
    final title =
        firstValue(item, ['title', 'judul', 'type', 'jenis'])?.toString() ??
        'Aktivitas laporan';

    final description =
        firstValue(item, [
          'description',
          'deskripsi',
          'message',
          'pesan',
        ])?.toString() ??
        '';

    final date =
        firstValue(item, [
          'createdAt',
          'created_at',
          'time',
          'waktu',
        ])?.toString() ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: darkPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REUSABLE CARD DI DALAM FILE INI
  // ============================================================

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.grey, size: 38),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
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
          onRefresh: loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 110),
            children: [
              buildHeader(),

              const SizedBox(height: 25),

              buildWelcomeCard(),

              const SizedBox(height: 28),

              const Text(
                'Ringkasan Laporan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1F2937),
                ),
              ),

              const SizedBox(height: 15),

              // LOADING
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),

              // ERROR
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xffFDECEC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
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

              if (!isLoading && error == null) ...[
                // STATISTIK
                buildStatisticGrid(),

                const SizedBox(height: 28),

                // RISIKO
                const Text(
                  'Prioritas Risiko',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1F2937),
                  ),
                ),

                const SizedBox(height: 15),

                buildRiskCard(),

                const SizedBox(height: 28),

                // AKTIVITAS
                const Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1F2937),
                  ),
                ),

                const SizedBox(height: 15),

                buildActivityCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
