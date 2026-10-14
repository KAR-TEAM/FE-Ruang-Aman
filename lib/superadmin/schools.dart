import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/superadmin/add_edit_sekolah.dart';

class SekolahSuperadmin extends StatefulWidget {
  const SekolahSuperadmin({super.key});

  @override
  State<SekolahSuperadmin> createState() => _SekolahSuperadminState();
}

class _SekolahSuperadminState extends State<SekolahSuperadmin> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  final searchController = TextEditingController();
  String? selectedFilterJenjang;
  Timer? _debounce;

  List<Map<String, dynamic>> schools = [];
  bool loading = false;
  String? error;

  final List<String> daftarJenjangFilter = [
    'Semua Jenjang',
    'SD/MI/Sederajat',
    'SMP/MTs/Sederajat',
    'SMA/SMK/MA/Sederajat',
  ];

  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
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
      result = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons backend bukan JSON valid');
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login tidak valid atau kedaluwarsa.');
    }

    if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Hanya Superadmin yang diizinkan.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || (result is Map && result['success'] == false)) {
      final message = result is Map ? result['message']?.toString() : null;
      throw Exception(message ?? 'Operasi gagal (${response.statusCode})');
    }

    return result;
  }

  List<Map<String, dynamic>> extractSchools(dynamic result) {
    dynamic data = result;
    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }
    if (data is Map) {
      data = data['schools'] ?? data['sekolah'] ?? data['results'] ?? data['items'];
    }
    if (data is! List) {
      throw Exception('Format daftar sekolah tidak sesuai dengan API.');
    }
    return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> loadSchools() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getToken();
      final keyword = searchController.text.trim();

      final queryParams = <String, String>{};
      if (keyword.isNotEmpty) {
        queryParams['query'] = keyword;
      }
      if (selectedFilterJenjang != null && selectedFilterJenjang != 'Semua Jenjang') {
        queryParams['jenjang'] = selectedFilterJenjang!;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/superadmin/search')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      final result = parseResponse(response);
      final list = extractSchools(result);

      if (!mounted) return;

      setState(() {
        schools = list;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa backend.';
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

  Future<void> deleteSchool(Map<String, dynamic> school) async {
    if (loading) return;

    final id = int.tryParse('${school['id']}');
    if (id == null) {
      showMessage('ID sekolah tidak valid');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Sekolah'),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${school['nama_sekolah'] ?? school['nama'] ?? 'sekolah ini'}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      parseResponse(response);
      if (!mounted) return;

      showMessage('Sekolah berhasil dihapus', success: true);
      await loadSchools();
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ====================================================
  // CARD SEKOLAH (DISESUAIKAN DENGAN GAMBAR REFERENSI)
  // ====================================================
  Widget schoolCard(Map<String, dynamic> school) {
    final nama = '${school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah'}';
    final alamat = '${school['alamat'] ?? '-'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditSekolahPage(school: school)),
          );
          if (result == true && mounted) {
            loadSchools();
            showMessage('Sekolah berhasil diperbarui', success: true);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darkPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alamat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aktif',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadSchools,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              // HEADER
              const Text(
                'Daftar Sekolah',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kelola data sekolah yang terdaftar di RuangAman.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),

              // INPUT PENCARIAN DENGAN AUTO-FETCH
              TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    loadSchools();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama sekolah...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            loadSchools();
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

              const SizedBox(height: 14),

              // FILTER JENJANG (TAMBAHAN)
              DropdownButtonFormField<String>(
                value: selectedFilterJenjang ?? 'Semua Jenjang',
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Filter Jenjang',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                items: daftarJenjangFilter.map((jenjang) {
                  return DropdownMenuItem<String>(
                    value: jenjang,
                    child: Text(jenjang, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFilterJenjang = value;
                  });
                  loadSchools();
                },
              ),

              const SizedBox(height: 20),
              // TOMBOL TAMBAH SEKOLAH
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: loading
                      ? null
                      : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditSekolahPage()),
                          );
                          if (result == true && mounted) {
                            loadSchools();
                            showMessage('Sekolah berhasil ditambahkan', success: true);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Tambah Sekolah',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),

              const SizedBox(height: 14),


              // LOADING
              if (loading)
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
                    color: const Color(0xffFDECEC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // EMPTY STATE
              if (!loading && error == null && schools.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 35),
                  child: Center(
                    child: Text(
                      'Belum ada data sekolah',
                      style: TextStyle(color: Colors.grey, fontSize: 12.5),
                    ),
                  ),
                ),

              // LIST SEKOLAH
              if (!loading && error == null) ...schools.map(schoolCard),
            ],
          ),
        ),
      ),
    );
  }
}