import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';

class LaporanMasukPage extends StatefulWidget {
  const LaporanMasukPage({super.key});

  @override
  State<LaporanMasukPage> createState() => _LaporanMasukPageState();
}

class _LaporanMasukPageState extends State<LaporanMasukPage> {
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

  String selectedFilter = 'Semua';
  bool showSearch = false;
  bool loading = true;
  String? error;

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> laporan = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPER LOKAL UNTUK MEMBACA DATA
  // ============================================================

  dynamic getValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data[key] != null) return data[key];
    }
    return null;
  }

  String getText(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '—',
  }) {
    final value = getValue(data, keys);

    if (value == null ||
        value is Map ||
        value is List ||
        value.toString().trim().isEmpty) {
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

  String readableError(Object error) {
    if (error is TimeoutException) {
      return 'Koneksi timeout. Periksa server backend.';
    }

    if (error is http.ClientException) {
      return 'Tidak dapat terhubung ke server.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TOKEN LOGIN
  // ============================================================

  Future<String> getToken() async {
    final token = await storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    return token;
  }

  // ============================================================
  // VALIDASI RESPONSE API
  // ============================================================

  dynamic parseResponse(http.Response response) {
    dynamic result;

    try {
      result = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons backend bukan JSON yang valid.');
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Sesi login sudah kedaluwarsa. '
        'Silakan login kembali.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Akun tidak memiliki izin.');
    }

    if (response.statusCode == 404) {
      throw Exception('Endpoint atau laporan tidak ditemukan.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (result is Map && result['success'] == false)) {
      final message = result is Map ? result['message']?.toString() : null;

      throw Exception(message ?? 'Operasi gagal (${response.statusCode})');
    }

    return result;
  }

  List<Map<String, dynamic>> extractReports(dynamic response) {
    dynamic data = response;

    for (int i = 0; i < 4 && data is Map; i++) {
      final next =
          data['data'] ??
          data['reports'] ??
          data['laporan'] ??
          data['items'] ??
          data['results'] ??
          data['rows'];

      if (next == null) break;
      data = next;
    }

    if (data is! List) {
      throw Exception('Format daftar laporan tidak sesuai dengan API.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // GET /api/bk/reports
  // ============================================================

  Future<void> loadReports({String? priorityFilter}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getToken();

      // Membangun URL dengan query parameter jika filter dipilih
      String url = ApiConfig.bkReports;
      if (priorityFilter != null && priorityFilter != 'Semua') {
        url += '?priority=${Uri.encodeComponent(priorityFilter)}';
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final result = parseResponse(response);
      final reports = extractReports(result);

      if (!mounted) return;

      setState(() {
        laporan = reports;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = readableError(e);
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
  // POST /api/bk/reports/:id/followups
  // ============================================================

  Future<void> saveFollowup({
    required String reportDatabaseId,
    required String catatan,
    required String tindakan,
  }) async {
    final token = await getToken();

    final response = await http
        .post(
          Uri.parse(ApiConfig.bkReportFollowups(reportDatabaseId)),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'catatan': catatan.trim(),
            'tindakan': tindakan.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    parseResponse(response);
  }

  // ============================================================
  // FORM FOLLOW-UP
  // ============================================================

  Future<void> tambahTindakLanjut(Map<String, dynamic> item) async {
    // HARUS ID DATABASE, BUKAN KODE LAPORAN.
    final rawId = item['id'];

    if (rawId == null || rawId.toString().trim().isEmpty) {
      showMessage('ID database laporan tidak tersedia.');
      return;
    }

    final id = rawId.toString();

    final berhasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormFollowupDialog(
        kodeLaporan: reportId(item),
        onSave: (catatan, tindakan) {
          return saveFollowup(
            reportDatabaseId: id,
            catatan: catatan,
            tindakan: tindakan,
          );
        },
      ),
    );

    if (!mounted || berhasil != true) return;

    showMessage('Tindak lanjut berhasil ditambahkan.', success: true);

    await loadReports();
  }

  // ============================================================
  // PEMBACAAN FIELD LAPORAN
  // ============================================================

  String reportId(Map<String, dynamic> item) {
    return getText(item, [
      'kode_laporan',
      'nomor_laporan',
      'report_code',
      'reportCode',
      'kode',
      'id',
    ]);
  }

  String reportTitle(Map<String, dynamic> item) {
    return getText(item, [
      'judul',
      'title',
      'jenis_kejadian',
      'jenis_laporan',
      'jenisLaporan',
      'kategori',
      'category',
    ], fallback: 'Laporan Kejadian');
  }

  String reportRisk(Map<String, dynamic> item) {
    final raw = getText(item, [
      'tingkat_risiko',
      'level_risiko',
      'risk_level',
      'riskLevel',
      'risiko',
      'priority',
    ]);

    switch (raw.trim().toLowerCase()) {
      case 'high':
      case 'tinggi':
        return 'Tinggi';

      case 'medium':
      case 'moderate':
      case 'sedang':
        return 'Sedang';

      case 'low':
      case 'rendah':
        return 'Rendah';

      default:
        return raw;
    }
  }

  String reportStatus(Map<String, dynamic> item) {
    final raw = getText(item, ['status_laporan', 'statusLaporan', 'status']);

    switch (raw.trim().toLowerCase()) {
      case 'new':
      case 'baru':
      case 'pending':
        return 'Baru';

      case 'in_progress':
      case 'in progress':
      case 'processing':
      case 'diproses':
      case 'sedang ditangani':
        return 'Sedang Ditangani';

      case 'resolved':
      case 'completed':
      case 'done':
      case 'selesai':
        return 'Selesai';

      default:
        return raw;
    }
  }

  bool reportIsAnonymous(Map<String, dynamic> item) {
    final value = getValue(item, [
      'is_anonymous',
      'isAnonymous',
      'is_anonim',
      'isAnonim',
      'anonim',
    ]);

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  String reportPelapor(Map<String, dynamic> item) {
    if (reportIsAnonymous(item)) {
      return 'Anonim';
    }

    final pelapor = toMap(
      getValue(item, ['pelapor', 'siswa', 'student', 'user']),
    );

    if (pelapor != null) {
      final nama = getText(pelapor, ['nama', 'name', 'fullName']);

      final kelas = getText(pelapor, [
        'kelas',
        'nama_kelas',
        'class',
      ], fallback: '');

      return kelas.isEmpty ? nama : '$nama ($kelas)';
    }

    return getText(item, [
      'nama_pelapor',
      'namaPelapor',
      'nama_siswa',
      'namaSiswa',
    ], fallback: 'Identitas tidak tersedia');
  }

  String reportDate(Map<String, dynamic> item) {
    final raw = getValue(item, [
      'createdAt',
      'created_at',
      'tanggal_laporan',
      'tanggalLaporan',
      'tanggal',
    ]);

    if (raw == null) return '—';

    final date = DateTime.tryParse(raw.toString());

    if (date == null) return raw.toString();

    final local = date.toLocal();

    const months = [
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

    return '${local.day} ${months[local.month - 1]} '
        '${local.year}, $jam:$menit';
  }

  // ============================================================
  // FILTER DAN PENCARIAN
  // ============================================================

  List<Map<String, dynamic>> get filteredLaporan {
    final keyword = searchController.text.trim().toLowerCase();

    return laporan.where((item) {
      final risiko = reportRisk(item);

      final cocokFilter =
          selectedFilter == 'Semua' ||
          risiko.toLowerCase() == selectedFilter.toLowerCase();

      final text = [
        reportId(item),
        reportTitle(item),
        reportPelapor(item),
        reportStatus(item),
      ].join(' ').toLowerCase();

      return cocokFilter && (keyword.isEmpty || text.contains(keyword));
    }).toList();
  }

  // ============================================================
  // WARNA STATUS DAN RISIKO
  // ============================================================

  Color riskColor(String risk) {
    switch (risk) {
      case 'Tinggi':
        return const Color(0xffEF4444);

      case 'Sedang':
        return const Color(0xffF59E0B);

      case 'Rendah':
        return const Color(0xff16A66A);

      default:
        return Colors.grey;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Baru':
        return const Color(0xff16A66A);

      case 'Sedang Ditangani':
        return const Color(0xff3B82F6);

      case 'Selesai':
        return const Color(0xff66706D);

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER BUTTON
  // ============================================================

  Widget headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: const Color(0xff5D6966)),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton(String label) {
    final active = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => selectedFilter = label);
          loadReports(priorityFilter: label); // Ambil data sesuai filter dari backend
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? primaryColor : const Color(0xffE5EBE8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xff68736F),
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  // ============================================================
  // FILTER BOTTOM SHEET
  // ============================================================

  void showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter Laporan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in ['Semua', 'Tinggi', 'Sedang', 'Rendah'])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      option == 'Tinggi'
                          ? Icons.priority_high_rounded
                          : option == 'Sedang'
                          ? Icons.remove_circle_outline
                          : option == 'Rendah'
                          ? Icons.check_circle_outline
                          : Icons.filter_list,
                      color: option == 'Semua'
                          ? primaryColor
                          : riskColor(option),
                    ),
                    title: Text(
                      option == 'Semua' ? 'Semua Laporan' : 'Risiko $option',
                    ),
                    trailing: selectedFilter == option
                        ? const Icon(Icons.check, color: primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        selectedFilter = option;
                      });
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CARD LAPORAN
  // ============================================================

  Widget laporanCard(Map<String, dynamic> item) {
    final id = reportId(item);
    final judul = reportTitle(item);
    final tanggal = reportDate(item);
    final pelapor = reportPelapor(item);
    final risiko = reportRisk(item);
    final status = reportStatus(item);

    return InkWell(
      onTap: () => showDetail(item),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffEEF2F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(7),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    id,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff263330),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                badge(risiko, riskColor(risiko)),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              judul,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xff263330),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tanggal,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                const Icon(Icons.person_outline, color: Colors.grey, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pelapor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xff66706D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                badge(status, statusColor(status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL LAPORAN
  // ============================================================

  Future<void> showDetail(Map<String, dynamic> item) async {
    final id = reportId(item);
    final judul = reportTitle(item);
    final tanggal = reportDate(item);
    final pelapor = reportPelapor(item);
    final risiko = reportRisk(item);
    final status = reportStatus(item);

    final kronologi = getText(item, [
      'kronologi',
      'deskripsi',
      'description',
      'isi_laporan',
      'cerita',
    ], fallback: '');

    final lokasi = getText(item, [
      'lokasi_kejadian',
      'lokasi',
      'location',
    ], fallback: '');

    // True jika pengguna memilih Tambah Tindak Lanjut.
    final openFollowup = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 15, 22, 25),
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

                  const SizedBox(height: 22),

                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          id,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          judul,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkPrimary,
                          ),
                        ),

                        const SizedBox(height: 22),

                        detailRow('Tanggal', tanggal),
                        detailRow('Pelapor', pelapor),
                        detailRow('Prioritas', risiko),
                        detailRow('Status', status),

                        if (lokasi.isNotEmpty) detailRow('Lokasi', lokasi),

                        if (kronologi.isNotEmpty) ...[
                          const Divider(height: 28),
                          const Text(
                            'Kronologi Kejadian',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            kronologi,
                            style: const TextStyle(fontSize: 13, height: 1.6),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // TOMBOL TAMBAH FOLLOW-UP
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext, true);
                      },
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Tambah Tindak Lanjut'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TUTUP DETAIL
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext, false);
                      },
                      child: const Text('Tutup Detail'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (openFollowup == true) {
      await tambahTindakLanjut(item);
    }
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xff34403D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: primaryColor,
                size: 35,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Laporan tidak ditemukan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Belum ada laporan atau coba filter lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filtered = filteredLaporan;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Laporan Masuk',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                  ),

                  headerButton(
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      if (!loading) loadReports();
                    },
                  ),

                  const SizedBox(width: 8),

                  headerButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      setState(() {
                        showSearch = !showSearch;

                        if (!showSearch) {
                          searchController.clear();
                        }
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  headerButton(
                    icon: Icons.tune_rounded,
                    onTap: showFilterSheet,
                  ),
                ],
              ),
            ),

            // SEARCH
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showSearch
                  ? Padding(
                      key: const ValueKey('search'),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari laporan...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: primaryColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-search')),
            ),

            const SizedBox(height: 20),

            // FILTER TAB
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  filterButton('Semua'),
                  filterButton('Tinggi'),
                  filterButton('Sedang'),
                  filterButton('Rendah'),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // JUMLAH LAPORAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loading
                      ? 'Memuat laporan...'
                      : error != null
                      ? 'Gagal memuat laporan'
                      : '${filtered.length} laporan ditemukan',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // DAFTAR LAPORAN
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: loadReports,
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(25),
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: loadReports,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      )
                    : filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [SizedBox(height: 280, child: emptyState())],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return laporanCard(filtered[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// FORM FOLLOW-UP DALAM FILE YANG SAMA
// ====================================================================

class _FormFollowupDialog extends StatefulWidget {
  final String kodeLaporan;
  final Future<void> Function(String catatan, String tindakan) onSave;

  const _FormFollowupDialog({required this.kodeLaporan, required this.onSave});

  @override
  State<_FormFollowupDialog> createState() => _FormFollowupDialogState();
}

class _FormFollowupDialogState extends State<_FormFollowupDialog> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);

  final formKey = GlobalKey<FormState>();

  final catatanController = TextEditingController();
  final tindakanController = TextEditingController();

  bool saving = false;
  String? error;

  @override
  void dispose() {
    catatanController.dispose();
    tindakanController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.onSave(
        catatanController.text.trim(),
        tindakanController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        error =
            'Koneksi timeout. Periksa apakah catatan '
            'sudah tersimpan sebelum mengirim ulang.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Tambah Tindak Lanjut',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkPrimary,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KODE LAPORAN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffE9F7F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Laporan: ${widget.kodeLaporan}',
                    style: const TextStyle(
                      color: darkPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CATATAN
                const Text(
                  'Catatan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: catatanController,
                  enabled: !saving,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan hasil penanganan...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Catatan wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // TINDAKAN
                const Text(
                  'Tindakan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: tindakanController,
                  enabled: !saving,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan tindakan yang dilakukan...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tindakan wajib diisi';
                    }
                    return null;
                  },
                ),

                // ERROR API
                if (error != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xffFDECEC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),

        ElevatedButton(
          onPressed: saving ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
