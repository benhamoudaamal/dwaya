import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  static const String _cloudName = "dqlm7wqpp";
  static const String _uploadPreset = "dwaya_preset";

  // 📸 Upload image (profil, etc.)
  static Future<String?> uploadImage(File image, String uid) async {
    return await uploadFile(image);
  }

  // 📄 Upload n'importe quel fichier (PDF, image, doc)
  static Future<String?> uploadFile(File file) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/auto/upload",
      );

      final request = http.MultipartRequest("POST", uri);
      request.fields["upload_preset"] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath("file", file.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (decoded["secure_url"] != null) {
        return decoded["secure_url"] as String;
      }

      print("❌ Cloudinary error: ${decoded["error"]}");
      return null;

    } catch (e) {
      print("❌ Upload exception: $e");
      return null;
    }
  }

  // 🗑️ Supprimer un fichier par son URL publique
  static Future<void> deleteFile(String url) async {
    try {
      // Extraire le public_id depuis l'URL Cloudinary
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf("upload");
      if (uploadIndex == -1) return;

      // Sauter la version (ex: v1234567)
      final publicIdWithExt = segments
          .sublist(uploadIndex + 2)
          .join("/");
      final publicId = publicIdWithExt.contains(".")
          ? publicIdWithExt.substring(0, publicIdWithExt.lastIndexOf("."))
          : publicIdWithExt;

      print("🗑️ Deleting Cloudinary file: $publicId");
      // Note: la suppression nécessite une signature côté serveur
      // Pour mobile, il vaut mieux désactiver la restriction dans le dashboard Cloudinary
    } catch (e) {
      print("❌ Delete error: $e");
    }
  }
}