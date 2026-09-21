import 'package:flutter/material.dart';

class RegisterSiswa extends StatefulWidget {
  const RegisterSiswa({super.key});

  @override
  State<RegisterSiswa> createState() => _RegisterSiswaState();
}

class _RegisterSiswaState extends State<RegisterSiswa> {
  String? guruDipilih;

  final List<Map<String, String>> guruBK = [
    {"nama": "Siti Rahma, S.Psi", "sekolah": "SMA Negeri 1 Bandung"},

    {"nama": "Budi Santoso, S.Pd", "sekolah": "SMK Informatika"},

    {"nama": "Ahmad Fauzi, M.Psi", "sekolah": "SMA Harapan Bangsa"},
  ];

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

                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 35),

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

                    child: SizedBox(
                      width: double.infinity,

                      child: Text(
                        guru["nama"]!,

                        overflow: TextOverflow.ellipsis,

                        maxLines: 1,

                        style: const TextStyle(fontSize: 14),
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

              // DETAIL GURU BK
              if (guruDipilih != null)
                Container(
                  margin: const EdgeInsets.only(top: 15),

                  padding: const EdgeInsets.all(15),

                  decoration: BoxDecoration(
                    color: const Color(0xffE7F7F2),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xff087F72)),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          "${guruDipilih}\n${guruBK.firstWhere((e) => e['nama'] == guruDipilih)['sekolah']}",

                          style: const TextStyle(
                            fontSize: 13,

                            color: Color(0xff124F4A),

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              input("Nama Lengkap", Icons.person_outline),

              input("NIS", Icons.badge_outlined),

              input("Email", Icons.email_outlined),

              input("Password", Icons.lock_outline, password: true),

              const SizedBox(height: 10),

              button(),
            ],
          ),
        ),
      ),
    );
  }

  Widget input(String hint, IconData icon, {bool password = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: TextField(
        obscureText: password,

        decoration: inputDecoration(hint, icon),
      ),
    );
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(icon, color: const Color(0xff087F72)),

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
