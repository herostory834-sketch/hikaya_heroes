import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/services/gemini_service.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class StoryCustomizationPageOld extends StatefulWidget {
  final String storyId;
  final bool gender;
  final Function(StoryCustomization) onCustomizationComplete;

  const StoryCustomizationPageOld({
    super.key,
    required this.storyId,
    required this.onCustomizationComplete,
    required this. gender,
  });

  @override
  State<StoryCustomizationPageOld> createState() => _StoryCustomizationPageOldState();
}

class _StoryCustomizationPageOldState extends State<StoryCustomizationPageOld> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late List<TextEditingController> _controllers;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  int _currentPage = 0;
  String? _childImageBase64;
  String? _baseImageBase64;
  bool _isGeneratingStory = false;

  String? _selectedColor;
  bool _isLoading = true;
  Story? _story;
  List<String> _customizationQuestions = [];

  static const List<Map<String, dynamic>> _colors = [
    {'name': 'أحمر', 'color': Colors.red},
    {'name': 'أزرق', 'color': Colors.blue},
    {'name': 'أخضر', 'color': Colors.green},
    {'name': 'أصفر', 'color': Colors.yellow},
    {'name': 'أرجواني', 'color': Colors.purple},
    {'name': 'برتقالي', 'color': Colors.orange},
    {'name': 'وردي', 'color': Colors.pink},
    {'name': 'بني', 'color': Colors.brown},
  ];

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _loadStory();
    _loadBaseImage(widget.gender);
  }
  Future<void> _loadBaseImage(bool gender) async {
    try {
      ByteData bytes = await rootBundle.load(gender?'assets/images/boy.png':'assets/images/girl.png');
      Uint8List buffer = bytes.buffer.asUint8List();
      _baseImageBase64 = base64Encode(buffer);
    } catch (e) {
      print('Error loading base image: $e');
    }
  }
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadStory() async {
    setState(() => _isLoading = true);
    try {
      final story = await _firebaseService.getStoryById(widget.storyId);
      if (story != null) {
        setState(() {
          _story = story;
          _customizationQuestions = story.customizationQuestions;
          _controllers = List.generate(
            _customizationQuestions.length - 1, // Exclude gender and color questions
                (index) => TextEditingController(),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Story not found');
      }
    } catch (e) {
      print('Error loading story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل القصة: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
  void _nextPage() {
    if (_currentPage < _customizationQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _isGeneratingStory = true);

      _generateStory();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }


  Future<String?> _sendToGeminiApiToChangeTheStory(
      String storyText,
      Map<String, String> answers,
      ) async {
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
      print('Error processing story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء معالجة القصة: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
  Future<String?> _sendToGeminiApi(String base64Image, String storyText) async {
    const apiKey = 'AIzaSyASsM1qJIaNWF80P-8ZtKz_kWZOX-78iuY';
    const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-goog-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Convert the image to cartoon style and incorporate the following story details: '

                      'Story Text: $storyText'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 1,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Result = data['candidates']?[0]['content']['parts']?[0]['inlineData']?['data'];
        if (base64Result != null) {
          return base64Result;
        } else {
          throw Exception('No base64 image data in response');
        }
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ أثناء معالجة الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  void _generateStory() async {
    if (_customizationQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أسئلة تخصيص متاحة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Collect all answers
    Map<String, String> answers = {};
    for (int i = 0; i < _customizationQuestions.length; i++) {
      if (i < _controllers.length) {
        answers[_customizationQuestions[i]] = _controllers[i].text.isNotEmpty ? _controllers[i].text : 'غير محدد';
      } else  if (i == _customizationQuestions.length - 1) {
        answers[_customizationQuestions[i]] = _selectedColor ?? 'أزرق';
      }
    }
// Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري معالجة القصة والصورة...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 10),
      ),
    );
    String storyText = _story?.content ?? 'قصة افتراضية.';


    _sendToGeminiApiToChangeTheStory( storyText, answers).then((res)async{
      String? processedImageBase64 = _childImageBase64;
      if (_childImageBase64 != null) {
        print(widget.gender);
        if(widget.gender){
          processedImageBase64 = await GeminiService.generateBoyPhoto(baseImageBase64: _baseImageBase64!, childImageBase64: _childImageBase64!,dataAi:_story!.aiBoy );

        }else{
          processedImageBase64 = await GeminiService.generateGirlPhoto(baseImageBase64: _baseImageBase64!, childImageBase64: _childImageBase64!,dataAi:_story!.aiGirl );

        }

      }

// Create customization object

      StoryCustomization storyCustomization = StoryCustomization(
        storyId: widget.storyId,
        childImage: processedImageBase64,
        storyText: res,
      );
      await _animationController.reverse();
      widget.onCustomizationComplete(storyCustomization);
    });


// Use actual story content

// Customization data




// Notify parent with animation

  }

  void _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _childImageBase64 = base64Encode(bytes);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إضافة الصورة بنجاح!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدم التخصيص',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                '${_currentPage + 1}/${_customizationQuestions.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: Constants.kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _customizationQuestions.isEmpty ? 0 : (_currentPage + 1) / _customizationQuestions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Constants.kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getQuestionIcon(index),
                    size: 40,
                    color: Constants.kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _customizationQuestions[index],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _getQuestionDescription(index),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildInputField(index),
              if (index == 0) _buildImageSelection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(int index) {
    if (index == _customizationQuestions.length - 1) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _colors.map((color) {
          final isSelected = _selectedColor == color['name'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color['name'];
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color['color'],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                Icons.check,
                color: Colors.white,
                size: 30,
              )
                  : null,
            ),
          );
        }).toList(),
      );
    }

    return Card(
      child: TextField(
        controller: _controllers[index],
        decoration: InputDecoration(
          hintText: _getHintText(index),
          hintStyle: const TextStyle(fontFamily: 'Tajawal'),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: _controllers[index].text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () => _controllers[index].clear(),
          )
              : null,
        ),
        style: const TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildImageSelection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _childImageBase64 != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              base64Decode(_childImageBase64!),
              fit: BoxFit.cover,
            ),
          )
              : IconButton(
            icon: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
            onPressed: _selectImage,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _selectImage,
          child: Text(
            _childImageBase64 != null ? 'تم إضافة الصورة' : 'إضافة صورة (PNG)',
            style: TextStyle(
              color: _childImageBase64 != null ? Colors.green : Constants.kPrimaryColor,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Constants.kPrimaryColor),
                ),
                child: const Text(
                  'السابق',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Tajawal',
                    color: Constants.kPrimaryColor,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 10),
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: () {

                if (_currentPage == _customizationQuestions.length - 1 && _selectedColor == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى اختيار اللون'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                _nextPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child:_isGeneratingStory?CircularProgressIndicator(
                color: Colors.white,
              ): Text(
                _currentPage == _customizationQuestions.length - 1 ? 'إنهاء التخصيص 🎉' : 'التالي',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuestionIcon(int index) {
// Adjust based on dynamic questions; these are placeholders
    if (index == _customizationQuestions.length - 2) return Icons.transgender;
    if (index == _customizationQuestions.length - 1) return Icons.color_lens;
    return Icons.person;
  }

  String _getQuestionDescription(int index) {
// Adjust descriptions based on dynamic questions
    if (index == _customizationQuestions.length - 1) return 'اختر اللون المفضل الذي سيظهر في القصة';
    return 'أدخل اسم الشخصية';
  }

  String _getHintText(int index) {
    if (index < _controllers.length) {
      return 'اكتب هنا...';
    }
    return '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_story == null || _customizationQuestions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'خطأ: لا توجد أسئلة تخصيص متاحة',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Constants.kPrimaryColor.withOpacity(0.9),
                    Constants.kPrimaryColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Constants.kPrimaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'لنصنع قصتك الخاصة!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'قم بتخصيص القصة لجعلها أكثر متعة وتشويقاً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customizationQuestions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(index);
                },
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }
}