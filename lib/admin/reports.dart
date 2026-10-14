import 'dart:async';
import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  bool loading = true;
  bool showSearch = false;
  String? error;
  List<Map<String, dynamic>> reports = [];
  String selectedStatus = 'Semua';

  // STATE FILTER TAHUN ('Semua' atau tahun tertentu misal '2026')
  String selectedYear = 'Semua';
  List<String> availableYears = ['Semua'];

  final TextEditingController searchController = TextEditingController();

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

  Future<void> loadReports() async {
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

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/adminsekolah/getallreports'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          data = decoded['data'];
        }

        final parsedReports = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        // Ekstraksi tahun secara dinamis dari data laporan yang masuk
        Set<String> yearsSet = {'Semua'};
        for (var item in parsedReports) {
          final rawDate = item['tanggal'];
          if (rawDate != null) {
            final date = DateTime.tryParse(rawDate.toString());
            if (date != null) {
              yearsSet.add(date.year.toString());
            }
          }
        }

        List<String> sortedYears = yearsSet.toList()
          ..sort((a, b) => b.compareTo(a)); // Urutkan dari tahun terbaru

        if (mounted) {
          setState(() {
            reports = parsedReports;
            availableYears = sortedYears;
            // Jika tahun yang sedang dipilih tidak ada di list tahun baru, reset ke 'Semua'
            if (!availableYears.contains(selectedYear)) {
              selectedYear = 'Semua';
            }
            loading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data laporan (${response.statusCode})');
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

  // FITUR EKSPOR LAPORAN (SESUAI DENGAN FILTER TAHUN YANG AKTIF)
  Future<void> exportRekapLaporan() async {
    try {
      final dataToExport =
          filteredReports; // Menggunakan data yang sudah terfilter (termasuk filter tahun)

      if (dataToExport.isEmpty) {
        showMessage(
          'Tidak ada data laporan pada tahun/filter ini untuk diekspor.',
        );
        return;
      }

      StringBuffer csvContent = StringBuffer();
      // Tambahkan informasi header periode tahun pada file atau judul
      csvContent.writeln(
        'REKAPITULASI LAPORAN SEKOLAH (PERIODE: $selectedYear)',
      );
      csvContent.writeln(
        'ID Laporan,Jenis Kejadian,Nama Pelapor,Email Pelapor,Tanggal,Waktu,Lokasi,Priority,Kronologi,Status',
      );

      for (var item in dataToExport) {
        final id = item['report_id'] ?? '-';
        final jenis =
            '"${(item['jenis_kejadian'] ?? 'Laporan Kejadian').replaceAll('"', '""')}"';
        final nama =
            '"${(item['nama_pelapor'] ?? 'Siswa').replaceAll('"', '""')}"';
        final email =
            '"${(item['email_pelapor'] ?? '-').replaceAll('"', '""')}"';
        final tanggal = formatTanggal(item['tanggal']);
        final waktu = item['waktu_kejadian'] ?? '-';
        final lokasi = '"${(item['lokasi'] ?? '-').replaceAll('"', '""')}"';
        final priority = item['priority'] ?? '-';
        final kronologi =
            '"${(item['kronologi'] ?? '-').replaceAll('"', '""').replaceAll('\n', ' ')}"';
        final status = item['status'] ?? 'BARU';

        csvContent.writeln(
          '$id,$jenis,$nama,$email,$tanggal,$waktu,$lokasi,$priority,$kronologi,$status',
        );
      }

      Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent.toString()));
      final String fileName =
          'Rekap_Laporan_${selectedYear}_${DateTime.now().toIso8601String().split('T')[0]}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (!mounted) return;
      showMessage(
        'Rekap laporan tahun $selectedYear berhasil didownload!',
        success: true,
      );
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mendownload rekap: $e');
    }
  }

  String formatTanggal(dynamic raw) {
    if (raw == null) return '-';
    final input = raw.toString();
    final date = DateTime.tryParse(input);
    if (date == null) return input.split('T')[0];

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
    return '${local.day} ${bulan[local.month - 1]} ${local.year}';
  }

  Color statusColor(String status) {
    final normalized = status.toUpperCase();
    if (normalized.contains('SELESAI')) return const Color(0xff16A66A);
    if (normalized.contains('PROSES') || normalized.contains('DITANGANI'))
      return const Color(0xff3B82F6);
    return const Color(0xffF59E0B);
  }

  Widget badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // LOGIKA FILTER PENGGABUNGAN (STATUS, KEYWORD PENCARIAN, & TAHUN)
  List<Map<String, dynamic>> get filteredReports {
    final keyword = searchController.text.trim().toLowerCase();

    return reports.where((item) {
      // 1. Filter Status
      final status = (item['status'] ?? '').toString();
      final cocokStatus =
          selectedStatus == 'Semua' ||
          status.toUpperCase() == selectedStatus.toUpperCase();

      // 2. Filter Tahun
      bool cocokTahun = true;
      if (selectedYear != 'Semua') {
        final rawDate = item['tanggal'];
        if (rawDate != null) {
          final date = DateTime.tryParse(rawDate.toString());
          cocokTahun = (date != null && date.year.toString() == selectedYear);
        } else {
          cocokTahun = false;
        }
      }

      // 3. Filter Keyword Pencarian
      final jenis = (item['jenis_kejadian'] ?? '').toString().toLowerCase();
      final namaPelapor = (item['nama_pelapor'] ?? '').toString().toLowerCase();
      final lokasi = (item['lokasi'] ?? '').toString().toLowerCase();
      final matchKeyword =
          keyword.isEmpty ||
          jenis.contains(keyword) ||
          namaPelapor.contains(keyword) ||
          lokasi.contains(keyword);

      return cocokStatus && cocokTahun && matchKeyword;
    }).toList();
  }

  void showReportDetail(Map<String, dynamic> item) {
    final jenis = item['jenis_kejadian'] ?? 'Laporan Kejadian';
    final namaPelapor = item['nama_pelapor'] ?? 'Siswa';
    final emailPelapor = item['email_pelapor'] ?? '-';
    final tanggal = formatTanggal(item['tanggal']);
    final waktu = item['waktu_kejadian'] ?? '-';
    final lokasi = item['lokasi'] ?? '-';
    final prioritas = item['priority'] ?? '-';
    final kronologi = item['kronologi'] ?? 'Tidak ada keterangan kronologi.';
    final status = item['status'] ?? 'BARU';
    final colorStatus = statusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
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
                  const Text(
                    'Detail Informasi Laporan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  badge(status, colorStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                jenis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    detailRow('Nama Pelapor', namaPelapor),
                    detailRow('Email Pelapor', emailPelapor),
                    detailRow('Tanggal Kejadian', tanggal),
                    detailRow('Waktu Kejadian', '$waktu WIB'),
                    detailRow('Lokasi', lokasi),
                    detailRow('Prioritas', prioritas),
                    const Divider(height: 24),
                    const Text(
                      'Kronologi Kejadian',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffE2ECE9)),
                      ),
                      child: Text(
                        kronologi,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Color(0xff34403D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: darkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredReports;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoring Laporan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rekapitulasi dan pemantauan kasus sekolah',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  headerButton(
                    icon: Icons.download_rounded,
                    onTap: exportRekapLaporan,
                    tooltip: 'Ekspor Rekap Tahun $selectedYear',
                  ),
                  const SizedBox(width: 8),
                  headerButton(icon: Icons.refresh_rounded, onTap: loadReports),
                  const SizedBox(width: 8),
                  headerButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      setState(() {
                        showSearch = !showSearch;
                        if (!showSearch) searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showSearch
                  ? Padding(
                      key: const ValueKey('search-box-reports'),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari jenis, pelapor, atau lokasi...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-search-reports')),
            ),
            const SizedBox(height: 16),

            // FILTER TAHUN (DROPDOWN / PILIHAN TAHUN)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Periode Tahun:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: darkPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffE2ECE9)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedYear,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: darkPrimary,
                        ),
                        items: availableYears.map((String year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: Text(year),
                          );
                        }).toList(),
                        onChanged: (String? newYear) {
                          if (newYear != null) {
                            setState(() {
                              selectedYear = newYear;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // FILTER STATUS CHIPS
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  filterChip('Semua'),
                  filterChip('BARU'),
                  filterChip('SEDANG DITANGANI'),
                  filterChip('SELESAI'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loading
                      ? 'Memuat data...'
                      : '${filtered.length} laporan ditemukan (Tahun: $selectedYear)',
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
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : error != null
                    ? Center(
                        child: Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada laporan ditemukan pada periode ini',
                          style: TextStyle(color: Colors.grey, fontSize: 12.5),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final jenis =
                              item['jenis_kejadian'] ?? 'Laporan Kejadian';
                          final status = item['status']?.toString() ?? 'BARU';
                          final tanggal = formatTanggal(item['tanggal']);
                          final namaPelapor = item['nama_pelapor'] ?? 'Siswa';
                          final lokasi = item['lokasi'] ?? '-';
                          final colorStatus = statusColor(status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => showReportDetail(item),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: colorStatus.withAlpha(15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.assignment_outlined,
                                          color: colorStatus,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              jenis,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Pelapor: $namaPelapor • $lokasi',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tanggal: $tanggal',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff34403D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      badge(status, colorStatus),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget headerButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: darkPrimary),
        ),
      ),
    );
  }

  Widget filterChip(String label) {
    final active = selectedStatus.toLowerCase() == label.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => selectedStatus = label),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? primaryColor : const Color(0xffE2ECE9),
            ),
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
}
