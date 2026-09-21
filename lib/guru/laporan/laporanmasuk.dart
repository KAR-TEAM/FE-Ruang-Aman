import 'package:flutter/material.dart';

class LaporanMasukPage extends StatefulWidget {
  const LaporanMasukPage({super.key});

  @override
  State<LaporanMasukPage> createState() => _LaporanMasukPageState();
}

class _LaporanMasukPageState extends State<LaporanMasukPage> {
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);

  String selectedFilter = "Semua";

  bool showSearch = false;

  final TextEditingController searchController =
      TextEditingController();

  // ============================================================
  // DATA DUMMY LAPORAN
  // ============================================================
  final List<Map<String, String>> laporan = [
    {
      "id": "RA-2026-0012",
      "judul": "Perundungan",
      "tanggal": "20 Mei 2026, 10:30",
      "pelapor": "Anonim",
      "risiko": "Tinggi",
      "status": "Sedang Ditangani",
    },
    {
      "id": "RA-2026-0011",
      "judul": "Kekerasan Verbal",
      "tanggal": "20 Mei 2026, 09:15",
      "pelapor": "Dimas A. (XI IPA 1)",
      "risiko": "Sedang",
      "status": "Baru",
    },
    {
      "id": "RA-2026-0010",
      "judul": "Konflik Teman",
      "tanggal": "19 Mei 2026, 14:20",
      "pelapor": "Siti N. (XI IPA 2)",
      "risiko": "Rendah",
      "status": "Selesai",
    },
    {
      "id": "RA-2026-0009",
      "judul": "Perundungan di Kelas",
      "tanggal": "19 Mei 2026, 11:05",
      "pelapor": "Anonim",
      "risiko": "Tinggi",
      "status": "Baru",
    },
    {
      "id": "RA-2026-0008",
      "judul": "Masalah Pertemanan",
      "tanggal": "18 Mei 2026, 08:45",
      "pelapor": "Raka P. (XI IPS 1)",
      "risiko": "Sedang",
      "status": "Sedang Ditangani",
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER DATA
  // ============================================================
  List<Map<String, String>> get filteredLaporan {
    return laporan.where((item) {
      final cocokFilter =
          selectedFilter == "Semua" ||
          item["risiko"] == selectedFilter;

      final keyword =
          searchController.text.toLowerCase();

      final cocokSearch =
          keyword.isEmpty ||
          item["judul"]!
              .toLowerCase()
              .contains(keyword) ||
          item["id"]!
              .toLowerCase()
              .contains(keyword) ||
          item["pelapor"]!
              .toLowerCase()
              .contains(keyword);

      return cocokFilter && cocokSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,

      child: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                0,
              ),

              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Laporan Masuk",

                      style: TextStyle(
                        decoration:
                            TextDecoration.none,
                        fontSize: 23,
                        fontWeight:
                            FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                  ),

                  // SEARCH
                  _headerButton(
                    icon: Icons.search_rounded,
                    onTap: () {
                      setState(() {
                        showSearch =
                            !showSearch;

                        if (!showSearch) {
                          searchController
                              .clear();
                        }
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  // FILTER
                  _headerButton(
                    icon:
                        Icons.tune_rounded,
                    onTap: () {
                      _showFilterSheet();
                    },
                  ),
                ],
              ),
            ),

            // ====================================================
            // SEARCH FIELD
            // ====================================================
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 200,
              ),

              child: showSearch
                  ? Padding(
                      key: const ValueKey(
                        "search",
                      ),

                      padding:
                          const EdgeInsets.fromLTRB(
                            20,
                            18,
                            20,
                            0,
                          ),

                      child: TextField(
                        controller:
                            searchController,

                        onChanged: (_) {
                          setState(() {});
                        },

                        decoration:
                            InputDecoration(
                              hintText:
                                  "Cari laporan...",

                              hintStyle:
                                  const TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        Colors.grey,
                                  ),

                              prefixIcon:
                                  const Icon(
                                    Icons
                                        .search_rounded,
                                    color:
                                        Colors.grey,
                                  ),

                              suffixIcon:
                                  searchController
                                          .text
                                          .isNotEmpty
                                      ? IconButton(
                                          onPressed:
                                              () {
                                            searchController
                                                .clear();

                                            setState(
                                              () {},
                                            );
                                          },

                                          icon:
                                              const Icon(
                                                Icons
                                                    .close_rounded,
                                              ),
                                        )
                                      : null,

                              filled: true,
                              fillColor:
                                  Colors
                                      .white,

                              contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                        vertical:
                                            14,
                                      ),

                              enabledBorder:
                                  OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                              15,
                                            ),

                                    borderSide:
                                        const BorderSide(
                                          color:
                                              Color(
                                                0xffE2E8E5,
                                              ),
                                        ),
                                  ),

                              focusedBorder:
                                  OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                              15,
                                            ),

                                    borderSide:
                                        const BorderSide(
                                          color:
                                              primaryColor,
                                          width:
                                              1.4,
                                        ),
                                  ),
                            ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey(
                        "no-search",
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // FILTER TABS
            // ====================================================
            SizedBox(
              height: 42,

              child: ListView(
                scrollDirection:
                    Axis.horizontal,

                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                children: [
                  _filterButton(
                    "Semua",
                  ),

                  _filterButton(
                    "Tinggi",
                  ),

                  _filterButton(
                    "Sedang",
                  ),

                  _filterButton(
                    "Rendah",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // ====================================================
            // TOTAL LAPORAN
            // ====================================================
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),

              child: Row(
                children: [
                  Text(
                    "${filteredLaporan.length} laporan ditemukan",

                    style: const TextStyle(
                      decoration:
                          TextDecoration.none,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // ====================================================
            // LIST LAPORAN
            // ====================================================
            Expanded(
              child:
                  filteredLaporan.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            100,
                          ),

                      itemCount:
                          filteredLaporan
                              .length,

                      separatorBuilder:
                          (
                            context,
                            index,
                          ) =>
                              const SizedBox(
                                height: 12,
                              ),

                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                            final item =
                                filteredLaporan[index];

                            return _laporanCard(
                              item,
                            );
                          },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER BUTTON
  // ============================================================
  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(13),

        onTap: onTap,

        child: Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(13),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withAlpha(
                      8,
                    ),

                blurRadius: 8,

                offset:
                    const Offset(0, 3),
              ),
            ],
          ),

          child: Icon(
            icon,
            color:
                const Color(0xff5D6966),
            size: 22,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================
  Widget _filterButton(
    String label,
  ) {
    final bool active =
        selectedFilter == label;

    return Padding(
      padding:
          const EdgeInsets.only(
            right: 8,
          ),

      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = label;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          padding:
              const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),

          decoration: BoxDecoration(
            color: active
                ? primaryColor
                : Colors.white,

            borderRadius:
                BorderRadius.circular(12),

            border: Border.all(
              color: active
                  ? primaryColor
                  : const Color(
                      0xffE5EBE8,
                    ),
            ),

            boxShadow: active
                ? [
                    BoxShadow(
                      color:
                          primaryColor
                              .withAlpha(
                                35,
                              ),

                      blurRadius: 8,

                      offset:
                          const Offset(
                            0,
                            3,
                          ),
                    ),
                  ]
                : [],
          ),

          child: Text(
            label,

            style: TextStyle(
              decoration:
                  TextDecoration.none,

              color: active
                  ? Colors.white
                  : const Color(
                      0xff68736F,
                    ),

              fontSize: 12,

              fontWeight: active
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LAPORAN CARD
  // ============================================================
  Widget _laporanCard(
    Map<String, String> item,
  ) {
    final riskStyle =
        _riskStyle(
          item["risiko"]!,
        );

    final statusStyle =
        _statusStyle(
          item["status"]!,
        );

    return GestureDetector(
      onTap: () {
        // Detail laporan nanti
        _showDetail(item);
      },

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(
          17,
        ),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color:
                const Color(
                  0xffEEF2F0,
                ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withAlpha(
                    7,
                  ),

              blurRadius: 10,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ID + RISIKO
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                Text(
                  item["id"]!,

                  style: const TextStyle(
                    decoration:
                        TextDecoration.none,

                    fontSize: 13,

                    fontWeight:
                        FontWeight.bold,

                    color:
                        Color(
                          0xff263330,
                        ),
                  ),
                ),

                _badge(
                  text:
                      item["risiko"]!,
                  background:
                      riskStyle[
                              "background"]
                          as Color,

                  textColor:
                      riskStyle[
                              "text"]
                          as Color,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // JUDUL
            Text(
              item["judul"]!,

              style: const TextStyle(
                decoration:
                    TextDecoration.none,

                fontSize: 15,

                fontWeight:
                    FontWeight.w700,

                color:
                    Color(
                      0xff263330,
                    ),
              ),
            ),

            const SizedBox(height: 7),

            // TANGGAL
            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,

                  size: 14,

                  color: Colors.grey,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  item["tanggal"]!,

                  style: const TextStyle(
                    decoration:
                        TextDecoration.none,

                    fontSize: 11,

                    color:
                        Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            // PELAPOR + STATUS
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .person_outline,

                        size: 15,

                        color:
                            Colors.grey,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Expanded(
                        child: Text(
                          item["pelapor"]!,

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                                decoration:
                                    TextDecoration
                                        .none,

                                fontSize:
                                    11.5,

                                color:
                                    Color(
                                      0xff66706D,
                                    ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _badge(
                  text:
                      item["status"]!,

                  background:
                      statusStyle[
                              "background"]
                          as Color,

                  textColor:
                      statusStyle[
                              "text"]
                          as Color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================
  Widget _badge({
    required String text,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

      decoration: BoxDecoration(
        color: background,

        borderRadius:
            BorderRadius.circular(15),
      ),

      child: Text(
        text,

        style: TextStyle(
          decoration:
              TextDecoration.none,

          fontSize: 9.5,

          fontWeight:
              FontWeight.w600,

          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // WARNA RISIKO
  // ============================================================
  Map<String, Color> _riskStyle(
    String risk,
  ) {
    switch (risk) {
      case "Tinggi":
        return {
          "background":
              const Color(
                0xffFDE8E8,
              ),

          "text":
              const Color(
                0xffEF4444,
              ),
        };

      case "Sedang":
        return {
          "background":
              const Color(
                0xffFFF3DC,
              ),

          "text":
              const Color(
                0xffF59E0B,
              ),
        };

      case "Rendah":
        return {
          "background":
              const Color(
                0xffE5F7EE,
              ),

          "text":
              const Color(
                0xff16A66A,
              ),
        };

      default:
        return {
          "background":
              Colors.grey.shade100,

          "text":
              Colors.grey,
        };
    }
  }

  // ============================================================
  // WARNA STATUS
  // ============================================================
  Map<String, Color> _statusStyle(
    String status,
  ) {
    switch (status) {
      case "Baru":
        return {
          "background":
              const Color(
                0xffE6F7EF,
              ),

          "text":
              const Color(
                0xff16A66A,
              ),
        };

      case "Sedang Ditangani":
        return {
          "background":
              const Color(
                0xffE8F1FF,
              ),

          "text":
              const Color(
                0xff3B82F6,
              ),
        };

      case "Selesai":
        return {
          "background":
              const Color(
                0xffF0F2F1,
              ),

          "text":
              const Color(
                0xff66706D,
              ),
        };

      default:
        return {
          "background":
              Colors.grey.shade100,

          "text":
              Colors.grey,
        };
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 75,
            height: 75,

            decoration: const BoxDecoration(
              color:
                  Color(
                    0xffE9F7F1,
                  ),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .description_outlined,

              color: primaryColor,

              size: 35,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            "Laporan tidak ditemukan",

            style: TextStyle(
              decoration:
                  TextDecoration.none,

              fontSize: 15,

              fontWeight:
                  FontWeight.bold,

              color: darkPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Coba gunakan filter lainnya.",

            style: TextStyle(
              decoration:
                  TextDecoration.none,

              fontSize: 12,

              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BOTTOM SHEET
  // ============================================================
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.transparent,

      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.all(
                20,
              ),

          decoration:
              const BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.only(
                      topLeft:
                          Radius.circular(
                            25,
                          ),

                      topRight:
                          Radius.circular(
                            25,
                          ),
                    ),
              ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,

                  decoration:
                      BoxDecoration(
                        color:
                            Colors.grey
                                .shade300,

                        borderRadius:
                            BorderRadius
                                .circular(
                                  5,
                                ),
                      ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Filter Laporan",

                style: TextStyle(
                  fontSize: 18,

                  fontWeight:
                      FontWeight.bold,

                  color: darkPrimary,
                ),
              ),

              const SizedBox(height: 15),

              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading: const Icon(
                  Icons
                      .priority_high_rounded,

                  color:
                      Color(
                        0xffEF4444,
                      ),
                ),

                title: const Text(
                  "Risiko Tinggi",
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  setState(() {
                    selectedFilter =
                        "Tinggi";
                  });
                },
              ),

              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading: const Icon(
                  Icons
                      .remove_circle_outline,

                  color:
                      Color(
                        0xffF59E0B,
                      ),
                ),

                title: const Text(
                  "Risiko Sedang",
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  setState(() {
                    selectedFilter =
                        "Sedang";
                  });
                },
              ),

              ListTile(
                contentPadding:
                    EdgeInsets.zero,

                leading: const Icon(
                  Icons
                      .check_circle_outline,

                  color:
                      Color(
                        0xff16A66A,
                      ),
                ),

                title: const Text(
                  "Risiko Rendah",
                ),

                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  setState(() {
                    selectedFilter =
                        "Rendah";
                  });
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL DUMMY
  // ============================================================
  void _showDetail(
    Map<String, String> item,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
                22,
                15,
                22,
                30,
              ),

          decoration:
              const BoxDecoration(
                color:
                    Color(
                      0xffF7FCFA,
                    ),

                borderRadius:
                    BorderRadius.only(
                      topLeft:
                          Radius.circular(
                            25,
                          ),

                      topRight:
                          Radius.circular(
                            25,
                          ),
                    ),
              ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,

                  decoration:
                      BoxDecoration(
                        color:
                            Colors.grey
                                .shade300,

                        borderRadius:
                            BorderRadius
                                .circular(
                                  10,
                                ),
                      ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                item["id"]!,

                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                item["judul"]!,

                style: const TextStyle(
                  fontSize: 20,

                  fontWeight:
                      FontWeight.bold,

                  color: darkPrimary,
                ),
              ),

              const SizedBox(height: 20),

              _detailRow(
                "Tanggal",
                item["tanggal"]!,
              ),

              _detailRow(
                "Pelapor",
                item["pelapor"]!,
              ),

              _detailRow(
                "Prioritas",
                item["risiko"]!,
              ),

              _detailRow(
                "Status",
                item["status"]!,
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,

                height: 48,

                child:
                    ElevatedButton(
                      style:
                          ElevatedButton
                              .styleFrom(
                                backgroundColor:
                                    primaryColor,

                                foregroundColor:
                                    Colors.white,

                                shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                            25,
                                          ),
                                    ),
                              ),

                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child:
                          const Text(
                            "Lihat Detail Laporan",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
            bottom: 12,
          ),

      child: Row(
        children: [
          SizedBox(
            width: 90,

            child: Text(
              title,

              style: const TextStyle(
                fontSize: 12,

                color:
                    Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style:
                  const TextStyle(
                    fontSize: 12,

                    fontWeight:
                        FontWeight
                            .w600,

                    color:
                        Color(
                          0xff34403D,
                        ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}