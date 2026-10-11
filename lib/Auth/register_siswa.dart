import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/Auth/verifikasi.dart';
import 'package:ruang_aman/ipconfig.dart';

class RegisterSiswa extends StatefulWidget {
  const RegisterSiswa({super.key});

  @override
  State<RegisterSiswa> createState() => _RegisterSiswaState();
}

class _RegisterSiswaState extends State<RegisterSiswa> {
  // CONTROLLER
  final namaController = TextEditingController();
  final nisController = TextEditingController();
  final kelasController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final schoolIdController = TextEditingController();

  // STATE
  String? guruDipilih;
  bool obscurePassword = true;
  bool isLoading = false;

  // DATA GURU BK SEMENTARA
  final List<Map<String, String>> guruBK = [
    {"nama": "Siti Rahma, S.Psi", "sekolah": "SMA Negeri 1 Bandung"},
    {"nama": "Budi Santoso, S.Pd", "sekolah": "SMK Informatika"},
    {"nama": "Ahmad Fauzi, M.Psi", "sekolah": "SMA Harapan Bangsa"},
  ];

  @override
  void dispose() {
    namaController.dispose();
    nisController.dispose();
    kelasController.dispose();
    emailController.dispose();
    passwordController.dispose();
    schoolIdController.dispose();
    super.dispose();
  }

  // MESSAGE
  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xff087F72) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // REGISTER KE API
  Future<void> register() async {
    if (isLoading) return;

    final nama = namaController.text.trim();
    final nis = nisController.text.trim();
    final kelas = kelasController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final schoolId = int.tryParse(schoolIdController.text.trim());

    if (guruDipilih == null) {
      showMessage("Silakan pilih Guru BK terlebih dahulu");
      return;
    }

    if (nama.isEmpty ||
        nis.isEmpty ||
        kelas.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        schoolIdController.text.trim().isEmpty) {
      showMessage("Semua data harus diisi");
      return;
    }

    if (schoolId == null || schoolId <= 0) {
      showMessage("ID sekolah tidak valid");
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      showMessage("Format email tidak valid");
      return;
    }

    if (password.length < 6) {
      showMessage("Password minimal 6 karakter");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'password': password,
              'role': 'siswa',
              'school_id': schoolId,
              'nis': nis,
              'kelas': kelas,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Respons server tidak berupa JSON.
      }

      if (!mounted) return;

      final berhasil =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] != false;

      if (berhasil) {
        showMessage(
          data['message']?.toString() ?? 'Registrasi siswa berhasil',
          success: true,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => VerifikasiScreen(email: email)),
        );
      } else {
        showMessage(
          data['message']?.toString() ??
              'Registrasi gagal (${response.statusCode})',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showMessage('Gagal menghubungi server: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // INPUT DECORATION
  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xff087F72)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xff087F72), width: 2),
      ),
    );
  }

  // INPUT
  Widget input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: inputDecoration(hint, icon),
      ),
    );
  }

  // PASSWORD INPUT
  Widget passwordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        decoration: inputDecoration("Password", Icons.lock_outline).copyWith(
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
      ),
    );
  }

  // REGISTER BUTTON
  Widget registerButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff62C9A9), Color(0xff087F72)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff087F72).withOpacity(.20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Daftar Sekarang",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guruTerpilih = guruDipilih == null
        ? null
        : guruBK.firstWhere((guru) => guru['nama'] == guruDipilih);

    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),
      body: Stack(
        children: [
          // BACKGROUND ATAS
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xffDDF3EC),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // BACKGROUND BAWAH
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Color(0xffE7F7F2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BACK BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xff087F72),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // LOGO
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Image.asset("assets/logo_ruang.jpeg", height: 70),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // TITLE
                  const Text(
                    "Daftar Sebagai\nSiswa",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Buat akun dan pilih Guru BK yang akan mendampingimu",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // PILIH GURU BK
                  const Text(
                    "Pilih Guru BK",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: guruDipilih,
                    isExpanded: true,
                    decoration: inputDecoration(
                      "Pilih Guru BK",
                      Icons.person_search_outlined,
                    ),
                    items: guruBK.map((guru) {
                      return DropdownMenuItem<String>(
                        value: guru["nama"],
                        child: Text(
                          guru["nama"] ?? "",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff124F4A),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        guruDipilih = value;
                      });
                    },
                  ),

                  // DETAIL GURU BK
                  if (guruTerpilih != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xffE7F7F2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xff087F72),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  guruTerpilih["nama"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff124F4A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  guruTerpilih["sekolah"] ?? "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 25),

                  // DATA DIRI
                  const Text(
                    "Data Diri",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                    ),
                  ),

                  const SizedBox(height: 15),

                  input(
                    controller: namaController,
                    hint: "Nama Lengkap",
                    icon: Icons.person_outline,
                  ),

                  input(
                    controller: nisController,
                    hint: "NIS",
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),

                  input(
                    controller: kelasController,
                    hint: "Kelas (contoh: XII IPA 1)",
                    icon: Icons.class_outlined,
                  ),

                  input(
                    controller: schoolIdController,
                    hint: "ID Sekolah",
                    icon: Icons.school_outlined,
                    keyboardType: TextInputType.number,
                  ),

                  input(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  passwordInput(),

                  const SizedBox(height: 10),

                  registerButton(),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      "Aman bercerita • Nyaman berkembang",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
