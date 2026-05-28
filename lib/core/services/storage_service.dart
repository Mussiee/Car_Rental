import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  Future<String> uploadImage(XFile file, String path) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = path.replaceAll('.jpg', '');
      final toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', uri)
        ..fields['public_id'] = publicId
        ..fields['timestamp'] = '$timestamp'
        ..fields['api_key'] = apiKey
        ..fields['signature'] = signature
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ));

      final response = await request.send();
      final body = jsonDecode(await response.stream.bytesToString());

      if (response.statusCode != 200) {
        throw Exception(body['error']?['message'] ?? 'Upload failed');
      }

      return body['secure_url'] as String;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
