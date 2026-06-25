class UrlHelper {
  /// Converte um link de visualização do Google Drive em um link de download direto para imagens.
  static String? convertDriveUrl(String url) {
    if (!url.contains("drive.google.com")) return url;

    final fileId = RegExp(r"d/([^/]+)").firstMatch(url)?.group(1) ??
        RegExp(r"id=([^&]+)").firstMatch(url)?.group(1);

    if (fileId != null) {
      return "https://docs.google.com/uc?export=download&id=$fileId";
    }
    return url;
  }
}
