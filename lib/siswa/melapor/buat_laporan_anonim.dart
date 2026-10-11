import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';

class BuatLaporanAnonimPage extends StatefulWidget {
  const BuatLaporanAnonimPage({super.key});

  @override
  State<BuatLaporanAnonimPage> createState() => _BuatLaporanAnonimPageState();
}

class _BuatLaporanAnonimPageState extends State<BuatLaporanAnonimPage> {
  // ==========================================
  // WARNA RUANGAMAN
  // ==========================================

  static const Color primaryColor = Color(0xff009B88);
  static const Color darkColor = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // ==========================================
  // FORM DAN STATE
  // ==========================================

  final formKey = GlobalKey<FormState>();

  final kronologiController = TextEditingController();

  String? jenis;
  bool isLoading = false;

  final List<String> jenisKejadian = [
    'Perundungan',
    'Kekerasan Verbal',
    'Konflik Teman',
    'Ancaman',
  ];

  @override
  void dispose() {
    kronologiController.dispose();
    super.dispose();
  }

  // ==========================================
  // MENAMPILKAN PESAN
  // ==========================================

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? primaryColor : Colors.red,
      ),
    );
  }

  // ==========================================
  // POST /api/reports/
  // ==========================================

  Future<void> kirimLaporan() async {
    if (isLoading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // AMBIL TOKEN DARI LOGIN
      final token = await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      // ==========================================
      // BODY PAYLOAD
      // ==========================================
      // Nama field masih asumsi sementara.
      // Sesuaikan dengan DTO/controller backend.
      //
      // Tidak mengirim nama, kelas, atau nomor HP.
      // Namun JWT tetap dapat mengidentifikasi
      // pelapor pada sisi server.

      final Map<String, dynamic> payload = {
        'jenis_kejadian': jenis,
        'kronologi': kronologiController.text.trim(),
        'is_anonymous': true,
      };

      // ==========================================
      // REQUEST API
      // ==========================================

      final response = await http
          .post(
            Uri.parse(ApiConfig.createReport),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      // ==========================================
      // PARSING RESPONSE
      // ==========================================

      dynamic result;

      try {
        result = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } catch (_) {
        throw Exception('Respons backend bukan JSON yang valid.');
      }

      // ==========================================
      // VALIDASI STATUS
      // ==========================================

      if (response.statusCode == 401) {
        throw Exception('Sesi login sudah kedaluwarsa.');
      }

      if (response.statusCode == 403) {
        throw Exception('Akses membuat laporan ditolak.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Map && result['success'] == false)) {
        final message = result is Map ? result['message']?.toString() : null;

        throw Exception(
          message ?? 'Gagal mengirim laporan (${response.statusCode})',
        );
      }

      if (!mounted) return;

      showMessage('Laporan berhasil dikirim', success: true);

      // KEMBALI KE HALAMAN SEBELUMNYA
      // Mengembalikan true sebagai tanda berhasil.
      Navigator.pop(context, true);
    } on TimeoutException {
      showMessage(
        'Koneksi timeout. Periksa daftar laporan '
        'sebelum mengirim ulang.',
      );
    } on http.ClientException {
      showMessage('Tidak dapat terhubung ke server API.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // LABEL
  // ==========================================

  Widget formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: darkColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================
  // INPUT DECORATION
  // ==========================================

  InputDecoration inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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

  // ==========================================
  // INFO CARD
  // ==========================================

  Widget buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.visibility_off_outlined,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Text(
              'Mode laporan anonim dipilih. '
              'Identitas pelapor tidak ditampilkan '
              'pada form, tetapi perlindungan '
              'identitas tetap bergantung pada '
              'sistem backend RuangAman.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff355B53),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UPLOAD BUKTI
  // ==========================================

  Widget buildUploadBukti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: primaryColor,
            size: 30,
          ),
          SizedBox(height: 8),
          Text(
            'Upload bukti belum tersedia',
            style: TextStyle(
              color: darkColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Menunggu konfigurasi upload dari backend',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOMBOL KIRIM
  // ==========================================

  Widget buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff35B99A), primaryColor],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(45),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : kirimLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Kirim Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
      ),
    );
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Laporan Anonim',
          style: TextStyle(
            color: darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO ANONIM
                buildInfoCard(),

                const SizedBox(height: 30),

                // JENIS KEJADIAN
                formLabel('Jenis Kejadian'),

                DropdownButtonFormField<String>(
                  value: jenis,
                  isExpanded: true,
                  decoration: inputDecoration(
                    'Pilih jenis kejadian',
                    icon: Icons.category_outlined,
                  ),
                  items: jenisKejadian.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      jenis = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih jenis kejadian';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // KRONOLOGI
                formLabel('Kronologi Kejadian'),

                TextFormField(
                  controller: kronologiController,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  decoration: inputDecoration('Ceritakan apa yang terjadi...'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kronologi wajib diisi';
                    }

                    if (value.trim().length < 10) {
                      return 'Kronologi minimal 10 karakter';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // UPLOAD BUKTI
                formLabel('Upload Bukti (Opsional)'),
                buildUploadBukti(),

                const SizedBox(height: 30),

                // BUTTON
                buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
