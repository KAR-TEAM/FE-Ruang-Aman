import 'package:flutter/material.dart';

class BuatLaporanAnonimPage extends StatefulWidget {
  const BuatLaporanAnonimPage({super.key});

  @override
  State<BuatLaporanAnonimPage> createState() => _BuatLaporanAnonimPageState();
}

class _BuatLaporanAnonimPageState extends State<BuatLaporanAnonimPage> {
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
                    "Laporan Anonim",

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
                        Icons.visibility_off_outlined,

                        color: Color(0xff009B88),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Text(
                        "Laporan kamu bersifat anonim. Identitas tidak akan diketahui oleh pihak sekolah.",

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
                        ].map((e) {
                          return DropdownMenuItem(
                            value: e,

                            child: Text(
                              e,

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

                  style: TextStyle(color: Colors.grey, fontSize: 13),
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

  BoxDecoration inputDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(15),

      border: Border.all(color: Colors.grey.shade300),
    );
  }
}
