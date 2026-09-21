import 'package:flutter/material.dart';
import 'package:ruang_aman/Auth/register.dart';

// MENU SISWA
import 'package:ruang_aman/siswa/menu.dart';

// MENU GURU BK
import 'package:ruang_aman/guru/menu.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // CONTROLLER
  // ============================================================
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================
  bool rememberMe = false;
  bool obscurePassword = true;

  // ============================================================
  // DATA USER DUMMY
  // ============================================================
  final List<Map<String, String>> dummyUsers = [
    {
      "nama": "Andi Pratama",
      "email": "siswa@gmail.com",
      "nis": "123456",
      "password": "siswa123",
      "role": "siswa",
    },
    {
      "nama": "Budi Santoso",
      "email": "budi@gmail.com",
      "nis": "654321",
      "password": "budi123",
      "role": "siswa",
    },
    {
      "nama": "Siti Aisyah",
      "email": "siti@gmail.com",
      "nis": "112233",
      "password": "siti123",
      "role": "siswa",
    },

    // GURU BK
    {
      "nama": "Ibu Rina",
      "email": "guru@gmail.com",
      "nis": "",
      "password": "guru123",
      "role": "guru_bk",
    },
    {
      "nama": "Pak Ahmad",
      "email": "bk@sekolah.com",
      "nis": "",
      "password": "guru123",
      "role": "guru_bk",
    },
  ];

  // ============================================================
  // DISPOSE
  // ============================================================
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // PROSES LOGIN
  // ============================================================
  void login() {
    final String emailOrNis = emailController.text.trim();
    final String password = passwordController.text.trim();

    // ==========================================================
    // VALIDASI INPUT KOSONG
    // ==========================================================
    if (emailOrNis.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NIS / Email dan password harus diisi"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // ==========================================================
    // MENCARI USER DARI DATA DUMMY
    // ==========================================================
    Map<String, String>? user;

    for (final data in dummyUsers) {
      final String emailUser = data["email"]?.toLowerCase() ?? "";

      final String nisUser = data["nis"] ?? "";

      final String passwordUser = data["password"] ?? "";

      // Cocokkan email
      final bool emailCocok = emailUser == emailOrNis.toLowerCase();

      // Cocokkan NIS
      final bool nisCocok = nisUser.isNotEmpty && nisUser == emailOrNis;

      // Cocokkan password
      final bool passwordCocok = passwordUser == password;

      // Jika email/NIS dan password benar
      if ((emailCocok || nisCocok) && passwordCocok) {
        user = data;
        break;
      }
    }

    // ==========================================================
    // USER TIDAK DITEMUKAN
    // ==========================================================
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NIS / Email atau password salah"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // ==========================================================
    // AMBIL DATA USER
    // ==========================================================
    final String nama = user["nama"] ?? "";

    final String role = user["role"] ?? "";

    debugPrint("=============================");
    debugPrint("LOGIN BERHASIL");
    debugPrint("Nama : $nama");
    debugPrint("Role : $role");
    debugPrint("=============================");

    // ==========================================================
    // LOGIN SEBAGAI SISWA
    // ==========================================================
    if (role == "siswa") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
      );

      return;
    }

    // ==========================================================
    // LOGIN SEBAGAI GURU BK
    // ==========================================================
    if (role == "guru_bk") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPageguru()),
      );

      return;
    }

    // ==========================================================
    // ROLE TIDAK DIKENALI
    // ==========================================================
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Role pengguna tidak ditemukan"),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,

              child: Column(
                children: [
                  const SizedBox(height: 35),

                  // ======================================================
                  // LOGO
                  // ======================================================
                  Image.asset("assets/logo_ruang.jpeg", height: 85),

                  const SizedBox(height: 15),

                  // ======================================================
                  // TITLE
                  // ======================================================
                  const Text(
                    "Selamat Datang\n"
                    "di RuangAman",

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff124F4A),
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Masuk untuk melanjutkan",

                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 35),

                  // ======================================================
                  // NIS / EMAIL
                  // ======================================================
                  inputField(
                    controller: emailController,
                    icon: Icons.person_outline,
                    hint: "NIS / Email",
                  ),

                  const SizedBox(height: 15),

                  // ======================================================
                  // PASSWORD
                  // ======================================================
                  passwordField(),

                  const SizedBox(height: 12),

                  // ======================================================
                  // REMEMBER + LUPA PASSWORD
                  // ======================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      // INGAT SAYA
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,

                            child: Checkbox(
                              value: rememberMe,

                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value ?? false;
                                });
                              },

                              activeColor: const Color(0xff087F72),
                            ),
                          ),

                          const SizedBox(width: 8),

                          const Text(
                            "Ingat saya",

                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),

                      // LUPA PASSWORD
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Fitur lupa password belum tersedia",
                              ),
                            ),
                          );
                        },

                        child: const Text(
                          "Lupa password?",

                          style: TextStyle(
                            color: Color(0xff087F72),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ======================================================
                  // BUTTON LOGIN
                  // ======================================================
                  Container(
                    width: double.infinity,
                    height: 52,

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff62C9A9), Color(0xff087F72)],
                      ),

                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,

                        shadowColor: Colors.transparent,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),

                      onPressed: login,

                      child: const Text(
                        "Masuk",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ======================================================
                  // PEMISAH
                  // ======================================================
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),

                        child: Text(
                          "atau",

                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ======================================================
                  // LOGIN GOOGLE
                  // ======================================================
                  Container(
                    height: 50,
                    width: double.infinity,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),

                      border: Border.all(color: Colors.grey.shade300),
                    ),

                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Google Login belum tersedia"),
                          ),
                        );
                      },

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Image.asset("assets/gg.png", height: 20),

                          const SizedBox(width: 12),

                          const Text(
                            "Masuk dengan Google",

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

                  // ======================================================
                  // REGISTER
                  // ======================================================
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },

                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.grey, fontSize: 13),

                        children: [
                          TextSpan(text: "Belum punya akun? "),

                          TextSpan(
                            text: "Daftar sekarang",

                            style: TextStyle(
                              color: Color(0xff087F72),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT EMAIL / NIS
  // ============================================================
  Widget inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return TextField(
      controller: controller,

      keyboardType: TextInputType.emailAddress,

      textInputAction: TextInputAction.next,

      decoration: InputDecoration(
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

          borderSide: const BorderSide(color: Color(0xff087F72), width: 1.5),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================
  Widget passwordField() {
    return TextField(
      controller: passwordController,

      obscureText: obscurePassword,

      textInputAction: TextInputAction.done,

      onSubmitted: (value) {
        login();
      },

      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),

        hintText: "Password",

        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),

        filled: true,

        fillColor: const Color(0xffFAFAFA),

        contentPadding: const EdgeInsets.symmetric(vertical: 18),

        // ICON SHOW / HIDE PASSWORD
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

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),

          borderSide: const BorderSide(color: Color(0xff087F72), width: 1.5),
        ),
      ),
    );
  }
}
