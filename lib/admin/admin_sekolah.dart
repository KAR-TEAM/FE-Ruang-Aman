
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';

class AdminSekolahPage extends StatefulWidget {
  const AdminSekolahPage({super.key});

  @override
  State<AdminSekolahPage> createState() =>
      _AdminSekolahPageState();
}

class _AdminSekolahPageState extends State<AdminSekolahPage> {
  // ============================================================
  // WARNA RUANGAMAN
  // ============================================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // ============================================================
  // CONTROLLER
  // ============================================================

  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> schools = [];

  int? selectedSchoolId;

  bool loadingSchools = true;
  bool saving = false;
  bool obscurePassword = true;

  String? error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // MENAMPILKAN PESAN
  // ============================================================

  void showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // AMBIL SEMUA SEKOLAH
  // GET /api/superadmin/schools
  // ============================================================

  Future<void> loadSchools() async {
    if (!mounted) return;

    setState(() {
      loadingSchools = true;
      error = null;
    });

    try {
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      dynamic result;

      try {
        result = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respons backend bukan JSON valid',
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Sesi login tidak valid atau kedaluwarsa.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses ditolak. Hanya Superadmin yang diizinkan.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Map && result['success'] == false)) {
        throw Exception(
          result is Map
              ? result['message']?.toString() ??
                  'Gagal mengambil daftar sekolah'
              : 'Gagal mengambil daftar sekolah',
        );
      }

      // MENDUKUNG BEBERAPA FORMAT RESPONSE
      dynamic data = result;

      if (data is Map && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is Map) {
        data = data['schools'] ??
            data['sekolah'] ??
            data['items'] ??
            data['results'];
      }

      if (data is! List) {
        throw Exception(
          'Format daftar sekolah dari API tidak sesuai.',
        );
      }

      final list = data
          .whereType<Map>()
          .map((school) =>
              Map<String, dynamic>.from(school))
          .toList();

      if (!mounted) return;

      setState(() {
        schools = list;
        selectedSchoolId = null;
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
          loadingSchools = false;
        });
      }
    }
  }

  // ============================================================
  // MEMBUAT ADMIN SEKOLAH
  // POST /api/superadmin/admin-schools
  // ============================================================

  Future<void> createAdmin() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedSchoolId == null) {
      showMessage('Silakan pilih sekolah');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan. Silakan login kembali.',
        );
      }

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/admin-schools',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'sekolah_id': selectedSchoolId,
              'nama': namaController.text.trim(),
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      dynamic result;

      try {
        result = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respons backend bukan JSON valid',
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Sesi login tidak valid atau kedaluwarsa.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses ditolak. Akun bukan Superadmin.',
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Map && result['success'] == false)) {
        throw Exception(
          result is Map
              ? result['message']?.toString() ??
                  'Gagal membuat Admin Sekolah'
              : 'Gagal membuat Admin Sekolah',
        );
      }

      if (!mounted) return;

      showMessage(
        'Admin sekolah berhasil dibuat',
        success: true,
      );

      // KEMBALI KE HALAMAN SEBELUMNYA
      Navigator.pop(context, true);
    } on TimeoutException {
      showMessage(
        'Koneksi timeout. Periksa server backend.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final validSchools = schools
        .where(
          (school) =>
              int.tryParse('${school['id']}') != null,
        )
        .toList();

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
          'Buat Admin Sekolah',
          style: TextStyle(
            color: darkPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20, 15, 20, 35,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WELCOME CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      ContainerPlaceholder(),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Data Sekolah',
                  style: TextStyle(
                    color: darkPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                // PILIH SEKOLAH
                if (loadingSchools)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  )
                else if (error != null)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: loadSchools,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<int>(
                    value: selectedSchoolId,
                    isExpanded: true,
                    decoration: inputDecoration(
                      'Pilih Sekolah',
                      Icons.school_outlined,
                    ),
                    items: validSchools.map((school) {
                      final id = int.parse('${school['id']}');

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '${school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah $id'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSchoolId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Pilih sekolah terlebih dahulu';
                      }
                      return null;
                    },
                  ),

                if (!loadingSchools &&
                    error == null &&
                    validSchools.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Belum ada sekolah terdaftar.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                const SizedBox(height: 28),

                // DATA ADMIN
                const Text(
                  'Data Admin',
                  style: TextStyle(
                    color: darkPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: namaController,
                  decoration: inputDecoration(
                    'Nama Lengkap Admin',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: inputDecoration(
                    'Email Admin',
                    Icons.email_outlined,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Format email tidak valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: inputDecoration(
                    'Password',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // BUTTON SIMPAN
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        saving || loadingSchools || validSchools.isEmpty
                            ? null
                            : createAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor:
                          Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Buat Admin Sekolah',
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

// ============================================================
// WELCOME CARD CONTENT
// ============================================================

class ContainerPlaceholder extends StatelessWidget {
  const ContainerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          color: Color(0xff009B88),
          size: 38,
        ),
        SizedBox(width: 13),
        Expanded(
          child: Text(
            'Daftarkan admin yang akan mengelola sekolah '
            'di dalam sistem RuangAman.',
            style: TextStyle(
              color: Color(0xff124F4A),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
