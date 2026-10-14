import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';

class AddEditAdminSekolahPage extends StatefulWidget {
  final Map<String, dynamic>? user; // Tambahan parameter untuk mode Edit

  const AddEditAdminSekolahPage({super.key, this.user});

  @override
  State<AddEditAdminSekolahPage> createState() => _AddEditAdminSekolahPageState();
}

class _AddEditAdminSekolahPageState extends State<AddEditAdminSekolahPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  late final TextEditingController namaController;
  late final TextEditingController emailController;
  final passwordController = TextEditingController();
  final searchSchoolController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> schoolResults = [];
  int? selectedSchoolId;
  String? selectedSchoolName;
  
  bool isSearching = false;
  bool saving = false;
  bool obscurePassword = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.user != null;

    namaController = TextEditingController(text: isEdit ? '${widget.user?['nama'] ?? ''}' : '');
    emailController = TextEditingController(text: isEdit ? '${widget.user?['email'] ?? ''}' : '');
    
    if (isEdit) {
      selectedSchoolId = int.tryParse('${widget.user?['sekolah_id'] ?? widget.user?['school_id'] ?? ''}');
      selectedSchoolName = widget.user?['nama_sekolah'] ?? widget.user?['sekolah']?['nama_sekolah'];
      if (selectedSchoolName != null) {
        searchSchoolController.text = selectedSchoolName!;
      }
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    searchSchoolController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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

  Future<void> searchSchools(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        schoolResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() => isSearching = true);

    try {
      final token = await storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/superadmin/search?query=$query'),
        headers: {
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
          data = decoded['schools'] ?? decoded['data'] ?? [];
        }

        if (mounted) {
          setState(() {
            schoolResults = data.map((s) => Map<String, dynamic>.from(s)).toList();
            isSearching = false;
          });
        }
      } else {
        setState(() => isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => isSearching = false);
    }
  }

  Future<void> saveAdminOrUser() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.user != null;

    setState(() => saving = true);

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception('Sesi login tidak ditemukan.');

      final userId = widget.user?['id'];
      final url = isEdit
          ? Uri.parse('${ApiConfig.baseUrl}/api/superadmin/users/$userId')
          : Uri.parse('${ApiConfig.baseUrl}/api/superadmin/admin-schools');

      final Map<String, dynamic> bodyData = {
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
      };

      if (!isEdit) {
        if (selectedSchoolId == null) {
          throw Exception('Silakan pilih sekolah dari daftar pencarian');
        }
        bodyData['sekolah_id'] = selectedSchoolId;
        bodyData['password'] = passwordController.text;
      } else {
        // Jika password diisi saat edit, ikut sertakan
        if (passwordController.text.isNotEmpty) {
          bodyData['password'] = passwordController.text;
        }
      }

      final response = await (isEdit
              ? http.put(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(bodyData))
              : http.post(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(bodyData)))
          .timeout(const Duration(seconds: 20));

      final result = response.body.isEmpty ? {} : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(result['message'] ?? 'Gagal menyimpan data pengguna');
      }

      if (!mounted) return;
      showMessage(isEdit ? 'Pengguna berhasil diperbarui' : 'Admin sekolah berhasil dibuat', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: darkPrimary, size: 20),
        ),
        title: Text(
          isEdit ? 'Edit Pengguna' : 'Tambah Admin Sekolah',
          style: const TextStyle(color: darkPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEdit) ...[
                  const Text(
                    'Cari & Pilih Sekolah',
                    style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: searchSchoolController,
                    decoration: inputDecoration('Ketik nama sekolah...', Icons.search).copyWith(
                      suffixIcon: selectedSchoolId != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  selectedSchoolId = null;
                                  selectedSchoolName = null;
                                  searchSchoolController.clear();
                                  schoolResults.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        searchSchools(value);
                      });
                    },
                  ),
                  if (schoolResults.isNotEmpty && selectedSchoolId == null)
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: schoolResults.length,
                        itemBuilder: (context, index) {
                          final school = schoolResults[index];
                          return ListTile(
                            title: Text(school['nama_sekolah'] ?? school['nama'] ?? ''),
                            subtitle: Text('NPSN: ${school['npsn'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              setState(() {
                                selectedSchoolId = int.tryParse('${school['id']}');
                                selectedSchoolName = school['nama_sekolah'] ?? school['nama'];
                                searchSchoolController.text = selectedSchoolName ?? '';
                                schoolResults.clear();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                const Text('Nama Lengkap', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: namaController,
                  decoration: inputDecoration('Masukkan nama lengkap', Icons.person_outline),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),

                const SizedBox(height: 20),
                const Text('Email', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration('Masukkan email aktif', Icons.email_outlined),
                  validator: (val) {
                    if (val == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                Text(isEdit ? 'Password Baru (Opsional)' : 'Password', style: const TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: inputDecoration(isEdit ? 'Kosongkan jika tidak diubah' : 'Minimal 6 karakter', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (!isEdit && (val == null || val.length < 6)) {
                      return 'Password minimal 6 karakter';
                    }
                    if (isEdit && val != null && val.isNotEmpty && val.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: saving ? null : saveAdminOrUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(isEdit ? 'Perbarui Pengguna' : 'Simpan Admin Sekolah', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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