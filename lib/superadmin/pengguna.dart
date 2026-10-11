
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';

class PenggunaSuperadmin extends StatefulWidget {
  const PenggunaSuperadmin({super.key});

  @override
  State<PenggunaSuperadmin> createState() =>
      _PenggunaSuperadminState();
}

class _PenggunaSuperadminState extends State<PenggunaSuperadmin> {
  // WARNA RUANGAMAN
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  // STATE
  List<Map<String, dynamic>> users = [];

  String selectedRole = '';
  bool loading = false;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  // ============================================================
  // MENAMPILKAN PESAN
  // ============================================================
  void showMessage(String message, {bool success = false}) {
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
  // AMBIL JWT LANGSUNG DARI STORAGE
  // ============================================================
  Future<String> getToken() async {
    final token = await storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    return token;
  }

  // ============================================================
  // VALIDASI RESPONSE BACKEND
  // ============================================================
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
      throw Exception('Sesi login tidak valid atau sudah kedaluwarsa.');
    }

    if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Hanya Superadmin yang diizinkan.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (result is Map && result['success'] == false)) {
      final message = result is Map
          ? result['message']?.toString()
          : null;

      throw Exception(
        message ?? 'Operasi gagal (${response.statusCode})',
      );
    }

    return result;
  }

  // ============================================================
  // AMBIL LIST PENGGUNA
  // ============================================================
  List<Map<String, dynamic>> extractUsers(dynamic result) {
    dynamic data = result;

    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }

    if (data is Map) {
      data = data['users'] ??
          data['pengguna'] ??
          data['items'] ??
          data['results'];
    }

    if (data is! List) {
      throw Exception('Format daftar pengguna tidak sesuai dengan API.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // GET DATA PENGGUNA
  // GET /api/superadmin/users?role=
  // ============================================================
  Future<void> loadUsers() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getToken();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/superadmin/users',
      ).replace(
        queryParameters:
            selectedRole.isEmpty ? null : {'role': selectedRole},
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
      final list = extractUsers(result);

      if (!mounted) return;

      setState(() {
        users = list;
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
        setState(() => loading = false);
      }
    }
  }

  // ============================================================
  // EDIT DATA PENGGUNA
  // PUT /api/superadmin/users/:id
  // ============================================================
  Future<void> editUser(Map<String, dynamic> user) async {
    if (saving) return;

    final id = int.tryParse('${user['id']}');

    if (id == null) {
      showMessage('ID pengguna tidak valid');
      return;
    }

    final namaController = TextEditingController(
      text: '${user['nama'] ?? ''}',
    );

    final emailController = TextEditingController(
      text: '${user['email'] ?? ''}',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Pengguna',
            style: TextStyle(
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
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
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
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext, {
                  'nama': namaController.text.trim(),
                  'email': emailController.text.trim(),
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
      emailController.dispose();
    });

    if (result == null || !mounted) return;

    setState(() => saving = true);

    try {
      final token = await getToken();

      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/superadmin/users/$id',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(result),
          )
          .timeout(const Duration(seconds: 20));

      parseResponse(response);

      if (!mounted) return;

      showMessage(
        'Pengguna berhasil diperbarui',
        success: true,
      );

      await loadUsers();
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // ============================================================
  // HAPUS PENGGUNA
  // DELETE /api/superadmin/users/:id
  // ============================================================
  Future<void> deleteUser(Map<String, dynamic> user) async {
    if (saving) return;

    final id = int.tryParse('${user['id']}');

    if (id == null) {
      showMessage('ID pengguna tidak valid');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text(
          'Apakah kamu yakin ingin menghapus '
          '${user['nama'] ?? 'pengguna ini'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
              '${ApiConfig.baseUrl}/api/superadmin/users/$id',
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
        'Pengguna berhasil dihapus',
        success: true,
      );

      await loadUsers();
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // ============================================================
  // CARD PENGGUNA
  // ============================================================
  Widget userCard(Map<String, dynamic> user) {
    final nama = '${user['nama'] ?? '-'}';
    final email = '${user['email'] ?? '-'}';
    final role = '${user['role'] ?? '-'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: primaryColor,
                  size: 25,
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
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Role: $role',
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 25),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving || loading
                      ? null
                      : () => editUser(user),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                  ),
                  label: const Text('Edit'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving || loading
                      ? null
                      : () => deleteUser(user),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
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

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadUsers,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20, 25, 20, 30,
            ),
            children: [
              // HEADER
              const Text(
                'Manajemen Pengguna',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: darkPrimary,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Kelola akun pengguna RuangAman',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 22),

              // FILTER ROLE
              DropdownButtonFormField<String>(
                value: selectedRole,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Filter Pengguna',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '',
                    child: Text('Semua Pengguna'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin Sekolah'),
                  ),
                  DropdownMenuItem(
                    value: 'guru_bk',
                    child: Text('Guru BK'),
                  ),
                  DropdownMenuItem(
                    value: 'siswa',
                    child: Text('Siswa'),
                  ),
                ],
                onChanged: loading
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          selectedRole = value;
                        });

                        loadUsers();
                      },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daftar Pengguna',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: loading ? null : loadUsers,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // LOADING
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
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
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              // EMPTY STATE
              if (!loading && error == null && users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 35),
                  child: Center(
                    child: Text(
                      'Belum ada pengguna',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              // LIST PENGGUNA
              if (!loading && error == null)
                ...users.map(userCard),
            ],
          ),
        ),
      ),
    );
  }
}
