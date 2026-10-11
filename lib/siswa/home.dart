
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/siswa/melapor/pilih_laporan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ==============================================
  // WARNA
  // ==============================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkColor = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // ==============================================
  // STATE
  // ==============================================

  String nama = 'Siswa';
  String kelas = '';

  bool loading = true;
  String? error;

  Map<String, dynamic> dashboard = {};
  Map<String, dynamic>? laporanTerakhir;

  // ==============================================
  // INIT
  // ==============================================

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // ==============================================
  // MEMBACA DATA DARI MAP
  // ==============================================

  dynamic firstValue(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String displayValue(
    Map<String, dynamic> source,
    List<String> keys, {
    String fallback = '—',
  }) {
    final value = firstValue(source, keys);

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  Map<String, dynamic>? toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  // ==============================================
  // AMBIL NAMA SISWA DARI SESSION LOGIN
  // ==============================================

  Future<void> loadStudentProfile() async {
    final savedUser = await storage.read(
      key: 'auth_user',
    );

    if (savedUser == null || savedUser.isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedUser);
    final user = toMap(decoded);

    if (user == null || !mounted) {
      return;
    }

    setState(() {
      nama = displayValue(
        user,
        ['nama', 'name', 'fullName'],
        fallback: 'Siswa',
      );

      kelas = displayValue(
        user,
        ['kelas', 'class', 'nama_kelas'],
        fallback: '',
      );
    });
  }

  // ==============================================
  // GET DASHBOARD SISWA
  // ==============================================

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // BACA PROFIL LOKAL
      await loadStudentProfile();

      // BACA JWT
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      // REQUEST BACKEND
      final response = await http
          .get(
            Uri.parse(ApiConfig.dashboardSiswa),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      // PARSING RESPONSE
      dynamic result;

      try {
        result = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respons backend bukan JSON yang valid.',
        );
      }

      // CEK ERROR HTTP
      if (response.statusCode == 401) {
        throw Exception(
          'Sesi login telah kedaluwarsa. Silakan login kembali.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses ditolak. Endpoint ini khusus siswa.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Map && result['success'] == false)) {
        final message = result is Map
            ? result['message']?.toString()
            : null;

        throw Exception(
          message ??
              'Gagal mengambil dashboard (${response.statusCode})',
        );
      }

      // MENGAMBIL DATA UTAMA
      dynamic rawData = result;

      if (result is Map && result.containsKey('data')) {
        rawData = result['data'];
      }

      final data = toMap(rawData);

      if (data == null) {
        throw Exception(
          'Format data dashboard tidak sesuai.',
        );
      }

      // ==============================================
      // DATA STATISTIK
      // ==============================================

      final statistics = toMap(
        firstValue(
          data,
          ['stats', 'statistics', 'statistik', 'summary'],
        ),
      );

      final parsedDashboard = statistics == null
          ? data
          : {
              ...data,
              ...statistics,
            };

      // ==============================================
      // LAPORAN TERAKHIR
      // ==============================================

      final latest = firstValue(
        data,
        [
          'laporan_terakhir',
          'laporanTerakhir',
          'latestReport',
          'latest_report',
          'lastReport',
        ],
      );

      Map<String, dynamic>? parsedLatest;

      if (latest is Map) {
        parsedLatest = Map<String, dynamic>.from(latest);
      } else if (latest is List && latest.isNotEmpty) {
        parsedLatest = toMap(latest.first);
      }

      // FORMAT ALTERNATIF:
      // jika backend memberikan array reports/laporan
      if (parsedLatest == null) {
        final reports = firstValue(
          data,
          ['reports', 'laporan', 'recentReports'],
        );

        if (reports is List && reports.isNotEmpty) {
          // Diasumsikan array sudah diurutkan terbaru
          // oleh backend.
          parsedLatest = toMap(reports.first);
        }
      }

      if (!mounted) return;

      setState(() {
        dashboard = parsedDashboard;
        laporanTerakhir = parsedLatest;

        // Opsional: informasi profil yang
        // ikut dikirim oleh endpoint dashboard
        final siswa = toMap(
          firstValue(
            data,
            ['siswa', 'student', 'user', 'profile'],
          ),
        );

        if (siswa != null) {
          nama = displayValue(
            siswa,
            ['nama', 'name', 'fullName'],
            fallback: nama,
          );

          kelas = displayValue(
            siswa,
            ['kelas', 'class', 'nama_kelas'],
            fallback: kelas,
          );
        }
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ==============================================
  // AMBIL JUMLAH LAPORAN
  // ==============================================

  String get jumlahDibuat {
    return displayValue(
      dashboard,
      [
        'total_laporan',
        'totalLaporan',
        'total_reports',
        'totalReports',
        'total',
        'dibuat',
      ],
    );
  }

  String get jumlahDiproses {
    return displayValue(
      dashboard,
      [
        'diproses',
        'sedang_diproses',
        'dalam_proses',
        'total_diproses',
        'totalDiproses',
        'in_progress',
        'inProgress',
        'processing',
      ],
    );
  }

  String get jumlahSelesai {
    return displayValue(
      dashboard,
      [
        'selesai',
        'total_selesai',
        'totalSelesai',
        'completed',
        'resolved',
      ],
    );
  }

  // ==============================================
  // FORMAT TANGGAL
  // ==============================================

  String formatTanggal(dynamic raw) {
    if (raw == null) return '-';

    final input = raw.toString();
    final date = DateTime.tryParse(input);

    if (date == null) return input;

    final local = date.toLocal();

    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final jam = local.hour.toString().padLeft(2, '0');
    final menit = local.minute.toString().padLeft(2, '0');

    return '${local.day} ${bulan[local.month - 1]} '
        '${local.year}, $jam:$menit';
  }

  // ==============================================
  // CARD RINGKASAN
  // ==============================================

  Widget summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // HEADER
  // ==============================================

  Widget buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            Icons.person,
            size: 32,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $nama! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kelas.isEmpty ? 'RuangAman' : 'Kelas $kelas',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: loading ? null : loadDashboard,
          tooltip: 'Perbarui dashboard',
          icon: const Icon(
            Icons.refresh_rounded,
            size: 28,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  // ==============================================
  // MOTIVATION CARD
  // ==============================================

  Widget buildMotivationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Setiap cerita penting.\n'
              'Terima kasih sudah\n'
              'berani bercerita. 🌱',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff3B5F57),
              ),
            ),
          ),
          Icon(
            Icons.eco,
            size: 55,
            color: Colors.green.shade400,
          ),
        ],
      ),
    );
  }

  // ==============================================
  // BUTTON BUAT LAPORAN
  // ==============================================

  Widget buildReportButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PilihLaporanPage(),
          ),
        );

        // Refresh setelah kembali dari halaman laporan.
        if (!mounted) return;

        await loadDashboard();
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xff35B99A),
              primaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Center(
          child: Text(
            '+  Buat Laporan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // STATUS LAPORAN
  // ==============================================

  Color statusColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized.contains('selesai') ||
        normalized.contains('resolved') ||
        normalized.contains('completed')) {
      return Colors.green;
    }

    if (normalized.contains('proses') ||
        normalized.contains('tangan') ||
        normalized.contains('progress') ||
        normalized.contains('process')) {
      return Colors.blue;
    }

    return Colors.orange;
  }

  // ==============================================
  // LAPORAN TERAKHIR
  // ==============================================

  Widget buildLatestReport() {
    final laporan = laporanTerakhir;

    if (laporan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 38,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              'Belum ada laporan terakhir',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final nomor = displayValue(
      laporan,
      [
        'nomor_laporan',
        'kode_laporan',
        'kodeLaporan',
        'report_code',
        'reportCode',
        'nomor',
        'id',
      ],
    );

    final jenis = displayValue(
      laporan,
      [
        'jenis_laporan',
        'jenisLaporan',
        'kategori',
        'category',
        'judul',
        'title',
        'jenis',
      ],
      fallback: 'Laporan',
    );

    final rawStatus = displayValue(
      laporan,
      [
        'status_laporan',
        'statusLaporan',
        'status',
      ],
      fallback: 'Belum diketahui',
    );

    final waktu = formatTanggal(
      firstValue(
        laporan,
        [
          'createdAt',
          'created_at',
          'tanggal_laporan',
          'tanggal',
          'created',
        ],
      ),
    );

    final warnaStatus = statusColor(rawStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nomor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            jenis,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Text(
                waktu,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: warnaStatus.withAlpha(20),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  rawStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: warnaStatus,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================
  // BUILD
  // ==============================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20, 25, 20, 90,
            ),
            children: [
              // HEADER
              buildHeader(),

              const SizedBox(height: 25),

              // MOTIVASI
              buildMotivationCard(),

              const SizedBox(height: 20),

              // TOMBOL LAPORAN
              buildReportButton(),

              const SizedBox(height: 25),

              // RINGKASAN LAPORAN
              const Text(
                'Ringkasan Laporan Saya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),

              const SizedBox(height: 15),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                ),

              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDECEC),
                    borderRadius: BorderRadius.circular(14),
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

              if (!loading && error == null)
                Row(
                  children: [
                    summaryCard(
                      icon: Icons.description,
                      title: 'Dibuat',
                      value: jumlahDibuat,
                      color: Colors.teal,
                    ),
                    summaryCard(
                      icon: Icons.hourglass_bottom,
                      title: 'Diproses',
                      value: jumlahDiproses,
                      color: Colors.orange,
                    ),
                    summaryCard(
                      icon: Icons.check_circle,
                      title: 'Selesai',
                      value: jumlahSelesai,
                      color: Colors.green,
                    ),
                  ],
                ),

              const SizedBox(height: 25),

              const Text(
                'Laporan Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),

              const SizedBox(height: 12),

              if (!loading && error == null)
                buildLatestReport(),

              if (error != null)
                const Text(
                  'Laporan terakhir belum dapat dimuat.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
