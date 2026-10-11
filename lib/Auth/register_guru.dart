import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/Auth/verifikasi.dart';
import 'package:ruang_aman/ipconfig.dart';

class RegisterGuru extends StatefulWidget {
  const RegisterGuru({super.key});

  @override
  State<RegisterGuru> createState() => _RegisterGuruState();
}

class _RegisterGuruState extends State<RegisterGuru> {
  final namaController = TextEditingController();
  final nipController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final schoolSearchController = TextEditingController();

  String? selectedSchoolId;
  String? selectedSchoolName;
  String selectedJenisKelamin = 'Laki-laki';

  bool obscurePassword = true;
  bool isLoading = false;
  bool isSearchingSchool = false;
  List<Map<String, dynamic>> schoolList = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchSchools();
  }

  @override
  void dispose() {
    namaController.dispose();
    nipController.dispose();
    emailController.dispose();
    passwordController.dispose();
    schoolSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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

  // Fungsi untuk mengambil daftar sekolah (opsi search sekolah)
  Future<void> fetchSchools({String query = ''}) async {
    setState(() => isSearchingSchool = true);
    try {
      // Ubah parameter menjadi 'query' sesuai backend req.query.query
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/search${query.isNotEmpty ? '?query=$query' : '?query=a'}'); 
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];

        // Backend mengembalikan format { schools: [...] }
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

  Future<void> register() async {
    if (isLoading) return;

    final nama = namaController.text.trim();
    final nip = nipController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (nama.isEmpty || nip.isEmpty || email.isEmpty || password.isEmpty || selectedSchoolId == null) {
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
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'password': password,
              'role': 'guru_bk',
              'school_id': selectedSchoolId,
              'nip': nip,
              'jenis_kelamin': selectedJenisKelamin,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (!mounted) return;

      final berhasil =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] != false;

      if (berhasil) {
        showMessage(
          data['message']?.toString() ?? 'Registrasi berhasil',
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

      if (e is http.ClientException) {
        showMessage('Tidak dapat terhubung ke server. Periksa backend dan URL API.');
      } else {
        showMessage('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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

  Widget passwordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,
        decoration: inputDecoration('Password', Icons.lock_outline).copyWith(
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
            color: const Color(0xff087F72).withOpacity(.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                    'Daftar Sekarang',
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
      body: SafeArea(
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

              const Text(
                'Daftar Sebagai\nGuru BK',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff124F4A),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Lengkapi data pribadi dan pilih sekolah tempat Anda bertugas',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Data Pribadi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff124F4A),
                ),
              ),

              const SizedBox(height: 15),

              input(
                controller: namaController,
                hint: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),

              input(
                controller: nipController,
                hint: 'NIP',
                icon: Icons.badge_outlined,
              ),

              input(
                controller: emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              passwordInput(),

              // PILIHAN JENIS KELAMIN
              const Padding(
                padding: EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  'Jenis Kelamin',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff124F4A),
                  ),
                ),
              ),
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

              const SizedBox(height: 20),

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
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: schoolList.isEmpty
                            ? const Center(child: Text('Sekolah tidak ditemukan', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: schoolList.length,
                                itemBuilder: (context, index) {
                                  final school = schoolList[index];
                                  final schoolIdStr = school['id'].toString();
                                  final schoolName = school['nama_sekolah'] ?? school['nama'] ?? 'Sekolah Tanpa Nama';
                                  final isSelected = selectedSchoolId == schoolIdStr;

                                  return ListTile(
                                    title: Text(schoolName, style: const TextStyle(fontSize: 14)),
                                    selected: isSelected,
                                    selectedTileColor: const Color(0xffE9F7F1),
                                    onTap: () {
                                      setState(() {
                                        selectedSchoolName = schoolName;
                                        schoolSearchController.text = schoolName;
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

              const SizedBox(height: 25),

              Center(
                child: Text(
                  'Aman bercerita • Nyaman berkembang',
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
    );
  }
}

// Helper kecil agar DropdownButton tidak error tipe data di Flutter modern
class DropdownButtonMenuItem<T> extends DropdownMenuItem<T> {
  const DropdownButtonMenuItem({
    super.key,
    required super.value,
    required super.child,
  });
}