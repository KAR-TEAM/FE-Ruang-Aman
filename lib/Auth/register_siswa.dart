import 'package:flutter/material.dart';
import 'package:ruang_aman/Auth/verifikasi.dart';

class RegisterSiswa extends StatefulWidget {
  const RegisterSiswa({super.key});

  @override
  State<RegisterSiswa> createState() => _RegisterSiswaState();
}

class _RegisterSiswaState extends State<RegisterSiswa> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nisController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String? guruDipilih;
  bool obscurePassword = true;

  // ============================================================
  // DATA GURU BK
  // ============================================================

  final List<Map<String, String>> guruBK = [
    {"nama": "Siti Rahma, S.Psi", "sekolah": "SMA Negeri 1 Bandung"},
    {"nama": "Budi Santoso, S.Pd", "sekolah": "SMK Informatika"},
    {"nama": "Ahmad Fauzi, M.Psi", "sekolah": "SMA Harapan Bangsa"},
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    namaController.dispose();
    nisController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // PROSES REGISTER
  // ============================================================

  void register() {
    final nama = namaController.text.trim();
    final nis = nisController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // ==========================================================
    // VALIDASI GURU BK
    // ==========================================================

    if (guruDipilih == null) {
      showMessage("Silakan pilih Guru BK terlebih dahulu");
      return;
    }

    // ==========================================================
    // VALIDASI FIELD KOSONG
    // ==========================================================

    if (nama.isEmpty || nis.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage("Semua data harus diisi");
      return;
    }

    // ==========================================================
    // VALIDASI EMAIL SEDERHANA
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
      MaterialPageRoute(builder: (context) => VerifikasiScreen(email: email)),
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
          // DEKORASI BACKGROUND ATAS
          // ====================================================
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

          // ====================================================
          // DEKORASI BACKGROUND BAWAH
          // ====================================================
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

          // ====================================================
          // CONTENT
          // ====================================================
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(25, 15, 25, 60),

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

                      child: Image.asset("assets/logo_ruang.jpeg", height: 70),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ============================================
                  // TITLE
                  // ============================================
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

                  // ============================================
                  // PILIH GURU BK
                  // ============================================
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

                  // ============================================
                  // DETAIL GURU BK
                  // ============================================
                  if (guruDipilih != null)
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
                                  guruDipilih!,

                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff124F4A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  guruBK.firstWhere(
                                        (guru) => guru["nama"] == guruDipilih,
                                      )["sekolah"] ??
                                      "",

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

                  // ============================================
                  // FORM TITLE
                  // ============================================
                  const Text(
                    "Data Diri",

                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ============================================
                  // NAMA
                  // ============================================
                  input(
                    controller: namaController,
                    hint: "Nama Lengkap",
                    icon: Icons.person_outline,
                  ),

                  // ============================================
                  // NIS
                  // ============================================
                  input(
                    controller: nisController,
                    hint: "NIS",
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),

                  // ============================================
                  // EMAIL
                  // ============================================
                  input(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // ============================================
                  // PASSWORD
                  // ============================================
                  passwordInput(),

                  const SizedBox(height: 10),

                  // ============================================
                  // BUTTON REGISTER
                  // ============================================
                  registerButton(),

                  const SizedBox(height: 20),

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
      padding: const EdgeInsets.only(bottom: 14),

      child: TextField(
        controller: controller,
        keyboardType: keyboardType,

        decoration: inputDecoration(hint, icon),
      ),
    );
  }

  // ============================================================
  // PASSWORD INPUT
  // ============================================================

  Widget passwordInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,

        decoration: InputDecoration(
          hintText: "Password",

          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff087F72)),

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
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),

            borderSide: BorderSide(color: Colors.grey.shade200),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),

            borderSide: const BorderSide(color: Color(0xff087F72), width: 2),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

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

  // ============================================================
  // REGISTER BUTTON
  // ============================================================

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

            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
