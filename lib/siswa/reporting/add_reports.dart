import 'package:flutter/material.dart';

class BuatLaporanPage extends StatefulWidget {
  final bool anonim;

  const BuatLaporanPage({super.key, required this.anonim});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  String? jenisKejadian;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF7FCFA),

      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,

            right: 20,

            top: 30,

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

                  Text(
                    widget.anonim ? "Laporan Anonim" : "Buat Laporan",

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Icon(Icons.more_vert),
                ],
              ),

              const SizedBox(height: 30),

              // STEP
              Row(
                children: [
                  stepItem("1", "Informasi", true),

                  lineStep(),

                  stepItem("2", "Detail", false),

                  lineStep(),

                  stepItem("3", "Konfirmasi", false),
                ],
              ),

              const SizedBox(height: 30),

              fieldLabel("Jenis Kejadian"),

              Container(
                height: 50,

                padding: const EdgeInsets.symmetric(horizontal: 15),

                decoration: inputDecoration(),

                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,

                    hint: const Text(
                      "Pilih jenis kejadian",

                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    value: jenisKejadian,

                    items: ["Perundungan", "Kekerasan Verbal", "Konflik Teman"]
                        .map((item) {
                          return DropdownMenuItem(
                            value: item,

                            child: Text(
                              item,

                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        })
                        .toList(),

                    onChanged: (value) {
                      setState(() {
                        jenisKejadian = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              fieldLabel("Kronologi Kejadian"),

              Container(
                height: 120,

                padding: const EdgeInsets.all(15),

                decoration: inputDecoration(),

                child: const Text(
                  "Ceritakan apa yang terjadi...",

                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),

              fieldLabel("Tanggal Kejadian"),

              inputBox(Icons.calendar_today, "20 Mei 2026"),

              const SizedBox(height: 20),

              fieldLabel("Lokasi Kejadian"),

              inputBox(Icons.location_on_outlined, "Pilih lokasi", arrow: true),

              const SizedBox(height: 20),

              fieldLabel("Upload Bukti (Opsional)"),

              Container(
                height: 90,

                decoration: BoxDecoration(
                  color: const Color(0xffF0FAFF),

                  borderRadius: BorderRadius.circular(15),

                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Icon(Icons.image_outlined, color: Color(0xff009B88)),

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

              Container(
                width: double.infinity,

                height: 50,

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff35B99A), Color(0xff009B88)],
                  ),

                  borderRadius: BorderRadius.circular(25),
                ),

                child: const Center(
                  child: Text(
                    "Lanjut",

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

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Text(
        text,

        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget inputBox(IconData icon, String text, {bool arrow = false}) {
    return Container(
      height: 50,

      padding: const EdgeInsets.symmetric(horizontal: 15),

      decoration: inputDecoration(),

      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),

          const SizedBox(width: 10),

          Text(text, style: const TextStyle(fontSize: 13)),

          const Spacer(),

          if (arrow) const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  BoxDecoration inputDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(12),

      border: Border.all(color: Colors.grey.shade300),
    );
  }

  Widget stepItem(String number, String text, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 13,

          backgroundColor: active
              ? const Color(0xff009B88)
              : Colors.grey.shade300,

          child: Text(
            number,

            style: TextStyle(
              fontSize: 12,

              color: active ? Colors.white : Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          text,

          style: TextStyle(
            fontSize: 10,

            color: active ? const Color(0xff009B88) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget lineStep() {
    return Expanded(
      child: Container(height: 2, color: const Color(0xff009B88)),
    );
  }
}
