import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FaceSwapBackend {
  // Your Render backend URL
  static const _url = "https://face-swap-backend-xwrv.onrender.com/swap_faces";

  /// Swaps faces between [targetImage] and [sourceImage].
  /// Returns the swapped image as a Uint8List ready for Image.memory().
  static Future<Uint8List?> swapFaces(File targetImage, File sourceImage) async {
    print('🔄 Swapping faces...');
    print('Target: ${targetImage.path}');
    print('Source: ${sourceImage.path}');

    final request = http.MultipartRequest("POST", Uri.parse(_url))
      ..files.add(await http.MultipartFile.fromPath('target', targetImage.path))
      ..files.add(await http.MultipartFile.fromPath('source', sourceImage.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('HTTP Status: ${response.statusCode}');
      print('Response: $responseBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);

        if (jsonData.containsKey('result')) {
          // Decode base64 string to bytes
          final base64Image = jsonData['result'] as String;
          final Uint8List imageBytes = base64Decode(base64Image);
          print('✅ Face swap successful, image bytes length: ${imageBytes.length}');
          return imageBytes;
        } else if (jsonData.containsKey('error')) {
          print('❌ Backend Error: ${jsonData['error']}');
          return null;
        } else {
          print('❌ Unexpected backend response');
          return null;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return null;
    }
  }
}
