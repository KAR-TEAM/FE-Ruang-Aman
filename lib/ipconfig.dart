class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';

  //Auth
  static const String register = '$baseUrl/api/auth/register';
  static const String login = '$baseUrl/api/auth/login';

  // Admin
    static const String superadminStats =
      '$baseUrl/api/superadmin/schools-stats';
    static const String schools =
      '$baseUrl/api/superadmin/schools';
    static const String searchSchools =
      '$baseUrl/api/superadmin/search';
    static String schoolById(dynamic id) =>
      '$schools/$id';
    static const String adminSchools =
      '$baseUrl/api/superadmin/admin-schools';
    static const String users =
      '$baseUrl/api/superadmin/users';
     static String userById(dynamic id) =>
      '$users/$id';

  // Siswa
    static const String dashboardSiswa =
        '$baseUrl/api/reports/dashboard-siswa';
    static const String myReports =
        '$baseUrl/api/reports/my-reports';
    static const String createReport =
        '$baseUrl/api/reports/';

  // Guru
    static const String bkDashboardStats =
        '$baseUrl/api/bk/dashboard/stats';
    static const String bkReports =
        '$baseUrl/api/bk/reports';
    static String bkReportFollowups(dynamic id) =>
        '$baseUrl/api/bk/reports/${Uri.encodeComponent(id.toString())}/followups';
}