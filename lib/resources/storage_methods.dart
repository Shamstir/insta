import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class StorageMethods {

  static const String _cloudName = '';
  static const String _apiKey = '';
  static const String _apiSecret = '';
  static const String _uploadPreset = '';

  // Generate signature for authenticated uploads
  String _generateSignature(Map<String, dynamic> params, String apiSecret) {
    // Sort parameters
    var sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );

    // Create query string
    String queryString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    queryString += apiSecret;

    // Generate SHA1 hash
    var bytes = utf8.encode(queryString);
    var digest = sha1.convert(bytes);

    return digest.toString();
  }

  // Upload image to Cloudinary - same interface as Firebase
  Future<String> uploadImageToStorage(String childName, Uint8List file, bool isPost) async {
    try {
      // Validate file size
      if (file.length > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('File size too large. Maximum size is 10MB');
      }

      // Generate filename
      String fileName = isPost
          ? 'post_${const Uuid().v1()}'
          : 'profile_${DateTime.now().millisecondsSinceEpoch}';

      // Prepare upload parameters
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      Map<String, dynamic> params = {
        'timestamp': timestamp,
        'folder': childName,
        'public_id': fileName,
      };

      // Generate signature
      String signature = _generateSignature(params, _apiSecret);

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file,
          filename: '$fileName.jpg',
        ),
      );

      // Add form fields
      request.fields['api_key'] = _apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['folder'] = childName;
      request.fields['public_id'] = fileName;
      request.fields['signature'] = signature;

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return responseData['secure_url']; // Return the HTTPS URL
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception('Cloudinary error: ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Alternative: Unsigned upload (simpler, but requires upload preset)
  Future<String> uploadImageUnsigned(String childName, Uint8List file, bool isPost) async {
    try {
      if (_uploadPreset.isEmpty) {
        throw Exception('Upload preset required for unsigned uploads');
      }

      // Validate file size
      if (file.length > 10 * 1024 * 1024) {
        throw Exception('File size too large. Maximum size is 10MB');
      }

      // Generate filename
      String fileName = isPost
          ? 'post_${const Uuid().v1()}'
          : 'profile_${DateTime.now().millisecondsSinceEpoch}';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
      );

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file,
          filename: '$fileName.jpg',
        ),
      );

      // Add form fields
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = childName;
      request.fields['public_id'] = fileName;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        return responseData['secure_url'];
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception('Cloudinary error: ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}