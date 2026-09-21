import 'package:flutter/material.dart';

class BuatLaporanDataPage extends StatefulWidget {
  const BuatLaporanDataPage({super.key});

  @override
  State<BuatLaporanDataPage> createState() => _BuatLaporanDataPageState();
}

class _BuatLaporanDataPageState extends State<BuatLaporanDataPage> {
  String? jenis;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF7FCFA),

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,

            right: 20,

            top: 25,

            bottom: 40,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },

                    child: const Icon(Icons.arrow_back, size: 24),
                  ),

                  const Text(
                    "Buat Laporan",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const Icon(Icons.help_outline, color: Color(0xff009B88)),
                ],
              ),

              const SizedBox(height: 25),

              // INFO CARD
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: const Color(0xffE9F7F1),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 45,

                      height: 45,

                      decoration: BoxDecoration(
                        color: const Color(0xff009B88).withOpacity(.15),

                        borderRadius: BorderRadius.circular(15),
                      ),

                      child: const Icon(
                        Icons.person_outline,

                        color: Color(0xff009B88),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Text(
                        "Laporan menggunakan data diri. Informasi kamu akan diketahui oleh Guru BK untuk proses tindak lanjut.",

                        style: TextStyle(
                          fontSize: 13,

                          color: Color(0xff355B53),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              formLabel("Nama Lengkap"),

              inputBox(Icons.person_outline, "Masukkan nama lengkap"),

              const SizedBox(height: 18),

              formLabel("Kelas"),

              inputBox(Icons.school_outlined, "XI IPA 2"),

              const SizedBox(height: 18),

              formLabel("Nomor HP"),

              inputBox(Icons.phone_outlined, "Masukkan nomor HP"),

              const SizedBox(height: 25),

              formLabel("Jenis Kejadian"),

              Container(
                height: 52,

                padding: const EdgeInsets.symmetric(horizontal: 15),

                decoration: inputDecoration(),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,

                    hint: const Text(
                      "Pilih jenis kejadian",

                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    value: jenis,

                    items:
                        [
                          "Perundungan",

                          "Kekerasan Verbal",

                          "Konflik Teman",

                          "Ancaman",
                        ].map((item) {
                          return DropdownMenuItem(
                            value: item,

                            child: Text(
                              item,

                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),

                    onChanged: (value) {
                      setState(() {
                        jenis = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              formLabel("Kronologi Kejadian"),

              Container(
                height: 130,

                padding: const EdgeInsets.all(15),

                decoration: inputDecoration(),

                child: const Text(
                  "Ceritakan apa yang terjadi...",

                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              formLabel("Upload Bukti (Opsional)"),

              Container(
                height: 90,

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,

                        color: Color(0xff009B88),

                        size: 30,
                      ),

                      SizedBox(height: 5),

                      Text(
                        "Tambah foto atau video",

                        style: TextStyle(
                          fontSize: 12,

                          color: Color(0xff009B88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // BUTTON
              Container(
                height: 52,

                width: double.infinity,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff35B99A), Color(0xff009B88)],
                  ),

                  borderRadius: BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff009B88).withOpacity(.25),

                      blurRadius: 10,

                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: const Center(
                  child: Text(
                    "Kirim Laporan",

                    style: TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        text,

        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget inputBox(IconData icon, String text) {
    return Container(
      height: 52,

      padding: const EdgeInsets.symmetric(horizontal: 15),

      decoration: inputDecoration(),

      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),

          const SizedBox(width: 10),

          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  BoxDecoration inputDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(15),

      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
