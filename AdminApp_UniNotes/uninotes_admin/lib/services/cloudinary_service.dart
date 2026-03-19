import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dxnmo1cin";
  static const String uploadPreset = "uninotes_covers";

  static Future<String> uploadImage(File file) async {
    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..fields["folder"] = "skriptarnica_products"
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Cloudinary upload failed: $body");
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data["secure_url"] as String;
  }
}
