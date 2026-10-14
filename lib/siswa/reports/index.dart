import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class LaporanPage extends StatefulWidget {
  final Map<String, dynamic>? initialReportToOpen; // Parameter baru untuk menerima data laporan

  const LaporanPage({super.key, this.initialReportToOpen});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  int selectedTab = 0;
  final List<String> tabs = ["Semua", "Diproses", "Selesai"];

  List<dynamic> laporanList = [];
  bool isLoading = true;
  String errorMessage = '';

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchLaporan().then((_) {
      // Jika halaman dibuka dengan membawa data laporan, otomatis buka detailnya
      if (widget.initialReportToOpen != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDetail(widget.initialReportToOpen!);
        });
      }
    });
  }

  Future<void> fetchLaporan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/siswa/my-reports'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map) {
          if (decoded['reports'] is List) {
            data = decoded['reports'];
          } else if (decoded['data'] is List) {
            data = decoded['data'];
          }
        }

        if (mounted) {
          setState(() {
            laporanList = data;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data laporan (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Color statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('selesai') || normalized.contains('resolved')) {
      return const Color(0xff16A66A);
    }
    if (normalized.contains('proses') || normalized.contains('tangan') || normalized.contains('progress')) {
      return const Color(0xff3B82F6);
    }
    return const Color(0xffF59E0B);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredData = laporanList.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      if (selectedTab == 0) return true;
      if (selectedTab == 1) {
        return status != 'selesai';
      }
      return status == 'selesai';
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Laporan Saya",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkPrimary),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 1,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      onTap: fetchLaporan,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.refresh_rounded, size: 20, color: primaryColor),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // TAB FILTER
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(tabs.length, (index) {
                    bool active = selectedTab == index;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => selectedTab = index),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? primaryColor : const Color(0xffE2ECE9)),
                          ),
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? Colors.white : const Color(0xff34403D),
                              fontWeight: active ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // KONTEN UTAMA
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : errorMessage.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: fetchLaporan,
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : filteredData.isEmpty
                            ? const Center(
                                child: Text('Belum ada laporan.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              )
                            : RefreshIndicator(
                                onRefresh: fetchLaporan,
                                color: primaryColor,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 30),
                                  itemCount: filteredData.length,
                                  itemBuilder: (context, index) {
                                    final item = filteredData[index];
                                    return laporanCard(item);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // KARTU LAPORAN SISWA
  Widget laporanCard(Map<String, dynamic> item) {
    final status = item["status"]?.toString() ?? "BARU";
    final warnaStatus = statusColor(status);

    final judul = item["jenis_kejadian"] ?? item["jenis"] ?? item["judul"] ?? "Laporan Kejadian";
    final tanggal = item["tanggal_kejadian"] ?? item["created_at"] ?? "-";
    final lokasi = item["lokasi"] ?? "-";
    final buktiUrl = item["bukti_url"];
    bool hasBukti = buktiUrl != null && buktiUrl.toString().isNotEmpty;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => showDetail(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Laporan Kejadian",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
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
                                  'Ada Lampiran',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: warnaStatus.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 10, color: warnaStatus, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  judul,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkPrimary),
                ),
                const SizedBox(height: 8),
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
                      tanggal.toString().split('T')[0],
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
                if (hasFollowup) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xffEEF2F0)),
                  const SizedBox(height: 12),
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
                              'Sudah Ditindak Lanjut oleh BK',
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BOTTOM SHEET DETAIL LAPORAN SISWA
  Future<void> showDetail(Map<String, dynamic> item) async {
    final jenis = item["jenis_kejadian"] ?? item["jenis"] ?? item["judul"] ?? "Laporan Kejadian";
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkPrimary),
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

                        // Riwayat Tindak Lanjut dari BK
                        if (followups is List && followups.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Tindak Lanjut & Penanganan Guru BK',
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

                        // Bukti Foto / Lampiran dengan Zoom Pop-up
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
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkPrimary),
            ),
          ),
        ],
      ),
    );
  }
}