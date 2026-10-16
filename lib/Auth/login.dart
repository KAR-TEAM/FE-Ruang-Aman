import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/Auth/register.dart';
import 'package:ruang_aman/siswa/menu.dart';
import 'package:ruang_aman/guru/menu.dart';
import 'package:ruang_aman/superadmin/menu.dart';
import 'package:ruang_aman/admin/menu.dart';
import 'package:ruang_aman/Auth/reset_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // CONTROLLER
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // STATE
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  static const Color primaryColor = Color(0xff087F72);
  static const Color darkColor = Color(0xff124F4A);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // MENAMPILKAN PESAN RAMAH PENGGUNA
  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryColor : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  // PROSES LOGIN KE BACKEND
  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage("Silakan isi email dan kata sandi terlebih dahulu.");
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      showMessage("Format alamat email yang kamu masukkan belum valid.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> result = {};

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          result = decoded;
        }
      } catch (_) {
        showMessage("Terjadi kendala pada respons peladen.");
        return;
      }

      if (!mounted) return;

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] == false) {
        showMessage(
          result['message']?.toString() ??
              'Gagal masuk. Periksa kembali email dan kata sandi kamu.',
        );
        return;
      }

      // DATA RESPONSE
      final rawData = result['data'];

      final Map<String, dynamic> data = rawData is Map<String, dynamic>
          ? rawData
          : result;

      // AMBIL JWT
      final token =
          (data['token'] ??
                  data['access_token'] ??
                  data['accessToken'] ??
                  result['token'])
              ?.toString();

      // AMBIL USER
      final rawUser = data['user'] ?? result['user'];

      if (token == null || token.isEmpty) {
        showMessage("Sesi masuk gagal diproses. Token tidak ditemukan.");
        return;
      }

      if (rawUser is! Map<String, dynamic>) {
        showMessage("Data pengguna tidak ditemukan.");
        return;
      }

      final user = rawUser;

      // Normalisasi role
      final role = user['role']?.toString().toLowerCase().trim() ?? '';
      final nama = user['nama']?.toString() ?? 'Pengguna';

      if (role != 'siswa' && role != 'guru bk' && role != 'admin' && role != 'admin sekolah' && role != 'superadmin') {
        showMessage('Peran akun tidak dikenali.');
        return;
      }

      // Simpan token dan data user
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'auth_user', value: jsonEncode(user));
      await storage.write(key: 'remember_me', value: rememberMe.toString());

      if (!mounted) return;

      showMessage('Selamat datang kembali, $nama!', success: true);

      // NAVIGASI BERDASARKAN ROLE
      if (role == 'superadmin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuSuperadmin()),
          (route) => false,
        );
      } else if (role == 'admin' || role == 'admin sekolah') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminMenuPage()),
          (route) => false,
        );
      } else if (role == 'siswa') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuPage()),
          (route) => false,
        );
      } else if (role == 'guru bk') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPageguru()),
          (route) => false,
        );
      }

    } on TimeoutException {
      showMessage("Sambungan terputus karena waktu habis. Periksa jaringan kamu.");
    } on http.ClientException {
      showMessage("Tidak dapat terhubung ke peladen saat ini.");
    } catch (e) {
      if (!mounted) return;
      showMessage('Terjadi kesalahan yang tidak terduga.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // DECORATION INPUT
  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xffFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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

  // TOMBOL LOGIN YANG AMAN
  Widget loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff62C9A9), primaryColor],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
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
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "Masuk",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // LOGO
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/logo_ruang.jpeg', height: 80),
              ),

              const SizedBox(height: 20),

              // TITLE
              const Text(
                'Selamat Datang\ndi RuangAman',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Masuk untuk melanjutkan aktivitasmu',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),

              const SizedBox(height: 35),

              // EMAIL FIELD
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: inputDecoration('Alamat Email', Icons.email_outlined),
              ),

              const SizedBox(height: 16),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => login(),
                decoration: inputDecoration('Kata Sandi', Icons.lock_outline).copyWith(
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // INGAT SAYA & LUPA PASSWORD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: rememberMe,
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ingat saya',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // TOMBOL MASUK
              loginButton(),

              const SizedBox(height: 25),

              // PEMISAH
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'atau',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              // TOMBOL GOOGLE
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextButton(
                  onPressed: () {
                    showMessage('Masuk dengan Google belum tersedia.');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/gg.png', height: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          color: Color(0xff333333),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // DAFTAR AKUN BARU
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      children: [
                        const TextSpan(text: 'Belum punya akun? '),
                        const TextSpan(
                          text: 'Daftar sekarang',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}