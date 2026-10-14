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
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

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

  Future<String> getToken() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }
    return token;
  }

  dynamic parseResponse(http.Response response) {
    dynamic result;
    try {
      result = response.body.trim().isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons backend bukan JSON yang valid.');
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah kedaluwarsa. Silakan login kembali.');
    }
    if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Akun tidak memiliki izin.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || (result is Map && result['success'] == false)) {
      final message = result is Map ? result['message']?.toString() : null;
      throw Exception(message ?? 'Operasi gagal (${response.statusCode})');
    }
    return result;
  }

  List<Map<String, dynamic>> extractReports(dynamic response) {
    dynamic data = response;
    for (int i = 0; i < 4 && data is Map; i++) {
      final next = data['data'] ?? data['reports'] ?? data['laporan'] ?? data['items'] ?? data['results'] ?? data['rows'];
      if (next == null) break;
      data = next;
    }
    if (data is! List) {
      throw Exception('Format daftar laporan tidak sesuai dengan API.');
    }
    return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> loadReports({String? priorityFilter}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getToken();
      String url = ApiConfig.bkReports;
      if (priorityFilter != null && priorityFilter != 'Semua') {
        url += '?priority=${Uri.encodeComponent(priorityFilter)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      final result = parseResponse(response);
      final reports = extractReports(result);

      if (!mounted) return;

      setState(() {
        laporan = reports;
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

  Future<void> saveFollowup({
    required String reportDatabaseId,
    required String catatan,
    required String tindakan,
  }) async {
    final token = await getToken();
    final response = await http.post(
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
    ).timeout(const Duration(seconds: 20));

    parseResponse(response);
  }

  Future<void> tambahTindakLanjut(Map<String, dynamic> item) async {
    final rawId = item['id'];
    if (rawId == null || rawId.toString().trim().isEmpty) {
      showMessage('ID database laporan tidak tersedia.');
      return;
    }

    final berhasil = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormFollowupDialog(
        onSave: (catatan, tindakan) {
          return saveFollowup(
            reportDatabaseId: rawId.toString(),
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

  String reportTitle(Map<String, dynamic> item) {
    return item['jenis'] ?? item['jenis_kejadian'] ?? 'Laporan Kejadian';
  }

  String reportRisk(Map<String, dynamic> item) {
    return item['priority'] ?? 'Sedang';
  }

  String reportStatus(Map<String, dynamic> item) {
    return item['status'] ?? 'BARU';
  }

  String reportPelapor(Map<String, dynamic> item) {
    final rawAnon = item['anonymous'];
    final isAnon = rawAnon != null && (rawAnon == true || rawAnon == 1 || rawAnon.toString().toLowerCase() == 'true');
    if (isAnon) return 'Anonim';

    final pelaporObj = item['pelapor'];
    if (pelaporObj is Map) {
      final nama = pelaporObj['nama'] ?? 'Siswa';
      final kelas = pelaporObj['kelas'];
      return kelas != null && kelas.toString().isNotEmpty ? '$nama ($kelas)' : nama;
    }
    return item['nama'] ?? 'Siswa';
  }

  String reportDate(Map<String, dynamic> item) {
    final tgl = item['tanggal_kejadian'] ?? item['created_at'];
    if (tgl == null) return '—';
    return tgl.toString().split('T')[0];
  }

  List<Map<String, dynamic>> get filteredLaporan {
    final keyword = searchController.text.trim().toLowerCase();

    return laporan.where((item) {
      final risiko = reportRisk(item);
      final cocokFilter = selectedFilter == 'Semua' || risiko.toLowerCase() == selectedFilter.toLowerCase();

      final text = [
        reportTitle(item),
        reportPelapor(item),
        reportStatus(item),
        item['lokasi'] ?? '',
        item['kronologi'] ?? '',
      ].join(' ').toLowerCase();

      return cocokFilter && (keyword.isEmpty || text.contains(keyword));
    }).toList();
  }

  Color riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'tinggi':
        return const Color(0xffEF4444);
      case 'sedang':
        return const Color(0xffF59E0B);
      case 'rendah':
        return const Color(0xff16A66A);
      default:
        return Colors.grey;
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'BARU':
        return const Color(0xff16A66A);
      case 'SEDANG DITANGANI':
        return const Color(0xff3B82F6);
      case 'SELESAI':
        return const Color(0xff66706D);
      default:
        return Colors.grey;
    }
  }

  Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: darkPrimary),
        ),
      ),
    );
  }

  Widget filterButton(String label) {
    final active = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => selectedFilter = label);
          loadReports(priorityFilter: label);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? primaryColor : const Color(0xffE2ECE9)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xff34403D),
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget laporanCard(Map<String, dynamic> item) {
    final jenis = reportTitle(item);
    final tanggal = reportDate(item);
    final pelapor = reportPelapor(item);
    final risiko = reportRisk(item);
    final status = reportStatus(item);
    final lokasi = item['lokasi'] ?? '-';
    
    final followups = item['followups'];
    bool hasFollowup = false;
    String lastTindakan = '';

    if (followups is List && followups.isNotEmpty) {
      hasFollowup = true;
      final latest = followups.last;
      if (latest is Map) {
        lastTindakan = latest['tindakan'] ?? '';
      }
    }

    final buktiUrl = item['bukti_url'];
    bool hasBukti = buktiUrl != null && buktiUrl.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => showDetail(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              jenis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkPrimary),
                            ),
                          ),
                          if (hasBukti) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: lightGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.image_outlined, size: 12, color: primaryColor),
                                  SizedBox(width: 3),
                                  Text(
                                    'Lampiran',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    badge(risiko, riskColor(risiko)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lokasi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      tanggal,
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xffEEF2F0)),
                const SizedBox(height: 12),
                if (hasFollowup) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Sudah Ditindak Lanjut',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        if (lastTindakan.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Tindakan: $lastTindakan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: darkPrimary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pelapor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff34403D)),
                      ),
                    ),
                    badge(status, statusColor(status)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showDetail(Map<String, dynamic> item) async {
    final jenis = reportTitle(item);
    final tanggal = reportDate(item);
    final waktu = item['waktu_kejadian'] ?? '-';
    final lokasi = item['lokasi'] ?? '-';
    final kronologi = item['kronologi'] ?? 'Tidak ada keterangan kronologi.';
    final pelapor = reportPelapor(item);
    final risiko = reportRisk(item);
    final status = reportStatus(item);
    final buktiUrl = item['bukti_url'];
    final followups = item['followups'];

    final openFollowup = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
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
                      const Text('Detail Informasi Laporan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      badge(status, statusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    jenis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkPrimary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        detailRow('Pelapor', pelapor),
                        detailRow('Tanggal', '$tanggal ($waktu WIB)'),
                        detailRow('Lokasi', lokasi),
                        detailRow('Prioritas', risiko),
                        const Divider(height: 24),
                        const Text(
                          'Kronologi Kejadian',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
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
                            'Riwayat Tindak Lanjut',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
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
                                Text('Tindakan: ${f['tindakan'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkPrimary)),
                                const SizedBox(height: 4),
                                Text('Catatan: ${f['catatan'] ?? '-'}', style: const TextStyle(fontSize: 11.5, color: Color(0xff34403D))),
                              ],
                            ),
                          )),
                        ],

                        // BUKTI FOTO DENGAN FITUR ZOOM INTERACTIVE VIEWER (SAMA SEPERTI DI SISWA)
                        if (buktiUrl != null && buktiUrl.toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Bukti Lampiran Foto',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
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
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.add_comment_outlined, size: 18),
                      label: const Text('Tambah Tindak Lanjut', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || openFollowup != true) return;
    await tambahTindakLanjut(item);
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
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredLaporan;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Laporan Masuk',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkPrimary),
                    ),
                  ),
                  headerButton(icon: Icons.refresh_rounded, onTap: () => loadReports()),
                  const SizedBox(width: 8),
                  headerButton(
                    icon: Icons.search_rounded,
                    onTap: () => setState(() {
                      showSearch = !showSearch;
                      if (!showSearch) searchController.clear();
                    }),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showSearch
                  ? Padding(
                      key: const ValueKey('search'),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari laporan, lokasi, pelapor...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-search')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loading ? 'Memuat laporan...' : '${filtered.length} laporan ditemukan',
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: loadReports,
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : error != null
                        ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                        : filtered.isEmpty
                            ? const Center(child: Text('Belum ada laporan masuk', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) => laporanCard(filtered[index]),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFollowupDialog extends StatefulWidget {
  final Future<void> Function(String catatan, String tindakan) onSave;

  const _FormFollowupDialog({required this.onSave});

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
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });

    try {
      await widget.onSave(catatanController.text.trim(), tindakanController.text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Tambah Tindak Lanjut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPrimary)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Catatan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: catatanController,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: 'Tuliskan catatan penanganan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Catatan wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                const Text('Tindakan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: tindakanController,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: 'Tuliskan tindakan yang dilakukan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Tindakan wajib diisi' : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: saving ? null : submit,
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }
}