import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int selectedTab = 0;
  final List<String> tabs = ["Semua", "Diproses", "Selesai"];

  List<dynamic> laporanList = [];
  bool isLoading = true;
  String errorMessage = '';

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchLaporan();
  }

  // ==========================================
  // AMBIL DATA LAPORAN DARI API
  // ==========================================
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

        // Menyesuaikan berbagai format respons JSON dari backend
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

  @override
  Widget build(BuildContext context) {
    // Filter laporan berdasarkan tab yang dipilih
    List<dynamic> filteredData = laporanList.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      if (selectedTab == 0) return true;
      if (selectedTab == 1) {
        return status != 'selesai'; // Kategori diproses / baru
      }
      return status == 'selesai';
    }).toList();

    return Container(
      color: const Color(0xffF7FCFA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 40,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Laporan Saya",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xff124F4A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xff009B88)),
                    onPressed: fetchLaporan,
                    tooltip: 'Muat Ulang',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TAB FILTER
              Row(
                children: List.generate(tabs.length, (index) {
                  bool active = selectedTab == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xff009B88) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // KONTEN UTAMA (LOADING, ERROR, ATAU LIST)
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff009B88),
                        ),
                      )
                    : errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  errorMessage,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: fetchLaporan,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff009B88),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : filteredData.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada laporan.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: fetchLaporan,
                                color: const Color(0xff009B88),
                                child: ListView.builder(
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

  // WIDGET KARTU LAPORAN
  Widget laporanCard(Map<String, dynamic> item) {
    final status = item["status"]?.toString() ?? "BARU";
    bool selesai = status.toLowerCase() == "selesai";

    final id = item["id"]?.toString() ?? "-";
    final judul = item["jenis_kejadian"] ?? item["judul"] ?? "Laporan";
    final tanggal = item["tanggal_kejadian"] ?? item["created_at"] ?? "-";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id.length > 8 ? "ID: ${id.substring(0, 8)}..." : id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff009B88),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff124F4A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggal.toString(),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selesai ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: selesai ? Colors.green.shade800 : Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}