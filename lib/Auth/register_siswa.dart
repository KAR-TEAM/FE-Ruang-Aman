import 'dart:convert';
import 'dart:async';

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
  final schoolSearchController = TextEditingController();

  // STATE
  String? selectedSchoolId;
  String? selectedSchoolName;
  String selectedJenisKelamin = 'Laki-laki';
  bool obscurePassword = true;
  bool isLoading = false;
  bool isSearchingSchool = false;
  List<Map<String, dynamic>> schoolList = [];
  Timer? _debounce;

  @override
  void dispose() {
    namaController.dispose();
    nisController.dispose();
    kelasController.dispose();
    emailController.dispose();
    passwordController.dispose();
    schoolSearchController.dispose();
    _debounce?.cancel();
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

  // PENCARIAN SEKOLAH (FITUR SEARCH)
  Future<void> fetchSchools({String query = ''}) async {
    if (query.trim().isEmpty) {
      setState(() {
        schoolList = [];
        isSearchingSchool = false;
      });
      return;
    }

    setState(() => isSearchingSchool = true);
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/search?query=${Uri.encodeComponent(query)}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];

        if (decoded is Map && decoded['schools'] is List) {
          data = decoded['schools'];
        } else if (decoded is List) {
          data = decoded;
        }

        if (mounted) {
          setState(() {
            schoolList = data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch schools: $e');
    } finally {
      if (mounted) setState(() => isSearchingSchool = false);
    }
  }

  // REGISTER KE API
  Future<void> register() async {
    if (isLoading) return;

    final nama = namaController.text.trim();
    final nis = nisController.text.trim();
    final kelas = kelasController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (nama.isEmpty ||
        nis.isEmpty ||
        kelas.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        selectedSchoolId == null ||
        selectedSchoolId!.isEmpty) {
      showMessage("Semua data termasuk sekolah wajib diisi");
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
              'school_id': selectedSchoolId,
              'nis': nis,
              'kelas': kelas,
              'jenis_kelamin': selectedJenisKelamin,
            }),
          )
          .timeout(const Duration(seconds: 30));

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
    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),
      body: Stack(
        children: [
          // BACKGROUND ATAS
          Positioned(
            top: -40,
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

                  // // LOGO
                  // Center(
                  //   child: Container(
                  //     padding: const EdgeInsets.all(15),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       shape: BoxShape.circle,
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.black.withOpacity(.08),
                  //           blurRadius: 15,
                  //         ),
                  //       ],
                  //     ),
                  //     child: Image.asset("assets/logo_ruang.jpeg", height: 70),
                  //   ),
                  // ),

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
                    "Lengkapi data diri dan pilih sekolahmu",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

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

                  // PILIHAN JENIS KELAMIN
                  // const Padding(
                  //   padding: EdgeInsets.only(bottom: 8, top: 4),
                  //   child: Text(
                  //     'Jenis Kelamin',
                  //     style: TextStyle(
                  //       fontSize: 13,
                  //       fontWeight: FontWeight.w600,
                  //       color: Color(0xff124F4A),
                  //     ),
                  //   ),
                  // ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedJenisKelamin,
                        isExpanded: true,
                        items: ['Laki-laki', 'Perempuan'].map((String value) {
                          return DropdownButtonMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedJenisKelamin = newValue!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  input(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  passwordInput(),

                  const SizedBox(height: 10),

                  // DATA SEKOLAH DENGAN FITUR SEARCH
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              color: Color(0xff087F72),
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Pilih Sekolah',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff124F4A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: schoolSearchController,
                          decoration: inputDecoration('Cari nama sekolah...', Icons.search),
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) _debounce?.cancel();
                            _debounce = Timer(const Duration(milliseconds: 500), () {
                              fetchSchools(query: value);
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        if (isSearchingSchool)
                          const Center(child: CircularProgressIndicator(color: Color(0xff087F72)))
                        else if (schoolList.isNotEmpty)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              itemCount: schoolList.length,
                              itemBuilder: (context, index) {
                                final school = schoolList[index];
                                final schoolIdStr = school['id'].toString();
                                final schoolName = school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah Tanpa Nama';
                                final isSelected = selectedSchoolId == schoolIdStr;

                                return ListTile(
                                  title: Text(schoolName, style: const TextStyle(fontSize: 14)),
                                  // Subtitle ID dihapus agar tidak tampil
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xffE9F7F1),
                                  onTap: () {
                                    setState(() {
                                      selectedSchoolId = schoolIdStr;
                                      selectedSchoolName = schoolName;
                                      schoolSearchController.text = schoolName;
                                      schoolList = []; // Sembunyikan list setelah dipilih
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        if (selectedSchoolName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Dipilih: $selectedSchoolName',
                            style: const TextStyle(fontSize: 12, color: Color(0xff087F72), fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

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

class DropdownButtonMenuItem<T> extends DropdownMenuItem<T> {
  const DropdownButtonMenuItem({
    super.key,
    required super.value,
    required super.child,
  });
}