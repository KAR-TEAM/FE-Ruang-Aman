
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';

class BuatLaporanDataPage extends StatefulWidget {
  const BuatLaporanDataPage({super.key});

  @override
  State<BuatLaporanDataPage> createState() =>
      _BuatLaporanDataPageState();
}

class _BuatLaporanDataPageState
    extends State<BuatLaporanDataPage> {
  // WARNA RUANGAMAN
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkColor = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage =
      FlutterSecureStorage();

  final formKey = GlobalKey<FormState>();

  final namaController = TextEditingController();
  final kelasController = TextEditingController();
  final hpController = TextEditingController();
  final kronologiController = TextEditingController();

  String? jenis;
  bool sending = false;
  bool loadingProfile = true;

  final List<String> jenisKejadian = const [
    'Perundungan',
    'Kekerasan Verbal',
    'Konflik Teman',
    'Ancaman',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    namaController.dispose();
    kelasController.dispose();
    hpController.dispose();
    kronologiController.dispose();
    super.dispose();
  }

  // =============================================
  // AMBIL DATA SISWA DARI LOGIN
  // =============================================
  Future<void> loadProfile() async {
    try {
      final savedUser = await storage.read(
        key: 'auth_user',
      );

      if (savedUser != null && savedUser.isNotEmpty) {
        final decoded = jsonDecode(savedUser);

        if (decoded is Map) {
          if (!mounted) return;

          setState(() {
            namaController.text =
                decoded['nama']?.toString() ?? '';

            kelasController.text =
                decoded['kelas']?.toString() ?? '';

            hpController.text = (
              decoded['nomor_hp'] ??
              decoded['no_hp'] ??
              decoded['phone'] ??
              ''
            ).toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal membaca profil lokal: $e');
    } finally {
      if (mounted) {
        setState(() => loadingProfile = false);
      }
    }
  }

  // =============================================
  // PESAN
  // =============================================
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

  // =============================================
  // KIRIM LAPORAN KE BACKEND
  // =============================================
  Future<void> kirimLaporan() async {
    if (sending) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => sending = true);

    try {
      final token = await storage.read(
        key: 'auth_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'Sesi login tidak ditemukan. Silakan login kembali.',
        );
      }

      // Sesuaikan nama field dengan backend.
      // Mode ini bukan laporan anonim.
      final Map<String, dynamic> payload = {
        'nama': namaController.text.trim(),
        'kelas': kelasController.text.trim(),
        'nomor_hp': hpController.text.trim(),
        'jenis_kejadian': jenis,
        'kronologi': kronologiController.text.trim(),
        'is_anonymous': false,
      };

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

      dynamic result;

      try {
        result = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Respons backend bukan JSON valid.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception(
          'Sesi login tidak valid atau telah kedaluwarsa.',
        );
      }

      if (response.statusCode == 403) {
        throw Exception(
          'Akses membuat laporan ditolak.',
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
              'Gagal mengirim laporan (${response.statusCode})',
        );
      }

      if (!mounted) return;

      showMessage(
        'Laporan berhasil dikirim',
        success: true,
      );

      Navigator.pop(context, true);
    } on TimeoutException {
      showMessage(
        'Koneksi timeout. Periksa daftar laporan '
        'sebelum mencoba mengirim ulang.',
      );
    } on http.ClientException {
      showMessage(
        'Tidak dapat terhubung ke server API.',
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  // =============================================
  // LABEL FORM
  // =============================================
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

  // =============================================
  // INPUT DECORATION
  // =============================================
  InputDecoration inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Colors.grey,
      ),
      prefixIcon: Icon(
        icon,
        size: 19,
        color: primaryColor,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
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
    );
  }

  // =============================================
  // INPUT FIELD
  // =============================================
  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: inputDecoration(hint, icon),
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bagian ini wajib diisi';
            }
            return null;
          },
    );
  }

  // =============================================
  // BUILD
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Buat Laporan',
          style: TextStyle(
            color: darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20, 25, 20, 40,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO CARD
                Container(
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
                          Icons.person_outline,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'Laporan menggunakan data diri. '
                          'Informasi kamu dapat digunakan '
                          'oleh Guru BK untuk proses tindak lanjut.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xff355B53),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                if (loadingProfile)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(
                      color: primaryColor,
                    ),
                  ),

                // NAMA
                formLabel('Nama Lengkap'),

                inputField(
                  controller: namaController,
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 18),

                // KELAS
                formLabel('Kelas'),

                inputField(
                  controller: kelasController,
                  hint: 'Contoh: XI IPA 2',
                  icon: Icons.school_outlined,
                ),

                const SizedBox(height: 18),

                // NOMOR HP
                formLabel('Nomor HP'),

                inputField(
                  controller: hpController,
                  hint: 'Masukkan nomor HP',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }

                    if (!RegExp(r'^[0-9+]{9,15}$')
                        .hasMatch(phone)) {
                      return 'Format nomor HP tidak valid';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 25),

                // JENIS KEJADIAN
                formLabel('Jenis Kejadian'),

                DropdownButtonFormField<String>(
                  value: jenis,
                  isExpanded: true,
                  decoration: inputDecoration(
                    'Pilih jenis kejadian',
                    Icons.category_outlined,
                  ),
                  items: jenisKejadian
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => jenis = value);
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

                inputField(
                  controller: kronologiController,
                  hint: 'Ceritakan apa yang terjadi...',
                  icon: Icons.description_outlined,
                  maxLines: 5,
                ),

                const SizedBox(height: 20),

                // UPLOAD BUKTI
                formLabel('Upload Bukti (Opsional)'),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
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
                        'Menunggu format upload dari backend',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // BUTTON KIRIM
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff35B99A),
                        primaryColor,
                      ],
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
                    onPressed: sending || loadingProfile
                        ? null
                        : kirimLaporan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor:
                          Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                    child: sending
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
