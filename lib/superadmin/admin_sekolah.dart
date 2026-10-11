import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/superadmin/add_admin_sekolah.dart'; // Halaman Page untuk tambah admin

class AdminSekolahPage extends StatefulWidget {
  const AdminSekolahPage({super.key});

  @override
  State<AdminSekolahPage> createState() => _AdminSekolahPageState();
}

class _AdminSekolahPageState extends State<AdminSekolahPage> {
  // ============================================================
  // WARNA TEMA RUANGAMAN
  // ============================================================
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ============================================================
  // STATE
  // ============================================================
  List<Map<String, dynamic>> schools = [];
  bool loadingSchools = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  // ============================================================
  // MENAMPILKAN PESAN / SNACKBAR
  // ============================================================
  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // AMBIL SEMUA SEKOLAH (GET /api/superadmin/schools)[cite: 5]
  // ============================================================
  Future<void> loadSchools() async {
    if (!mounted) return;

    setState(() {
      loadingSchools = true;
      error = null;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      dynamic result;
      try {
        result = response.body.isEmpty ? {} : jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respons backend bukan JSON valid');
      }

      if (response.statusCode == 401) {
        throw Exception('Sesi login tidak valid atau kedaluwarsa.');
      }

      if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya Superadmin yang diizinkan.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(result is Map ? result['message']?.toString() ?? 'Gagal mengambil daftar sekolah' : 'Gagal mengambil daftar sekolah');
      }

      dynamic data = result;
      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }
      if (data is Map) {
        data = data['schools'] ?? data['sekolah'] ?? data['items'] ?? data['results'];
      }

      if (data is! List) {
        throw Exception('Format daftar sekolah dari API tidak sesuai.');
      }

      final list = data.whereType<Map>().map((school) => Map<String, dynamic>.from(school)).toList();

      if (!mounted) return;

      setState(() {
        schools = list;
        loadingSchools = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa server backend.';
        loadingSchools = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loadingSchools = false;
      });
    }
  }

  // ============================================================
  // BUILD UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final validSchools = schools.where((school) => int.tryParse('${school['id']}') != null).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: darkPrimary,
            size: 20,
          ),
        ),
        title: const Text(
          'Kelola Admin Sekolah',
          style: TextStyle(
            color: darkPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadSchools,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KARTU INFORMASI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_outlined,
                        color: primaryColor,
                        size: 38,
                      ),
                      SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Kelola dan tambahkan admin yang akan mengelola sekolah di dalam sistem RuangAman.',
                          style: TextStyle(
                            color: darkPrimary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Status Sekolah & Sistem',
                  style: TextStyle(
                    color: darkPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // KONTEN STATUS SEKOLAH
                if (loadingSchools)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                else if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: loadSchools,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Sekolah Terdaftar: ${validSchools.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: darkPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // TOMBOL NAVIGASI KE HALAMAN TAMBAH ADMIN SEKOLAH (PAGE)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loadingSchools
                        ? null
                        : () async {
                            // Navigasi ke halaman AddAdminSekolahPage (Page penuh)
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddAdminSekolahPage(),
                              ),
                            );

                            // Jika berhasil disimpan, muat ulang data sekolah
                            if (result == true && mounted) {
                              loadSchools();
                              showMessage('Admin sekolah berhasil ditambahkan', success: true);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Tambah Admin Sekolah Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}