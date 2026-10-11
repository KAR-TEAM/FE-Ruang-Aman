
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/admin/admin_sekolah.dart';

class SekolahSuperadmin extends StatefulWidget {
  const SekolahSuperadmin({super.key});

  @override
  State<SekolahSuperadmin> createState() =>
      _SekolahSuperadminState();
}

class _SekolahSuperadminState
    extends State<SekolahSuperadmin> {
  // WARNA RUANGAMAN
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // CONTROLLER
  final searchController = TextEditingController();

  // STATE
  List<Map<String, dynamic>> schools = [];
  bool loading = false;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // MENAMPILKAN PESAN
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

  // MEMBACA JWT LANGSUNG
  Future<String> getToken() async {
    final token = await storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Token tidak ditemukan. Silakan login kembali.',
      );
    }

    return token;
  }

  // PARSING RESPONS
  dynamic parseResponse(http.Response response) {
    dynamic result;

    try {
      result = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons backend bukan JSON valid');
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
      final message = result is Map
          ? result['message']?.toString()
          : null;

      throw Exception(
        message ??
            'Operasi gagal (${response.statusCode})',
      );
    }

    return result;
  }

  // AMBIL DAFTAR SEKOLAH DARI JSON
  List<Map<String, dynamic>> extractSchools(dynamic result) {
    dynamic data = result;

    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }

    if (data is Map) {
      data = data['schools'] ??
          data['sekolah'] ??
          data['results'] ??
          data['items'];
    }

    if (data is! List) {
      throw Exception(
        'Format daftar sekolah tidak sesuai dengan API.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ====================================================
  // GET SEKOLAH DAN PENCARIAN
  // ====================================================
  Future<void> loadSchools({String keyword = ''}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getToken();

      final uri = keyword.trim().isEmpty
          ? Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools',
            )
          : Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/search',
            ).replace(
              queryParameters: {
                'query': keyword.trim(),
              },
            );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

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

  // ====================================================
  // TAMBAH DAN EDIT SEKOLAH
  // ====================================================
  Future<void> schoolForm({
    Map<String, dynamic>? school,
  }) async {
    if (saving) return;

    final namaController = TextEditingController(
      text: '${school?['nama_sekolah'] ?? school?['nama'] ?? ''}',
    );

    final alamatController = TextEditingController(
      text: '${school?['alamat'] ?? ''}',
    );

    final npsnController = TextEditingController(
      text: '${school?['npsn'] ?? ''}',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            school == null
                ? 'Tambah Sekolah'
                : 'Edit Sekolah',
            style: const TextStyle(
              color: darkPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Sekolah',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Nama sekolah wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: alamatController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Sekolah',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Alamat wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: npsnController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'NPSN',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!RegExp(r'^\d{8}$')
                            .hasMatch(value?.trim() ?? '')) {
                          return 'NPSN harus 8 digit angka';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(dialogContext, {
                  'nama_sekolah': namaController.text.trim(),
                  'alamat': alamatController.text.trim(),
                  'npsn': npsnController.text.trim(),
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      namaController.dispose();
      alamatController.dispose();
      npsnController.dispose();
    });

    if (result == null || !mounted) return;

    final id = school == null
        ? null
        : int.tryParse('${school['id']}');

    if (school != null && id == null) {
      showMessage('ID sekolah tidak valid');
      return;
    }

    setState(() => saving = true);

    try {
      final token = await getToken();

      final url = id == null
          ? Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools',
            )
          : Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools/$id',
            );

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final http.Response response;

      if (id == null) {
        response = await http
            .post(
              url,
              headers: headers,
              body: jsonEncode(result),
            )
            .timeout(const Duration(seconds: 20));
      } else {
        response = await http
            .put(
              url,
              headers: headers,
              body: jsonEncode(result),
            )
            .timeout(const Duration(seconds: 20));
      }

      parseResponse(response);

      if (!mounted) return;

      showMessage(
        id == null
            ? 'Sekolah berhasil ditambahkan'
            : 'Sekolah berhasil diperbarui',
        success: true,
      );

      await loadSchools(
        keyword: searchController.text,
      );
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ====================================================
  // HAPUS SEKOLAH
  // ====================================================
  Future<void> deleteSchool(
    Map<String, dynamic> school,
  ) async {
    if (saving) return;

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
          'Apakah kamu yakin ingin menghapus '
          '${school['nama_sekolah'] ?? school['nama'] ?? 'sekolah ini'}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => saving = true);

    try {
      final token = await getToken();

      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/schools/$id',
            ),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      parseResponse(response);

      if (!mounted) return;

      showMessage(
        'Sekolah berhasil dihapus',
        success: true,
      );

      await loadSchools(
        keyword: searchController.text,
      );
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ====================================================
  // CARD SEKOLAH
  // ====================================================
  Widget schoolCard(Map<String, dynamic> school) {
    final nama =
        '${school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'NPSN: ${school['npsn'] ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 5),

          Text(
            '${school['alamat'] ?? '-'}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const Divider(height: 25),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving || loading
                      ? null
                      : () => schoolForm(school: school),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving || loading
                      ? null
                      : () => deleteSchool(school),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 17,
                  ),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================
  // BUILD
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () => loadSchools(
            keyword: searchController.text,
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20, 25, 20, 30,
            ),
            children: [
              // HEADER
              const Text(
                'Manajemen Sekolah',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Kelola sekolah yang terdaftar',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 22),

              // PENCARIAN
              TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  loadSchools(keyword: value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama sekolah...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      searchController.clear();
                      loadSchools();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // TAMBAH SEKOLAH
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving || loading
                      ? null
                      : () => schoolForm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.all(15),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Sekolah'),
                ),
              ),

              const SizedBox(height: 10),

              // BUAT ADMIN SEKOLAH
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminSekolahPage(),
                            ),
                          );

                          if (!mounted) return;

                          await loadSchools(
                            keyword: searchController.text,
                          );
                        },
                  icon: const Icon(
                    Icons.person_add_alt_outlined,
                  ),
                  label: const Text('Buat Admin Sekolah'),
                ),
              ),

              const SizedBox(height: 18),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                ),

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              if (!loading && error == null && schools.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 35),
                  child: Center(
                    child: Text(
                      'Belum ada data sekolah',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              if (!loading && error == null)
                ...schools.map(schoolCard),
            ],
          ),
        ),
      ),
    );
  }
}
