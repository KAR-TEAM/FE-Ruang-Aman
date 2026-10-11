import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/Auth/login.dart'; // Uncomment jika sudah ada halaman login

class VerifikasiScreen extends StatefulWidget {
  final String email;

  const VerifikasiScreen({super.key, required this.email});

  @override
  State<VerifikasiScreen> createState() => _VerifikasiScreenState();
}

class _VerifikasiScreenState extends State<VerifikasiScreen> {
  // ============================================================
  // OTP CONTROLLER
  // ============================================================

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // VERIFIKASI KE API BACKEND
  // ============================================================

  Future<void> verifikasi() async {
    final String otp = otpControllers
        .map((controller) => controller.text)
        .join();

    // Validasi OTP
    if (otp.length != 6) {
      showMessage("Masukkan 6 digit kode verifikasi", Colors.red);
      return;
    }

    // Loading
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'otp_code': otp,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        showMessage(
          data['message']?.toString() ?? "Verifikasi berhasil. Akun Anda sudah aktif.",
          const Color(0xff087F72),
        );

        // Navigasi ke halaman login setelah berhasil verifikasi
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        showMessage(
          data['message']?.toString() ?? "Kode OTP salah atau kedaluwarsa.",
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Gagal terhubung ke server: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // KIRIM ULANG OTP KE API BACKEND
  // ============================================================

  Future<void> kirimUlang() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
        }),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Kosongkan OTP lama
        for (final controller in otpControllers) {
          controller.clear();
        }

        // Fokus kembali ke OTP pertama
        if (focusNodes.isNotEmpty) {
          FocusScope.of(context).requestFocus(focusNodes.first);
        }

        showMessage(
          data['message']?.toString() ?? "Kode verifikasi baru telah dikirim.",
          const Color(0xff087F72),
        );
      } else {
        showMessage(
          data['message']?.toString() ?? "Gagal mengirim ulang kode.",
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showMessage("Gagal terhubung ke server: $e", Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),
      body: Stack(
        children: [
          // DEKORASI ATAS
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

          // DEKORASI BAWAH
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

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),

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
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Color(0xff087F72),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

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
                        child: Image.asset(
                          "assets/logo_ruang.jpeg",
                          height: 65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // TITLE
                    const Center(
                      child: Text(
                        "Verifikasi Akun",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff124F4A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // SUBTITLE
                    const Center(
                      child: Text(
                        "Masukkan kode verifikasi yang telah\n"
                        "dikirimkan ke email kamu",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // EMAIL
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff087F72),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // CARD VERIFIKASI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 25,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ICON
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xff087F72).withOpacity(.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              color: Color(0xff087F72),
                              size: 30,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // TITLE OTP
                          const Text(
                            "Kode Verifikasi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff124F4A),
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "Masukkan 6 digit kode yang kamu terima",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),

                          const SizedBox(height: 25),

                          // OTP RESPONSIVE
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const double spacing = 6;
                              const double totalSpacing = spacing * 5;
                              final double availableWidth =
                                  constraints.maxWidth - totalSpacing;
                              double boxWidth = availableWidth / 6;

                              if (boxWidth > 50) {
                                boxWidth = 50;
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(6, (index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index == 5 ? 0 : spacing,
                                    ),
                                    child: otpBox(index, boxWidth),
                                  );
                                }),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // BUTTON VERIFIKASI
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff62C9A9), Color(0xff087F72)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xff087F72,
                                  ).withOpacity(.20),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : verifikasi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            "Verifikasi Akun",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.verified_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // RESEND
                          const Text(
                            "Belum menerima kode?",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),

                          const SizedBox(height: 5),

                          TextButton(
                            onPressed: isLoading ? null : kirimUlang,
                            child: const Text(
                              "Kirim Ulang Kode",
                              style: TextStyle(
                                color: Color(0xff087F72),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // FOOTER
                    Center(
                      child: Text(
                        "Aman bercerita - Nyaman berkembang",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OTP BOX RESPONSIVE
  // ============================================================

  Widget otpBox(int index, double width) {
    return SizedBox(
      width: width,
      height: 55,
      child: TextField(
        controller: otpControllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xff124F4A),
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xffF8FCFA),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xffDCECE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
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
  }
}