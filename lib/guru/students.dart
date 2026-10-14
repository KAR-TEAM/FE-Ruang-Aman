import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class DataSiswaPage extends StatefulWidget {
  const DataSiswaPage({super.key});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  final TextEditingController searchController = TextEditingController();

  String selectedKelas = "Semua";
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> siswaList = [];

  @override
  void initState() {
    super.initState();
    loadSiswa();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSiswa() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token sesi tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.bkSiswa),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data siswa (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        if (decoded is List) {
          siswaList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  List<String> get availableKelas {
    final setKelas = <String>{};
    for (var siswa in siswaList) {
      final k = siswa["kelas"]?.toString().trim();
      if (k != null && k.isNotEmpty && k != '-') {
        setKelas.add(k);
      }
    }
    final sortedList = setKelas.toList()..sort();
    return ["Semua", ...sortedList];
  }

  List<Map<String, dynamic>> get filteredSiswa {
    final keyword = searchController.text.toLowerCase().trim();

    return siswaList.where((data) {
      final kelasSiswa = data["kelas"]?.toString() ?? '';
      final sesuaiKelas = selectedKelas == "Semua" || kelasSiswa == selectedKelas;

      final nama = data["nama"]?.toString().toLowerCase() ?? '';
      final nis = data["nis"]?.toString().toLowerCase() ?? '';
      final kelas = kelasSiswa.toLowerCase();

      final sesuaiSearch = keyword.isEmpty ||
          nama.contains(keyword) ||
          nis.contains(keyword) ||
          kelas.contains(keyword);

      return sesuaiKelas && sesuaiSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredSiswa;
    final listKelas = availableKelas;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadSiswa,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _buildHeader(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearch(),
              ),
              const SizedBox(height: 17),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: listKelas.length,
                  itemBuilder: (context, index) {
                    return _kelasButton(listKelas[index]);
                  },
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      isLoading ? "Memuat data siswa..." : "${filtered.length} siswa ditemukan",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          )
                        : filtered.isEmpty
                            ? _emptyState()
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _siswaCard(filtered[index]),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Data Siswa",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkPrimary),
              ),
              SizedBox(height: 4),
              Text(
                "Kelola dan pantau data siswa terdaftar",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.people_outline_rounded, color: primaryColor, size: 24),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: "Cari nama, NIS, atau kelas...",
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _kelasButton(String kelas) {
    final active = selectedKelas == kelas;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => selectedKelas = kelas),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? primaryColor : const Color(0xffE2ECE9)),
          ),
          child: Text(
            kelas,
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

  Widget _siswaCard(Map<String, dynamic> data) {
    final status = data["status"] ?? "Aman";
    final statusColor = _getStatusColor(status);
    final statusBackground = _getStatusBackground(status);

    return Container(
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
          onTap: () => _showDetailSiswa(data),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text(
                      data["inisial"] ?? "S",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data["nama"] ?? "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "NIS: ${data["nis"] ?? '-'} • Kelas: ${data["kelas"] ?? '-'}",
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 13, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            "${data["laporan"] ?? 0} laporan terkait",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Perlu Perhatian": return const Color(0xffEF4444);
      case "Pendampingan": return const Color(0xffF59E0B);
      case "Aman": return const Color(0xff16A66A);
      default: return Colors.grey;
    }
  }

  Color _getStatusBackground(String status) {
    switch (status) {
      case "Perlu Perhatian": return const Color(0xffFDEAEA);
      case "Pendampingan": return const Color(0xffFFF4DC);
      case "Aman": return const Color(0xffE5F7EE);
      default: return Colors.grey.shade100;
    }
  }

  void _showDetailSiswa(Map<String, dynamic> data) {
    final jumlahLaporan = data["laporan"] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(18)),
                    child: Center(
                      child: Text(
                        data["inisial"] ?? "S",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data["nama"] ?? "-", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPrimary)),
                        const SizedBox(height: 4),
                        Text("${data["nis"] ?? '-'} • ${data["kelas"] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Informasi Detail", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkPrimary)),
              const SizedBox(height: 12),
              _detailRow(icon: Icons.badge_outlined, label: "NIS", value: data["nis"] ?? '-'),
              _detailRow(icon: Icons.school_outlined, label: "Kelas", value: data["kelas"] ?? '-'),
              _detailRow(icon: Icons.email_outlined, label: "Email", value: data["email"] ?? '-'),
              _detailRow(icon: Icons.person_outline, label: "Jenis Kelamin", value: data["jenisKelamin"] ?? '-'),
              
              // KARTU INFORMASI JUMLAH LAPORAN DI DALAM DETAIL
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: primaryColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Laporan Siswa", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text("$jumlahLaporan Laporan Terkait", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: darkPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 75, height: 75,
            decoration: const BoxDecoration(color: lightGreen, shape: BoxShape.circle),
            child: const Icon(Icons.people_outline_rounded, color: primaryColor, size: 35),
          ),
          const SizedBox(height: 15),
          const Text("Siswa tidak ditemukan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkPrimary)),
          const SizedBox(height: 5),
          const Text("Coba kata pencarian atau filter kelas lain.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}