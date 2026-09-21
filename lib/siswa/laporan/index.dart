import 'package:flutter/material.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int selectedTab = 0;

  final List<String> tabs = ["Semua", "Diproses", "Selesai"];

  final List<Map<String, dynamic>> laporan = [
    {
      "id": "RA-2026-0012",
      "judul": "Perundungan",
      "tanggal": "20 Mei 2026, 10:30",
      "status": "Sedang Ditangani",
    },

    {
      "id": "RA-2026-0011",
      "judul": "Kekerasan Verbal",
      "tanggal": "16 Mei 2026, 09:15",
      "status": "Diproses",
    },

    {
      "id": "RA-2026-0010",
      "judul": "Konflik Teman",
      "tanggal": "12 Mei 2026, 14:20",
      "status": "Selesai",
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> data;

    if (selectedTab == 0) {
      data = laporan;
    } else if (selectedTab == 1) {
      data = laporan.where((item) => item["status"] != "Selesai").toList();
    } else {
      data = laporan.where((item) => item["status"] == "Selesai").toList();
    }

    return Container(
      color: const Color(0xffF7FCFA),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,

            right: 20,

            top: 40,

            bottom: 20,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Laporan Saya",

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  Row(
                    children: [
                      const Icon(Icons.search, size: 26),

                      const SizedBox(width: 12),

                      const Icon(Icons.filter_alt_outlined, size: 24),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TAB
              Row(
                children: List.generate(tabs.length, (index) {
                  bool active = selectedTab == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = index;
                      });
                    },

                    child: Container(
                      margin: const EdgeInsets.only(right: 8),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,

                        vertical: 9,
                      ),

                      decoration: BoxDecoration(
                        color: active ? const Color(0xff009B88) : Colors.white,

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        tabs[index],

                        style: TextStyle(
                          fontSize: 12,

                          color: active ? Colors.white : Colors.grey.shade700,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // LIST LAPORAN
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,

                  itemBuilder: (context, index) {
                    final item = data[index];

                    return laporanCard(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget laporanCard(Map<String, dynamic> item) {
    bool selesai = item["status"] == "Selesai";

    bool ditangani = item["status"] == "Sedang Ditangani";

    return Container(
      margin: const EdgeInsets.only(bottom: 25),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                item["id"],

                style: const TextStyle(
                  fontSize: 14,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                item["judul"],

                style: const TextStyle(
                  fontSize: 13,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                item["tanggal"],

                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

            decoration: BoxDecoration(
              color: selesai ? Colors.green.shade100 : Colors.orange.shade100,

              borderRadius: BorderRadius.circular(12),
            ),

            child: Text(
              item["status"],

              style: TextStyle(
                fontSize: 10,

                color: selesai ? Colors.green : Colors.orange,

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
