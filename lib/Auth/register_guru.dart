import 'package:flutter/material.dart';
import 'package:ruang_aman/Auth/verifikasi.dart';

class RegisterGuru extends StatefulWidget {
  const RegisterGuru({super.key});

  @override
  State<RegisterGuru> createState() => _RegisterGuruState();
}

class _RegisterGuruState extends State<RegisterGuru> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nipController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController sekolahController = TextEditingController();
  final TextEditingController alamatSekolahController =
      TextEditingController();
  final TextEditingController kodeSekolahController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool obscurePassword = true;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    namaController.dispose();
    nipController.dispose();
    emailController.dispose();
    passwordController.dispose();
    sekolahController.dispose();
    alamatSekolahController.dispose();
    kodeSekolahController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  void register() {
    final nama = namaController.text.trim();
    final nip = nipController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final sekolah = sekolahController.text.trim();
    final alamatSekolah = alamatSekolahController.text.trim();
    final kodeSekolah = kodeSekolahController.text.trim();

    // ==========================================================
    // VALIDASI DATA KOSONG
    // ==========================================================

    if (nama.isEmpty ||
        nip.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        sekolah.isEmpty ||
        alamatSekolah.isEmpty ||
        kodeSekolah.isEmpty) {
      showMessage("Semua data harus diisi");
      return;
    }

    // ==========================================================
    // VALIDASI EMAIL
    // ==========================================================

    if (!email.contains("@") || !email.contains(".")) {
      showMessage("Format email tidak valid");
      return;
    }

    // ==========================================================
    // VALIDASI PASSWORD
    // ==========================================================

    if (password.length < 6) {
      showMessage("Password minimal 6 karakter");
      return;
    }

    // ==========================================================
    // REGISTER BERHASIL → VERIFIKASI
    // ==========================================================

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifikasiScreen(
          email: email,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          // ====================================================
          // DECORATION ATAS
          // ====================================================

          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                color: Color(0xffDDF3EC),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ====================================================
          // DECORATION BAWAH
          // ====================================================

          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: Color(0xffE7F7F2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                25,
                15,
                25,
                60,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ============================================
                  // BACK BUTTON
                  // ============================================

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

                  const SizedBox(height: 30),

                  // ============================================
                  // LOGO
                  // ============================================

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
                        height: 70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ============================================
                  // TITLE
                  // ============================================

                  const Text(
                    "Daftar Sebagai\nGuru BK",

                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Lengkapi data untuk mendampingi siswa "
                    "dengan layanan konseling terbaik",

                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // ============================================
                  // DATA PRIBADI
                  // ============================================

                  const Text(
                    "Data Pribadi",

                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // NAMA
                  input(
                    controller: namaController,
                    hint: "Nama Lengkap",
                    icon: Icons.person_outline,
                  ),

                  // NIP
                  input(
                    controller: nipController,
                    hint: "NIP / ID Guru",
                    icon: Icons.badge_outlined,
                  ),

                  // EMAIL
                  input(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // PASSWORD
                  passwordInput(),

                  const SizedBox(height: 10),

                  // ============================================
                  // DATA SEKOLAH
                  // ============================================

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
                              "Data Sekolah",

                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff124F4A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // NAMA SEKOLAH
                        input(
                          controller: sekolahController,
                          hint: "Nama Sekolah",
                          icon: Icons.school_outlined,
                        ),

                        // ALAMAT SEKOLAH
                        input(
                          controller: alamatSekolahController,
                          hint: "Alamat Sekolah",
                          icon: Icons.location_on_outlined,
                        ),

                        // KODE SEKOLAH
                        input(
                          controller: kodeSekolahController,
                          hint: "Kode Sekolah",
                          icon: Icons.qr_code_2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ============================================
                  // BUTTON REGISTER
                  // ============================================

                  registerButton(),

                  const SizedBox(height: 25),

                  // ============================================
                  // FOOTER
                  // ============================================

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

  // ============================================================
  // INPUT
  // ============================================================

  Widget input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: TextField(
        controller: controller,
        keyboardType: keyboardType,

        decoration: inputDecoration(
          hint,
          icon,
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD
  // ============================================================

  Widget passwordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,

        decoration: InputDecoration(
          hintText: "Password",

          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),

          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xff087F72),
          ),

          // SHOW / HIDE PASSWORD
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

          filled: true,
          fillColor: const Color(0xffFAFAFA),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),

            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),

            borderSide: const BorderSide(
              color: Color(0xff087F72),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xff087F72),
      ),

      filled: true,
      fillColor: const Color(0xffFAFAFA),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),

        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),

        borderSide: const BorderSide(
          color: Color(0xff087F72),
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON REGISTER
  // ============================================================

  Widget registerButton() {
    return Container(
      width: double.infinity,
      height: 55,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff62C9A9),
            Color(0xff087F72),
          ],
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
        // ======================================================
        // REGISTER → VERIFIKASI
        // ======================================================

        onPressed: register,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: const Row(
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
}