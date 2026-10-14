import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class AddEditSekolahPage extends StatefulWidget {
  final Map<String, dynamic>? school;

  const AddEditSekolahPage({super.key, this.school});

  @override
  State<AddEditSekolahPage> createState() => _AddEditSekolahPageState();
}

class _AddEditSekolahPageState extends State<AddEditSekolahPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  final formKey = GlobalKey<FormState>();
  late final TextEditingController namaController;
  late final TextEditingController alamatController;
  late final TextEditingController npsnController;

  String? selectedJenjang;
  bool saving = false;

  final List<String> daftarJenjang = [
    'SD/MI/Sederajat',
    'SMP/MTs/Sederajat',
    'SMA/SMK/MA/Sederajat',
  ];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(
      text: '${widget.school?['nama_sekolah'] ?? widget.school?['nama'] ?? ''}',
    );
    alamatController = TextEditingController(
      text: '${widget.school?['alamat'] ?? ''}',
    );
    npsnController = TextEditingController(
      text: '${widget.school?['npsn'] ?? ''}',
    );
    selectedJenjang = widget.school?['jenjang'];
    if (selectedJenjang != null && !daftarJenjang.contains(selectedJenjang)) {
      selectedJenjang = null;
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    alamatController.dispose();
    npsnController.dispose();
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

  Future<void> saveSchool() async {
    if (saving) return;
    if (!formKey.currentState!.validate()) return;

    if (selectedJenjang == null) {
      showMessage('Jenjang sekolah wajib dipilih');
      return;
    }

    setState(() => saving = true);

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final isEdit = widget.school != null;
      final rawId = widget.school?['id'] ?? widget.school?['school_id'] ?? widget.school?['id_sekolah'];
      final id = isEdit ? (int.tryParse('$rawId') ?? rawId) : null;

      if (isEdit && (id == null || '$id'.isEmpty)) {
        throw Exception('ID sekolah tidak valid (ID: $rawId).');
      }

      final url = isEdit
          ? Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools/$id')
          : Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools');

      final payload = {
        'nama_sekolah': namaController.text.trim(),
        'alamat': alamatController.text.trim(),
        'npsn': npsnController.text.trim(),
        'jenjang': selectedJenjang,
      };

      final response = await (isEdit
              ? http.put(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(payload))
              : http.post(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(payload)))
          .timeout(const Duration(seconds: 20));

      dynamic result;
      try {
        result = response.body.isEmpty ? {} : jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respons backend bukan JSON valid');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(result is Map ? result['message']?.toString() ?? 'Gagal menyimpan data sekolah' : 'Gagal menyimpan data sekolah');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ====================================================
  // FITUR HAPUS SEKOLAH (DELETE)
  // ====================================================
  Future<void> deleteSchool() async {
    if (saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Sekolah'),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${namaController.text.trim()}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => saving = true);

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final rawId = widget.school?['id'] ?? widget.school?['school_id'] ?? widget.school?['id_sekolah'];
      final id = int.tryParse('$rawId') ?? rawId;

      if (id == null || '$id'.isEmpty) {
        throw Exception('ID sekolah tidak valid.');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/superadmin/schools/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal menghapus sekolah (${response.statusCode})');
      }

      if (!mounted) return;
      Navigator.pop(context, true); // Kembali ke halaman list dengan membawa status true (refresh)
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
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
    final isEdit = widget.school != null;

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
          isEdit ? 'Edit Sekolah' : 'Tambah Sekolah',
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
                const Text('Nama Sekolah', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: namaController,
                  decoration: inputDecoration('Masukkan nama sekolah', Icons.school_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nama sekolah wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                const Text('Jenjang Sekolah', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedJenjang,
                  isExpanded: true,
                  decoration: inputDecoration('Pilih jenjang sekolah', Icons.layers_outlined),
                  items: daftarJenjang.map((jenjang) {
                    return DropdownMenuItem<String>(
                      value: jenjang,
                      child: Text(jenjang),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedJenjang = value;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Pilih jenjang sekolah terlebih dahulu' : null,
                ),
                const SizedBox(height: 20),
                const Text('Alamat Sekolah', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: alamatController,
                  maxLines: 2,
                  decoration: inputDecoration('Masukkan alamat sekolah', Icons.location_on_outlined),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                const Text('NPSN', style: TextStyle(color: darkPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: npsnController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: inputDecoration('Masukkan 8 digit NPSN', Icons.numbers),
                  validator: (value) {
                    if (!RegExp(r'^\d{8}$').hasMatch(value?.trim() ?? '')) {
                      return 'NPSN harus 8 digit angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                // TOMBOL SIMPAN / PERBARUI
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: saving ? null : saveSchool,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(isEdit ? 'Perbarui Sekolah' : 'Simpan Sekolah', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),

                // TOMBOL HAPUS (Hanya tampil jika dalam mode Edit)
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : deleteSchool,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus Sekolah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
}