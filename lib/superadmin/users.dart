import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:ruang_aman/ipconfig.dart';
import 'package:ruang_aman/superadmin/add_edit_admin_sekolah.dart';

class PenggunaSuperadmin extends StatefulWidget {
  const PenggunaSuperadmin({super.key});

  @override
  State<PenggunaSuperadmin> createState() => _PenggunaSuperadminState();
}

class _PenggunaSuperadminState extends State<PenggunaSuperadmin> {
  // WARNA RUANGAMAN
  static const Color primaryColor = Color(0xff009B88);
  static const Color darkPrimary = Color(0xff124F4A);
  static const Color backgroundColor = Color(0xffF7FCFA);
  static const Color lightGreen = Color(0xffE9F7F1);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  // CONTROLLER, SCROLL & TIMER
  final searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  Timer? _debounce;

  // STATE PAGINATION & DATA
  List<Map<String, dynamic>> users = [];
  String selectedRole =
      ''; // '' = Semua, 'siswa' = Siswa, 'guru bk' = Guru BK, 'admin' = Admin
  bool loading = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int limitPerPage = 20;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadUsers();

    // Listener untuk Infinite Scrolling (Load More di bagian bawah)
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMoreData && !loading) {
          loadMoreUsers();
        }
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // MENAMPILKAN PESAN
  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // AMBIL JWT LANGSUNG DARI STORAGE
  Future<String> getToken() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }
    return token;
  }

  // VALIDASI RESPONSE BACKEND
  dynamic parseResponse(http.Response response) {
    dynamic result;
    try {
      result = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      throw Exception('Respons backend bukan JSON valid');
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login tidak valid atau sudah kedaluwarsa.');
    }

    if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Hanya Superadmin yang diizinkan.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (result is Map && result['success'] == false)) {
      final message = result is Map ? result['message']?.toString() : null;
      throw Exception(message ?? 'Operasi gagal (${response.statusCode})');
    }

    return result;
  }

  // AMBIL LIST PENGGUNA
  List<Map<String, dynamic>> extractUsers(dynamic result) {
    dynamic data = result;
    if (data is Map && data.containsKey('data')) {
      data = data['data'];
    }
    if (data is Map) {
      data =
          data['users'] ?? data['pengguna'] ?? data['items'] ?? data['results'];
    }
    if (data is! List) {
      throw Exception('Format daftar pengguna tidak sesuai dengan API.');
    }
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // GET DATA PENGGUNA (HALAMAN UTAMA / FILTER / SEARCH)
  // ============================================================
  Future<void> loadUsers() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
      currentPage = 1;
      hasMoreData = true;
    });

    try {
      final token = await getToken();
      final keyword = searchController.text.trim();

      final queryParams = <String, String>{
        'page': '1',
        'limit': limitPerPage.toString(),
      };
      if (selectedRole.isNotEmpty) {
        queryParams['role'] = selectedRole;
      }
      if (keyword.isNotEmpty) {
        queryParams['query'] = keyword;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/superadmin/users',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final result = parseResponse(response);
      final list = extractUsers(result);

      if (!mounted) return;

      setState(() {
        users = list;
        if (list.length < limitPerPage) {
          hasMoreData = false;
        }
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Koneksi timeout. Periksa backend.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ============================================================
  // LOAD MORE (INFINITE SCROLLING)
  // ============================================================
  Future<void> loadMoreUsers() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() => isLoadingMore = true);

    try {
      final token = await getToken();
      final keyword = searchController.text.trim();
      currentPage++;

      final queryParams = <String, String>{
        'page': currentPage.toString(),
        'limit': limitPerPage.toString(),
      };
      if (selectedRole.isNotEmpty) {
        queryParams['role'] = selectedRole;
      }
      if (keyword.isNotEmpty) {
        queryParams['query'] = keyword;
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/superadmin/users',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final result = parseResponse(response);
      final list = extractUsers(result);

      if (!mounted) return;

      setState(() {
        if (list.isEmpty) {
          hasMoreData = false;
        } else {
          users.addAll(list);
          if (list.length < limitPerPage) {
            hasMoreData = false;
          }
        }
      });
    } catch (_) {
      // Abaikan error minor saat load more agar UI tidak crash
    } finally {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  // EDIT DATA PENGGUNA
  Future<void> editUser(Map<String, dynamic> user) async {
    // Mengecek berbagai kemungkinan nama key ID dari backend
    final rawId = user['id'] ?? user['user_id'] ?? user['id_user'];
    final id = int.tryParse('$rawId') ?? rawId;

    if (id == null || '$id'.isEmpty) {
      showMessage('ID pengguna tidak valid');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditAdminSekolahPage(user: user)),
    );

    if (result == true && mounted) {
      loadUsers();
      showMessage('Pengguna berhasil diperbarui', success: true);
    }
  }

  // ============================================================
  // HAPUS PENGGUNA
  // ============================================================
  Future<void> deleteUser(Map<String, dynamic> user) async {
    if (saving) return;

    // Pengecekan ID secara aman dari berbagai variasi key backend
    final rawId = user['id'] ?? user['user_id'] ?? user['id_user'];
    final id = int.tryParse('$rawId') ?? rawId;

    if (id == null || '$id'.isEmpty) {
      showMessage('ID pengguna tidak valid');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus ${user['nama'] ?? 'pengguna ini'}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => saving = true);

    try {
      final token = await getToken();
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/superadmin/users/$id'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      parseResponse(response);
      if (!mounted) return;

      showMessage('Pengguna berhasil dihapus', success: true);
      await loadUsers(); // Refresh daftar pengguna setelah dihapus
    } on TimeoutException {
      showMessage('Koneksi timeout. Periksa backend.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ============================================================
  // CARD PENGGUNA
  // ============================================================
  Widget userCard(Map<String, dynamic> user) {
    final nama = '${user['nama'] ?? '-'}';
    final email = '${user['email'] ?? '-'}';
    final roleRaw = '${user['role'] ?? 'siswa'}'.toLowerCase();

    Color badgeBg = const Color(0xffE8F1FF);
    Color badgeTextColor = const Color(0xff3B82F6);
    String roleLabel = 'Siswa';

    if (roleRaw.contains('admin')) {
      badgeBg = const Color(0xffFDECEC);
      badgeTextColor = Colors.red;
      roleLabel = 'Admin';
    } else if (roleRaw.contains('guru') || roleRaw.contains('bk')) {
      badgeBg = const Color(0xffFFF4E1);
      badgeTextColor = const Color(0xffF59E0B);
      roleLabel = 'Guru BK';
    } else {
      badgeBg = const Color(0xffE8F1FF);
      badgeTextColor = const Color(0xff3B82F6);
      roleLabel = 'Siswa';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // MENGGUNAKAN EXPANDED AGAR TEKS MENYESUAIKAN RUANG TERSISA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.grey,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                editUser(user);
              } else if (value == 'delete') {
                deleteUser(user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRoleFilterButton(String label, String roleValue) {
    final isSelected = selectedRole == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = roleValue;
        });
        loadUsers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xffEDF5F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff34403D),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadUsers,
          child: ListView.builder(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            itemCount: users.length + 2 + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 0: Header & Search & Filter Pill
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar Pengguna',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: darkPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kelola pengguna pada setiap sekolah.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton.filled(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditAdminSekolahPage(),
                              ),
                            );
                            if (result == true && mounted) {
                              loadUsers();
                              showMessage(
                                'Admin sekolah berhasil ditambahkan',
                                success: true,
                              );
                            }
                          },

                          icon: const Icon(Icons.add, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 500),
                          () {
                            loadUsers();
                          },
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau email...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  loadUsers();
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildRoleFilterButton('Semua', ''),
                          const SizedBox(width: 8),
                          buildRoleFilterButton('Siswa', 'siswa'),
                          const SizedBox(width: 8),
                          buildRoleFilterButton('Guru BK', 'guru bk'),
                          const SizedBox(width: 8),
                          buildRoleFilterButton('Admin', 'admin'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              // 1: Loading / Error / Empty State
              if (index == 1) {
                if (loading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(35),
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                }
                if (error != null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xffFDECEC),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Belum ada pengguna',
                        style: TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              // Item list pengguna
              int userIndex = index - 2;
              if (userIndex < users.length) {
                return userCard(users[userIndex]);
              }

              // Loading indicator tambahan saat scroll di bawah (Load More)
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
