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

  // MENAMPILKAN PESAN
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

  // PROSES LOGIN KE BACKEND
  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage("Email dan password wajib diisi");
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      showMessage("Format email tidak valid");
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
        showMessage("Respons backend bukan JSON valid");
        return;
      }

      if (!mounted) return;

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] == false) {
        showMessage(
          result['message']?.toString() ??
              'Login gagal (${response.statusCode})',
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
        showMessage("Token JWT tidak ditemukan dari backend");
        return;
      }

      if (rawUser is! Map<String, dynamic>) {
        showMessage("Data user tidak ditemukan dari backend");
        return;
      }

      final user = rawUser;

      // Normalisasi role menjadi huruf kecil untuk pengecekan yang lebih aman
      final role = user['role']?.toString().toLowerCase().trim() ?? '';
      final nama = user['nama']?.toString() ?? 'Pengguna';

      // Validasi role yang diizinkan masuk
      if (role != 'siswa' && role != 'guru bk' && role != 'admin' && role != 'admin sekolah' && role != 'superadmin') {
        showMessage('Role tidak dikenali: $role');
        return;
      }

      // Simpan token JWT dan data user
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'auth_user', value: jsonEncode(user));
      await storage.write(key: 'remember_me', value: rememberMe.toString());

      if (!mounted) return;

      showMessage('Selamat datang, $nama!', success: true);

      // ==============================================
      // NAVIGASI BERDASARKAN ROLE USER
      // ==============================================
      if (role == 'superadmin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuSuperadmin()),
          (route) => false,
        );
      } else if (role == 'admin' || role == 'admin sekolah') {
        // // NAVIGASI ADMIN SEKOLAH (Pastikan file MenuAdmin sudah di-import)
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => const MenuAdminsekolah()),
        //   (route) => false,
        // );
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
      showMessage("Koneksi timeout. Periksa backend.");
    } on http.ClientException {
      showMessage("Tidak dapat terhubung ke server API.");
    } catch (e) {
      if (!mounted) return;
      showMessage('Terjadi kesalahan: $e');
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
      prefixIcon: Icon(icon, color: Colors.grey),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: const Color(0xffFAFAFA),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
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

  // EMAIL
  Widget emailField() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: inputDecoration('Email', Icons.email_outlined),
    );
  }

  // PASSWORD
  Widget passwordField() {
    return TextField(
      controller: passwordController,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onSubmitted: (_) => login(),
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
    );
  }

  // BUTTON LOGIN
  Widget loginButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff62C9A9), primaryColor],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 35),

                      // LOGO
                      Image.asset('assets/logo_ruang.jpeg', height: 85),

                      const SizedBox(height: 15),

                      // TITLE
                      const Text(
                        'Selamat Datang\n'
                        'di RuangAman',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Masuk untuk melanjutkan',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),

                      const SizedBox(height: 35),

                      // EMAIL
                      emailField(),

                      const SizedBox(height: 15),

                      // PASSWORD
                      passwordField(),

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
                                  onChanged: (value) {
                                    setState(() {
                                      rememberMe = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ingat saya',
                                style: TextStyle(
                                  color: Colors.grey,
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
                              'Lupa password?',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // LOGIN BUTTON
                      loginButton(),

                      const SizedBox(height: 25),

                      // PEMISAH
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Text(
                              'atau',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // LOGIN GOOGLE
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextButton(
                          onPressed: () {
                            showMessage('Google Login belum tersedia');
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

                      const Spacer(),

                      // REGISTER
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(text: 'Belum punya akun? '),
                                TextSpan(
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
          },
        ),
      ),
    );
  }
}
