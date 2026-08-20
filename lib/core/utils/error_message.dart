String appErrorMessage(Object error) {
  final text = error.toString().toLowerCase();
  final isNetworkError =
      text.contains('failed host lookup') ||
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused');

  if (isNetworkError) {
    return 'Tidak dapat terhubung ke internet. Hubungkan perangkat ke internet lalu coba lagi.';
  }

  return 'Terjadi kesalahan saat memuat data: $error';
}
