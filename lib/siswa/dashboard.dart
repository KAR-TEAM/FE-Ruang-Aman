import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/siswa/reporting/select_reports.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkColor = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  String nama = 'Siswa';
  String kelas = '';

  bool loading = true;
  static bool showMotivation = true; 

  String? error;

  Map<String, dynamic> dashboard = {};
  Map<String, dynamic>? laporanTerakhir;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  dynamic firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null) return value;
    }
    return null;
  }

  String displayValue(Map<String, dynamic> source, List<String> keys, {String fallback = '—'}) {
    final value = firstValue(source, keys);
    if (value == null) return fallback;
    return value.toString();
  }

  Map<String, dynamic>? toMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<void> loadStudentProfile() async {
    final savedUser = await storage.read(key: 'auth_user');
    if (savedUser == null || savedUser.isEmpty) return;

    final decoded = jsonDecode(savedUser);
    final user = toMap(decoded);
    if (user == null || !mounted) return;

    setState(() {
      nama = displayValue(user, ['nama', 'name', 'fullName'], fallback: 'Siswa');
      kelas = displayValue(user, ['kelas', 'class', 'nama_kelas'], fallback: '');
    });
  }

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await loadStudentProfile();

      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.dashboardSiswa),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      dynamic result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respons backend bukan JSON yang valid.');
      }

      if (response.statusCode == 401) {
        throw Exception('Sesi login telah kedaluwarsa. Silakan login kembali.');
      }
      if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Endpoint ini khusus siswa.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300 || (result is Map && result['success'] == false)) {
        final message = result is Map ? result['message']?.toString() : null;
        throw Exception(message ?? 'Gagal mengambil dashboard (${response.statusCode})');
      }

      dynamic rawData = result;
      if (result is Map && result.containsKey('data')) {
        rawData = result['data'];
      }

      final data = toMap(rawData);
      if (data == null) {
        throw Exception('Format data dashboard tidak sesuai.');
      }

      final statistics = toMap(firstValue(data, ['stats', 'statistics', 'statistik', 'summary']));
      final parsedDashboard = statistics == null ? data : { ...data, ...statistics };

      final latest = firstValue(data, [
        'laporan_terbaru', 
        'laporanTerakhir', 
        'latestReport', 
        'latest_report', 
        'lastReport',
        'reports',
        'laporan'
      ]);
      
      Map<String, dynamic>? parsedLatest;

      if (latest is Map) {
        parsedLatest = Map<String, dynamic>.from(latest);
      } else if (latest is List && latest.isNotEmpty) {
        parsedLatest = toMap(latest.first);
      }

      if (!mounted) return;

      setState(() {
        dashboard = parsedDashboard;
        laporanTerakhir = parsedLatest;

        final siswa = toMap(firstValue(data, ['siswa', 'student', 'user', 'profile']));
        if (siswa != null) {
          nama = displayValue(siswa, ['nama', 'name', 'fullName'], fallback: nama);
          kelas = displayValue(siswa, ['kelas', 'class', 'nama_kelas'], fallback: kelas);
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

  String get jumlahDibuat => displayValue(dashboard, ['total_laporan', 'totalLaporan', 'total_reports', 'totalReports', 'total', 'dibuat']);
  String get jumlahDiproses => displayValue(dashboard, ['diproses', 'sedang_diproses', 'dalam_proses', 'total_diproses', 'totalDiproses', 'in_progress', 'inProgress', 'processing']);
  String get jumlahSelesai => displayValue(dashboard, ['selesai', 'total_selesai', 'totalSelesai', 'completed', 'resolved']);

  String formatTanggal(dynamic raw) {
    if (raw == null) return '-';
    final input = raw.toString();
    final date = DateTime.tryParse(input);
    if (date == null) return input;

    final local = date.toLocal();
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final jam = local.hour.toString().padLeft(2, '0');
    final menit = local.minute.toString().padLeft(2, '0');

    return '${local.day} ${bulan[local.month - 1]} ${local.year}, $jam:$menit';
  }

  Color statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('selesai') || normalized.contains('resolved') || normalized.contains('completed')) {
      return const Color(0xff16A66A);
    }
    if (normalized.contains('proses') || normalized.contains('tangan') || normalized.contains('progress') || normalized.contains('process')) {
      return const Color(0xff3B82F6);
    }
    return const Color(0xffF59E0B);
  }

  Widget summaryCard({required IconData icon, required String title, required String value, required Color color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.person_outline_rounded, size: 26, color: primaryColor),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $nama! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkColor),
              ),
              const SizedBox(height: 3),
              Text(
                kelas.isEmpty ? 'RuangAman' : 'Kelas $kelas',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: loading ? null : loadDashboard,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.refresh_rounded, size: 20, color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMotivationCard() {
    if (!showMotivation) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD6EFE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setiap cerita itu penting.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                ),
                SizedBox(height: 4),
                Text(
                  'Terima kasih sudah berani bersuara untuk lingkungan yang lebih aman. 🌱',
                  style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xff34403D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => showMotivation = false),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: darkColor.withAlpha(150)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLatestReport() {
    final laporan = laporanTerakhir;

    if (laporan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: const [
            Icon(Icons.description_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Belum ada laporan aktif',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final jenis = displayValue(laporan, ['jenis', 'jenis_kejadian', 'jenisLaporan', 'kategori', 'category', 'judul', 'title'], fallback: 'Laporan Kejadian');
    final rawStatus = displayValue(laporan, ['status', 'status_laporan', 'statusLaporan'], fallback: 'BARU');
    final waktu = formatTanggal(firstValue(laporan, ['created_at', 'createdAt', 'tanggal_laporan', 'tanggal', 'created']));
    final warnaStatus = statusColor(rawStatus);

    return InkWell(
      onTap: () => showDetail(laporan),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Laporan Terbaru',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: warnaStatus.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rawStatus,
                    style: TextStyle(fontSize: 10, color: warnaStatus, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              jenis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  waktu,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showDetail(Map<String, dynamic> item) async {
    final jenis = item["jenis"] ?? item["jenis_kejadian"] ?? item["judul"] ?? "Laporan Kejadian";
    final tanggal = item["tanggal_kejadian"] ?? item["created_at"] ?? "-";
    final waktu = item["waktu_kejadian"] ?? "-";
    final lokasi = item["lokasi"] ?? "-";
    final kronologi = item["kronologi"] ?? "Tidak ada keterangan kronologi.";
    final status = item["status"] ?? "BARU";
    final buktiUrl = item["bukti_url"];
    final followups = item["followups"];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 25),
            decoration: const BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Detail Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor(status).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 10, color: statusColor(status), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    jenis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        detailRow('Tanggal', '${tanggal.toString().split('T')[0]} ($waktu WIB)'),
                        detailRow('Lokasi', lokasi),
                        const Divider(height: 24),
                        const Text(
                          'Kronologi Kejadian',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffE2ECE9)),
                          ),
                          child: Text(
                            kronologi,
                            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xff34403D)),
                          ),
                        ),

                        if (followups is List && followups.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Tindak Lanjut & Penanganan Guru BK',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                          ),
                          const SizedBox(height: 8),
                          ...followups.map((f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tindakan: ${f['tindakan'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkColor)),
                                const SizedBox(height: 4),
                                Text('Catatan: ${f['catatan'] ?? '-'}', style: const TextStyle(fontSize: 11.5, color: Color(0xff34403D))),
                              ],
                            ),
                          )),
                        ],

                        if (buktiUrl != null && buktiUrl.toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Bukti Lampiran Foto',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkColor),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => Dialog(
                                  backgroundColor: Colors.black.withOpacity(0.9),
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: Image.network(
                                            buktiUrl.toString().startsWith('http') ? buktiUrl : '${ApiConfig.baseUrl}/$buktiUrl',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                          onPressed: () => Navigator.pop(dialogContext),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(4),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Image.network(
                                      buktiUrl.toString().startsWith('http') ? buktiUrl : '${ApiConfig.baseUrl}/$buktiUrl',
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 100,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text('Gagal memuat gambar bukti', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text('Ketuk untuk memperbesar', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            children: [
              buildHeader(),
              const SizedBox(height: 20),
              buildMotivationCard(),
              if (showMotivation) const SizedBox(height: 18),
              const Text(
                'Ringkasan Laporan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDEAEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              if (!loading && error == null)
                Row(
                  children: [
                    summaryCard(icon: Icons.description_outlined, title: 'Dibuat', value: jumlahDibuat, color: primaryColor),
                    summaryCard(icon: Icons.hourglass_top_rounded, title: 'Diproses', value: jumlahDiproses, color: const Color(0xff3B82F6)),
                    summaryCard(icon: Icons.check_circle_outline_rounded, title: 'Selesai', value: jumlahSelesai, color: const Color(0xff16A66A)),
                  ],
                ),
              const SizedBox(height: 25),
              const Text(
                'Laporan Terakhir',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkColor),
              ),
              const SizedBox(height: 12),
              if (!loading && error == null) buildLatestReport(),
              if (error != null)
                const Text(
                  'Laporan terakhir belum dapat dimuat.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelectReportsPage()),
          );
          if (!mounted) return;
          await loadDashboard();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}