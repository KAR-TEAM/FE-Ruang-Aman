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

  // Ambil Data Siswa dari API Backend
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

  // Filter Lokal Berdasarkan Kelas & Search Input
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
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: _buildHeader(),
              ),

              const SizedBox(height: 20),

              // SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearch(),
              ),

              const SizedBox(height: 17),

              // FILTER KELAS (Dibuat dinamis dari data atau list kelas standar)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _kelasButton("Semua"),
                    _kelasButton("XI IPA 1"),
                    _kelasButton("XI IPA 2"),
                    _kelasButton("XI IPS 1"),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // JUMLAH SISWA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      isLoading ? "Memuat data siswa..." : "${filtered.length} siswa ditemukan",
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // LIST SISWA / LOADING / ERROR
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
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 1100),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                                        itemCount: filtered.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          return _siswaCard(filtered[index]);
                                        },
                                      ),
                                    ),
                                  );
                                },
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
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Kelola dan pantau data siswa",
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            color: primaryColor,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 10, offset: const Offset(0, 3)),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xffE5EBE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: primaryColor, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _kelasButton(String kelas) {
    final active = selectedKelas == kelas;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => selectedKelas = kelas),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? primaryColor : const Color(0xffE5EBE8)),
          ),
          child: Text(
            kelas,
            style: TextStyle(
              decoration: TextDecoration.none,
              color: active ? Colors.white : const Color(0xff66706D),
              fontSize: 11.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetailSiswa(data),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffEEF2F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(7), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(17)),
                child: Center(
                  child: Text(
                    data["inisial"] ?? "S",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data["nama"] ?? "-",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff263330)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(15)),
                          child: Text(
                            status,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "NIS ${data["nis"] ?? '-'}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          data["kelas"] ?? '-',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xffF7FCFA), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            "${data["laporan"] ?? 0} laporan",
                            style: const TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Icon(Icons.chevron_right_rounded, color: Color(0xffAAB4B0), size: 23),
              ),
            ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final status = data["status"] ?? "Aman";
        final statusColor = _getStatusColor(status);
        final statusBackground = _getStatusBackground(status);

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 15, 22, 30),
          decoration: const BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
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
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(20)),
                    child: Center(
                      child: Text(
                        data["inisial"] ?? "S",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data["nama"] ?? "-", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkPrimary)),
                        const SizedBox(height: 5),
                        Text("${data["nis"] ?? '-'} • ${data["kelas"] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text("Informasi Siswa", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkPrimary)),
              const SizedBox(height: 15),
              _detailRow(icon: Icons.badge_outlined, label: "NIS", value: data["nis"] ?? '-'),
              _detailRow(icon: Icons.school_outlined, label: "Kelas", value: data["kelas"] ?? '-'),
              _detailRow(icon: Icons.email_outlined, label: "Email", value: data["email"] ?? '-'),
              _detailRow(icon: Icons.person_outline, label: "Jenis Kelamin", value: data["jenisKelamin"] ?? '-'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Text("Status", style: TextStyle(fontSize: 12, color: Colors.grey))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(15)),
                    child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.description_outlined, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Riwayat Laporan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff34403D))),
                          const SizedBox(height: 3),
                          Text("${data["laporan"] ?? 0} laporan terkait siswa", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 35, height: 35,
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
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xff34403D))),
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
          const Text("Coba kata pencarian atau kelas lain.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}