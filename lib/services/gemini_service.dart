import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';


/// Generates a family photo by combining two images using the Gemini AI API.
///
/// This method takes a base image and a child image, then uses the Gemini AI model
/// to create a composite family photo that incorporates elements from both images.
///
/// Parameters:
/// - [baseImageBase64]: Base64 encoded string of the main image (likely containing grandma and living room)
/// - [childImageBase64]: Base64 encoded string of the child image (to be inserted into the family photo)
///
/// Returns:
/// - A Future that completes with a String containing the base64 encoded generated image,
///   or null if the g
  ///   eneration fails.

  static Future<String?> generateFamilyPhotoFromCarton({
    required String baseImageBase64,  // Base64 string of the main image
    required String childImageBase64,  // Base64 string of the child image to be added
  }) async
  {

    // API configuration
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';  // Gemini API key
    // API endpoint URL for image generation
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    // HTTP headers for the API request
    var headers = {
      'x-goog-api-key': apiKey,  // Authentication header
      'Content-Type': 'application/json',  // Content type specification
    };

    // Request body containing the images and generation instructions
    var body = json.encode({
      "contents": [
        {
          "parts": [
            // First image (base image)
            {
              "inlineData": {
                "mimeType": "image/png",  // MIME type for the base image
                "data": baseImageBase64,  // Base64 encoded image data
              }
            },
            // Text prompt for image generation
            {
              "text":
              "Just replace the girl with red dress in the first image by the girl from second image to make full-body cartoon-style shot of the grandma, the boy, and the girl standing together in the living room, naturally facing each other with warm expressions"
            },
            // Second image (child image)
            {
              "inlineData": {
                "mimeType": "image/jpeg",  // Adjust to "image/png" if child image is PNG
                "data": childImageBase64,
              }
            }
          ]
        }
      ]
    });

    try {
      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");

        final data = jsonDecode(responseBody);
        String? base64Image;

        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final parts = data["candidates"][0]["content"]["parts"];
          for (var part in parts) {
            if (part["inlineData"] != null && part["inlineData"]["data"] != null) {
              base64Image = part["inlineData"]["data"];
              break;
            }
          }
        }

        return base64Image;  // Returns only the base64 string or null
      } else {
        print("Error: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }


  }


  static Future<String?> generateFamilyPhoto({
    required String baseImageBase64,  // Base64 string of the main image
    required String childImageBase64,  // Base64 string of the child image to be added
  }) async
  {

    // API configuration
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';  // Gemini API key
    // API endpoint URL for image generation
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    // HTTP headers for the API request
    var headers = {
      'x-goog-api-key': apiKey,  // Authentication header
      'Content-Type': 'application/json',  // Content type specification
    };

    // Request body containing the images and generation instructions
    var body = json.encode({
      "contents": [
        {
          "parts": [
            // First image (base image)
            {
              "inlineData": {
                "mimeType": "image/png",  // MIME type for the base image
                "data": baseImageBase64,  // Base64 encoded image data
              }
            },
            // Text prompt for image generation
            {
              "text":
            //  "Create a realistic, professional-style family photo. Use the little girl from the first image with all her details and appearance. And From the second image, use all the background details, objects, furniture, and decorations, but exclude the girl with red dress. Generate a full-body, realistic shot of the grandma, the boy, and the girl standing together in the living room, naturally facing each other with warm expressions, as if captured in a candid family moment."
         "Replace the face of the girl or the boy in the first photo with the face of the girl or the boy in the second photo, and make the face of the boy or the girl in the first photo look like the face of the boy or the girl in the second photo and leave the face of the grandma as it was."
            },
            // Second image (child image)
            {
              "inlineData": {
                "mimeType": "image/jpeg",  // Adjust to "image/png" if child image is PNG
                "data": childImageBase64,
              }
            }
          ]
        }
      ]
    });

    try {
      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");

        final data = jsonDecode(responseBody);
        String? base64Image;

        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final parts = data["candidates"][0]["content"]["parts"];
          for (var part in parts) {
            if (part["inlineData"] != null && part["inlineData"]["data"] != null) {
              base64Image = part["inlineData"]["data"];
              break;
            }
          }
        }

        return base64Image;  // Returns only the base64 string or null
      } else {
        print("Error: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  static Future<String?> generateBoyPhoto({
    required String baseImageBase64,  // Base64 string of the main image
    required String childImageBase64,  // Base64 string of the child image to be added
    required String dataAi,  // Base64 string of the child image to be added
  }) async
  {

    // API configuration
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';  // Gemini API key
    // API endpoint URL for image generation
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    // HTTP headers for the API request
    var headers = {
      'x-goog-api-key': apiKey,  // Authentication header
      'Content-Type': 'application/json',  // Content type specification
    };

    // Request body containing the images and generation instructions
    var body = json.encode({
      "contents": [
        {
          "parts": [
            // First image (base image)
            {
              "inlineData": {
                "mimeType": "image/png",  // MIME type for the base image
                "data": baseImageBase64,  // Base64 encoded image data
              }
            },
            // Text prompt for image generation
            {
              "text":dataAi
             // "Swap the face of the boy from the first image with the face of the boy in the second image. Do not merge or adapt the facial expression from the original image. Keep the eyes, mouth, and expression exactly as they appear in the second image. Only replace the face while keeping the body, hair,color, dress, and scene unchanged. Keep the style consistent with the illustration. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image"

              //  "wap the face of the boy in the first image with the face of the second image. Use the facial features and expression from the second image, but preserve the skin tone, colors, and lighting of the original boy in the first image. Keep the body, clothes, and background unchanged. Do not blend or merge the original expression—only replace the face features. Keep the style consistent with the photo. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image."
             // "Swap the face of the boy in the white saudi thobe from the first image with the face of the boy in the second image. Do not merge or adapt the facial expression from the original image. Keep the eyes, mouth, and expression exactly as they appear in the second image. Only replace the face while keeping the body, hair, dress, and scene unchanged. Keep the style consistent with the illustration. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image."

              //  "Create a realistic, professional-style family photo. Use the little girl from the first image with all her details and appearance. And From the second image, use all the background details, objects, furniture, and decorations, but exclude the girl with red dress. Generate a full-body, realistic shot of the grandma, the boy, and the girl standing together in the living room, naturally hugging each other with warm expressions, as if captured in a candid family moment."
            },
            // Second image (child image)
            {
              "inlineData": {
                "mimeType": "image/jpeg",  // Adjust to "image/png" if child image is PNG
                "data": childImageBase64,
              }
            }
          ]
        }
      ]
    });

    try {
      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");

        final data = jsonDecode(responseBody);
        String? base64Image;

        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final parts = data["candidates"][0]["content"]["parts"];
          for (var part in parts) {
            if (part["inlineData"] != null && part["inlineData"]["data"] != null) {
              base64Image = part["inlineData"]["data"];
              break;
            }
          }
        }

        return base64Image;  // Returns only the base64 string or null
      } else {
        print("Error: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
  static Future<String?> generateGirlPhoto({
    required String baseImageBase64,  // Base64 string of the main image
    required String childImageBase64,  // Base64 string of the child image to be added
    required String dataAi,  // Base64 string of the child image to be added
  }) async
  {

    // API configuration
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';  // Gemini API key
    // API endpoint URL for image generation
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    // HTTP headers for the API request
    var headers = {
      'x-goog-api-key': apiKey,  // Authentication header
      'Content-Type': 'application/json',  // Content type specification
    };

    // Request body containing the images and generation instructions
    var body = json.encode({
      "contents": [
        {
          "parts": [
            // First image (base image)
            {
              "inlineData": {
                "mimeType": "image/png",  // MIME type for the base image
                "data": baseImageBase64,  // Base64 encoded image data
              }
            },
            // Text prompt for image generation
            {
              "text":dataAi
                 // "Swap the face of the girl in the first image with the face of the second image. Use the facial features and expression from the second image, but preserve the skin tone, colors, and lighting of the original girl in the first image. Keep the body, dress, and background unchanged. Do not blend or merge the original expression—only replace the face features. Keep the style consistent with the photo. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image"
                 // "Swap the face of the girl from the first image with the face of the girl in the second image. Do not merge or adapt the facial expression from the original image. Keep the eyes, mouth, and expression exactly as they appear in the second image. Only replace the face while keeping the body, hair, color, dress, and scene unchanged. Keep the style consistent with the illustration. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image"
                  //"Swap the face of the girl in the white from the first image with the face of the girl in the second image. Do not merge or adapt the facial expression from the original image. Keep the eyes, mouth, and expression exactly as they appear in the second image. Only replace the face while keeping the body, hair, dress, and scene unchanged. Keep the style consistent with the illustration. Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image."
              // "Swap the face of the girl in the white dress from the first image with the face of the girl in the second image as it is. Keep the style consistent with the illustration . Do not add extra descriptions, summaries, or follow-up text after generating the image—just output the new image"
               // "Create a realistic, professional-style family photo. Use the little girl from the first image with all her details and appearance. And From the second image, use all the background details, objects, furniture, and decorations, but exclude the girl face with white dress. Generate a face, he boy, and the girl standing together in the living room, naturally facing each other with warm expressions, as if captured in a candid family moment."
            //  "Replace the face of the girl in the first photo with the face of the girl in the second photo, and make the face of the girl in the first photo look like the face of the girl in the second photo and leave the face of the grandma as it was."
            },
            // Second image (child image)
            {
              "inlineData": {
                "mimeType": "image/jpeg",  // Adjust to "image/png" if child image is PNG
                "data": childImageBase64,
              }
            }
          ]
        }
      ]
    });

    try {
      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");

        final data = jsonDecode(responseBody);
        String? base64Image;

        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final parts = data["candidates"][0]["content"]["parts"];
          for (var part in parts) {
            if (part["inlineData"] != null && part["inlineData"]["data"] != null) {
              base64Image = part["inlineData"]["data"];
              break;
            }
          }
        }

        return base64Image;  // Returns only the base64 string or null
      } else {
        print("Error: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }
  static Future<String?> convertPhotoToCartoon({
    required String imageBase64, // الصورة المركبة
  }) async {
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    var headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    var body = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text":
              "Create a realistic, professional-style family photo. Use the little girl from the first image with all her details and appearance. And From the second image, use all the background details, objects, furniture, and decorations, but exclude the girl with red dress. Generate a full-body, realistic shot of the grandma, the boy, and the girl standing together in the living room, naturally facing each other with warm expressions, as if captured in a candid family moment."
            },
            {
              "inline_data": {
                "mime_type": "image/png",
                "data": imageBase64,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 1
      }
    });

    try {
      var request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = body;

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print("Response: $responseBody");
        return responseBody;
      } else {
        print("Error: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Exception: $e");
      return null;
    }
  }

  static Future<String?> generateCustomizedStory(
      String storyText,
      Map<String, String> answers,
      ) async
  {
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY'; // يفضل تخزينه بأمان
    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    );

    String customizationText =
    answers.entries.map((e) => '${e.key}: ${e.value}').join(', ');

    final headers = {
      'x-goog-api-key': apiKey,
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text": '''
The general story is: $storyText  

Based on the customize questions and user answers: $customizationText  

Extract the user preferences then customize the general story to fit children's preferences.  
Always use the user's language (Arabic if input is Arabic).  

⚠️ Return ONLY a valid JSON object in this format:
{
  "customized_story": "..."
}
'''
            }
          ]
        }
      ]
    });

    try {
      final request = http.Request('POST', endpoint);
      request.body = body;
      request.headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        String rawText =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

        // تنظيف أي ```json أو ``` من النص
        rawText = rawText.trim();
        if (rawText.startsWith("```")) {
          rawText = rawText.replaceAll(RegExp(r"^```(json)?"), "");
          rawText = rawText.replaceAll("```", "");
          rawText = rawText.trim();
        }

        final Map<String, dynamic> result = jsonDecode(rawText);

        return result["customized_story"] ?? storyText;
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {

      return null;
    }
  }
  /// Generate a customized story text from answers



   static const _urlo =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

  static const String _url =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-preview:generateContent';

  /// Generates a cartoon-style image from a base64 image and story text
  static Future<Uint8List?> generateCartoonImage(
      String base64Image, String storyText) async
  {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'x-goog-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "prompt": [
            {
              "text":
              "Convert this image to cartoon style and incorporate the following story details: $storyText"
            }
          ],
          "image_input": [
            {
              "image": {
                "mime_type": "image/png",
                "data": base64Image,
              }
            }
          ],
          "candidate_count": 1
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Full response: $data');

        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final firstCandidate = candidates[0];
          final imageBase64 =
          firstCandidate['content']?[0]?['image']?['imageBytes'];

          if (imageBase64 != null) {
            return base64Decode(imageBase64);
          }
        }
        throw Exception('No image data in response');
      } else {
        throw Exception(
            'API request failed with status: ${response.statusCode} | ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }




  /// دمج وجه الطفل مع صورة كرتونية
  static Future<Uint8List?> mergeChildWithCartoon(
      String childBase64, String cartoonBase64) async
  {
    final url =
    Uri.parse("$_baseUrl/gemini-2.5-flash-image-preview:generateContent");

    try
    {
      final response = await http.post(
        url,
        headers: {
          'x-goog-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                  "دمج وجه الطفل من الصورة الأولى داخل الشخصية الكرتونية من الصورة الثانية مع الحفاظ على الطابع الكرتوني."
                },
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': childBase64,
                  }
                },
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': cartoonBase64,
                  }
                }
              ]
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Result = data['candidates']?[0]['content']['parts']?[0]
        ['inlineData']?['data'];
        if (base64Result != null) {
          return base64Decode(base64Result);
        }
      } else {
        throw Exception("Failed to merge images: ${response.statusCode}");
      }
    } catch (e) {
      print("Error merging child with cartoon: $e");
    }
    return null;
  }//خالد أحمد نور سلمى ورده عافيه
//
}
