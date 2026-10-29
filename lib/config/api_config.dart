class ApiConfig {
  static String baseUrl = 'http://10.102.144.91:8000';

  static void setApiBaseUrl(String ipAddress) {
    baseUrl = 'http://$ipAddress:8000';
  }
}