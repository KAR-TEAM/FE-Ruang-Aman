import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:ruang_aman/ipconfig.dart';

class BuatLaporanDataPage extends StatefulWidget {
  const BuatLaporanDataPage({super.key});

  @override
  State<BuatLaporanDataPage> createState() => _BuatLaporanDataPageState();
}

class _BuatLaporanDataPageState extends State<BuatLaporanDataPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkColor = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  XFile? pickedFileObj;
  Uint8List? webImageBytes;
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  final formKey = GlobalKey<FormState>();
  final kronologiController = TextEditingController();
  final lokasiController = TextEditingController();
  final tanggalController = TextEditingController();
  final waktuController = TextEditingController();

  String namaSiswa = 'Memuat...';
  String kelasSiswa = '-';
  String? jenis;
  bool isLoading = false;

  final List<String> jenisKejadian = [
    'Kekerasan Fisik',
    'Pelecehan',
    'Cyberbullying',
    'Bullying',
    'Kekerasan Verbal',
    'Konflik Teman',
    'Masalah Keluarga',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  @override
  void dispose() {
    kronologiController.dispose();
    lokasiController.dispose();
    tanggalController.dispose();
    waktuController.dispose();
    super.dispose();
  }

  Future<void> loadStudentData() async {
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) return;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/siswa/profile'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData is Map && mounted) {
          setState(() {
            namaSiswa = resData['nama'] ?? 'Siswa';
            final kelasVal = resData['kelas'] ?? '-';
            final jurusanVal = resData['jurusan'] ?? '';
            kelasSiswa = jurusanVal.isNotEmpty
                ? '$kelasVal ($jurusanVal)'
                : kelasVal;
          });
        }
      }
    } catch (_) {
      setState(() {
        namaSiswa = 'Siswa';
        kelasSiswa = '-';
      });
    }
  }

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

  Future<void> selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hours = picked.hour.toString().padLeft(2, '0');
      final minutes = picked.minute.toString().padLeft(2, '0');
      setState(() {
        waktuController.text = '$hours:$minutes';
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          pickedFileObj = image;
          webImageBytes = bytes;
        });
      } else {
        setState(() {
          pickedFileObj = image;
        });
      }
    }
  }

  Future<void> kirimLaporan() async {
    if (isLoading) return;

    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      // Menggunakan MultipartRequest untuk mengirim teks dan file bukti sekaligus
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.createReport));
      
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['jenis'] = jenis ?? '';
      request.fields['kronologi'] = kronologiController.text.trim();
      request.fields['lokasi'] = lokasiController.text.trim();
      request.fields['tanggal_kejadian'] = tanggalController.text.trim();
      if (waktuController.text.trim().isNotEmpty) {
        request.fields['waktu_kejadian'] = waktuController.text.trim();
      }
      request.fields['anonymous'] = 'false';

      // Lampirkan file bukti foto jika ada
      if (pickedFileObj != null) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'bukti',
            webImageBytes!,
            filename: pickedFileObj!.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'bukti',
            pickedFileObj!.path,
          ));
        }
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 35));
      var response = await http.Response.fromStream(streamedResponse);

      dynamic result;
      try {
        result = response.body.isEmpty ? {} : jsonDecode(response.body);
      } catch (_) {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }

      if (response.statusCode == 401) {
        throw Exception('Sesi login sudah kedaluwarsa.');
      }
      if (response.statusCode == 403) {
        throw Exception('Akses membuat laporan ditolak.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = result is Map ? result['message']?.toString() : null;
        throw Exception(message ?? 'Gagal mengirim laporan (${response.statusCode})');
      }

      if (!mounted) return;

      showMessage('Laporan berhasil dikirim', success: true);
      Navigator.pop(context, true);
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa jaringan Anda.');
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

  Widget formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: darkColor,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  InputDecoration inputDecoration(
    String hint, {
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: primaryColor, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffE2ECE9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD6EFE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laporan dengan Identitas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Melaporkan sebagai $namaSiswa (Kelas $kelasSiswa)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff355B53),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : kirimLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Kirim Laporan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
      ),
    );
  }

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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildInfoCard(),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formLabel('Nama Lengkap'),
                          TextFormField(
                            controller: TextEditingController(text: namaSiswa),
                            readOnly: true,
                            decoration: inputDecoration(
                              'Nama',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formLabel('Kelas'),
                          TextFormField(
                            controller: TextEditingController(text: kelasSiswa),
                            readOnly: true,
                            decoration: inputDecoration(
                              'Kelas',
                              icon: Icons.school_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

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
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13, color: darkColor),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      jenis = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih jenis kejadian terlebih dahulu';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                formLabel('Lokasi Kejadian'),
                TextFormField(
                  controller: lokasiController,
                  decoration: inputDecoration(
                    'Contoh: Kantin Sekolah / Kelas X-2',
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lokasi wajib diisi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formLabel('Tanggal Kejadian'),
                          TextFormField(
                            controller: tanggalController,
                            readOnly: true,
                            onTap: selectDate,
                            decoration: inputDecoration(
                              'Pilih tanggal',
                              icon: Icons.calendar_today_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          formLabel('Waktu (Opsional)'),
                          TextFormField(
                            controller: waktuController,
                            readOnly: true,
                            onTap: selectTime,
                            decoration: inputDecoration(
                              'Pilih waktu',
                              icon: Icons.access_time_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                formLabel('Kronologi Kejadian'),
                TextFormField(
                  controller: kronologiController,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  decoration: inputDecoration(
                    'Ceritakan kronologi kejadian secara detail...',
                  ),
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

                const SizedBox(height: 18),

                formLabel('Bukti atau Lampiran (Opsional)'),
                InkWell(
                  onTap: pickImage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffE2ECE9)),
                    ),
                    child: pickedFileObj == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: primaryColor,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Unggah Foto / Bukti Pendukung',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.memory(
                                        webImageBytes!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(pickedFileObj!.path),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Lampiran berhasil dipilih',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => setState(() {
                                  pickedFileObj = null;
                                  webImageBytes = null;
                                }),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}