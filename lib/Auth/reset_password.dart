import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  // 1: Input Email, 2: Input OTP, 3: Input Password Baru
  int currentStep = 1;

  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // 6 Controller untuk input OTP
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String verifiedOtpCode = ''; // Menyimpan kode OTP yang sudah diverifikasi

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xff087F72) : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // TAHAP 1: KIRIM OTP KE EMAIL (FORGOT PASSWORD)
  // ============================================================
  Future<void> requestOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("Email wajib diisi");
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      showMessage("Format email tidak valid");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showMessage(data['message'] ?? "Kode OTP berhasil dikirim ke email.", success: true);
        setState(() {
          currentStep = 2; // Pindah ke form verifikasi OTP
        });
      } else {
        showMessage(data['message'] ?? "Gagal mengirim kode OTP.");
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Terjadi kesalahan koneksi: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // TAHAP 2: VERIFIKASI KODE OTP
  // ============================================================
  Future<void> verifyOtpOnly() async {
    final email = emailController.text.trim();
    final otp = otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      showMessage("Masukkan 6 digit kode OTP secara lengkap");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp_code': otp,
        }),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        verifiedOtpCode = otp; // Simpan OTP yang valid
        showMessage("OTP terverifikasi. Silakan masukkan password baru.", success: true);
        setState(() {
          currentStep = 3; // Pindah ke form input password baru
        });
      } else {
        showMessage(data['message'] ?? "Kode OTP salah atau sudah kedaluwarsa.");
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Terjadi kesalahan koneksi: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // TAHAP 3: UPDATE PASSWORD BARU (RESET PASSWORD)
  // ============================================================
  Future<void> submitNewPassword() async {
    final email = emailController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showMessage("Semua kolom password wajib diisi");
      return;
    }

    if (newPassword.length < 6) {
      showMessage("Password baru minimal 6 karakter");
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage("Konfirmasi password tidak cocok");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp_code': verifiedOtpCode,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showMessage(data['message'] ?? "Password berhasil diubah. Silakan login.", success: true);
        Navigator.pop(context); // Kembali ke halaman login
      } else {
        showMessage(data['message'] ?? "Gagal mereset password.");
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Terjadi kesalahan koneksi: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    String titleText = "Reset\nPassword";
    String subtitleText = "Masukkan email akunmu untuk menerima kode OTP pemulihan sandi.";

    if (currentStep == 2) {
      titleText = "Verifikasi\nKode OTP";
      subtitleText = "Masukkan 6 digit kode OTP yang dikirimkan ke email ${emailController.text}";
    } else if (currentStep == 3) {
      titleText = "Buat Password\nBaru";
      subtitleText = "Pastikan password barunya kuat dan mudah diingat.";
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),
      body: Stack(
        children: [
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
                      onPressed: () {
                        if (currentStep > 1) {
                          setState(() => currentStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xff087F72),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // ==========================================
                  // TAHAP 1: INPUT EMAIL
                  // ==========================================
                  if (currentStep == 1) ...[
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputDecoration("Email terdaftar", Icons.email_outlined),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff087F72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Kirim Kode OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]

                  // ==========================================
                  // TAHAP 2: INPUT KODE OTP
                  // ==========================================
                  else if (currentStep == 2) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 45,
                          height: 55,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff124F4A)),
                            decoration: InputDecoration(
                              counterText: "",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xff087F72), width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                              }
                              if (value.isEmpty && index > 0) {
                                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : verifyOtpOnly,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff087F72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Verifikasi OTP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]

                  // ==========================================
                  // TAHAP 3: MASUKKAN PASSWORD BARU
                  // ==========================================
                  else if (currentStep == 3) ...[
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscurePassword,
                      decoration: inputDecoration("Password Baru (Min. 6 Karakter)", Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: inputDecoration("Konfirmasi Password Baru", Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                          icon: Icon(
                            obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitNewPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff087F72),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Simpan Password Baru", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}