class UrlHelper {
  /// Converte um link de visualização do Google Drive em um link de download direto para imagens.
  static String? convertDriveUrl(String url) {
    if (url.isEmpty) return url;
    
    if (!url.contains("drive.google.com") && !url.contains("photos.app.goo.gl")) return url;

    // Caso Google Drive
    if (url.contains("drive.google.com")) {
      final fileId = RegExp(r"d/([^/]+)").firstMatch(url)?.group(1) ??
          RegExp(r"id=([^&]+)").firstMatch(url)?.group(1);

      if (fileId != null) {
        return "https://docs.google.com/uc?export=download&id=$fileId";
      }
    }
    
    // Google Photos e outros links não diretos são mais complexos de converter sem API,
    // mas garantimos que ao menos o link do Drive esteja 100% funcional.

    return url;
  }
}
