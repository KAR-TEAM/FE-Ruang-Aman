import 'package:flutter/material.dart';

class RegisterGuru extends StatelessWidget {
  const RegisterGuru({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FCFA),

      body: Stack(
        children: [
          // DECORATION
          Positioned(
            top: -60,

            right: -50,

            child: Container(
              width: 170,

              height: 170,

              decoration: BoxDecoration(
                color: const Color(0xffDDF3EC),

                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -40,

            left: -40,

            child: Container(
              width: 130,

              height: 130,

              decoration: BoxDecoration(
                color: const Color(0xffE7F7F2),

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
                    "Lengkapi data untuk mendampingi siswa dengan layanan konseling terbaik",

                    style: TextStyle(
                      color: Colors.grey,

                      fontSize: 14,

                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),

                  input("Nama Lengkap", Icons.person_outline),

                  input("NIP / ID Guru", Icons.badge_outlined),

                  input("Email", Icons.email_outlined),

                  input("Password", Icons.lock_outline, password: true),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),

                          blurRadius: 15,
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Data Sekolah",

                          style: TextStyle(
                            fontSize: 17,

                            fontWeight: FontWeight.bold,

                            color: Color(0xff124F4A),
                          ),
                        ),

                        const SizedBox(height: 15),

                        input("Nama Sekolah", Icons.school_outlined),

                        input("Alamat Sekolah", Icons.location_on_outlined),

                        input("Kode Sekolah", Icons.qr_code_2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  button(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget input(String hint, IconData icon, {bool password = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: TextField(
        obscureText: password,

        decoration: InputDecoration(
          hintText: hint,

          prefixIcon: Icon(icon, color: const Color(0xff087F72)),

          filled: true,

          fillColor: const Color(0xffFAFAFA),

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

  Widget button() {
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,

          shadowColor: Colors.transparent,
        ),

        onPressed: () {},

        child: const Text(
          "Daftar Sekarang",

          style: TextStyle(
            color: Colors.white,

            fontSize: 16,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
