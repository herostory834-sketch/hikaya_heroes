import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/services/face_swap_hugging_face.dart'; // Updated import for Hugging Face
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';  // Added for File I/O in _saveImageLocally
import 'package:path_provider/path_provider.dart';

class StoryCustomizationPage extends StatefulWidget {
  final String storyId;
  final bool gender;
  final Function(StoryCustomization) onCustomizationComplete;

  const StoryCustomizationPage({
    super.key,
    required this.storyId,
    required this.onCustomizationComplete,
    required this.gender,
  });

  @override
  State<StoryCustomizationPage> createState() => _StoryCustomizationPageState();
}

class _StoryCustomizationPageState extends State<StoryCustomizationPage> with SingleTickerProviderStateMixin {
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
      ByteData bytes = await rootBundle.load(gender ? 'assets/images/happy.png' : 'assets/images/happy.png');
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
        print(story.content);
        print(story.customizationQuestions);
        setState(() {
          _story = story;
          _customizationQuestions = story.customizationQuestions;
          _controllers = List.generate(
            _customizationQuestions.length - 1, // Exclude color question
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

  // Updated method to use Hugging Face for story customization (using a text-generation model)

  // Helper method to convert Base64 to temporary File
  Future<File?> _base64ToTempFile(String base64String, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      final bytes = base64Decode(base64String);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error creating temp file: $e');
      return null;
    }
  }

  Future<String?> _saveImageLocally(XFile? selectedImage, String photoName) async {
    if (selectedImage == null) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/$photoName';
      final bytes = await selectedImage.readAsBytes();
      await File(imagePath).writeAsBytes(bytes);
      return imagePath;
    } catch (e) {
      print('Error saving image: $e');
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
      setState(() => _isGeneratingStory = false);
      return;
    }

    // Collect all answers
    Map<String, String> answers = {};
    for (int i = 0; i < _customizationQuestions.length; i++) {
      if (i < _controllers.length) {
        answers[_customizationQuestions[i]] =
        _controllers[i].text.isNotEmpty ? _controllers[i].text : 'غير محدد';
      } else if (i == _customizationQuestions.length - 1) {
        answers[_customizationQuestions[i]] = _selectedColor ?? 'أزرق';
      }
    }

    // Add gender
    answers['الجنس'] = widget.gender ? 'ولد' : 'فتاة';

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري معالجة القصة والصورة...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 10),
      ),
    );

    String storyText = _story?.content ?? 'قصة افتراضية.';
    String res = storyText; // Replace with story generation if needed

    // Specific replacements for the story based on user answers
    // Assuming questions order: 0 - hero name (replace سُدرة), 1 - friend name (replace سارة, with Yamon if empty?), 2 - grandma name (replace نورة)
    String customizedStory = storyText;
    if (_customizationQuestions.length > 0) {
      String heroName = answers[_customizationQuestions[0]] ?? 'سُدرة';
      customizedStory = customizedStory.replaceAll('سُدرة', heroName);
    }
    if (_customizationQuestions.length > 1) {
      String friendName = answers[_customizationQuestions[1]] ?? 'يمون'; // Default to Yamon as per request if empty
      customizedStory = customizedStory.replaceAll('سارة', friendName);
    }
    if (_customizationQuestions.length > 2) {
      String grandmaName = answers[_customizationQuestions[2]] ?? 'نورة';
      customizedStory = customizedStory.replaceAll('نورة', grandmaName);
    }
    // Replace color (assuming last question is color, replace أبيض)
    if (_selectedColor != null) {
      customizedStory = customizedStory.replaceAll('أبيض', _selectedColor!);
    }

    res = customizedStory;

    Uint8List? processedImageBytes;
    String? localPhotoPath;

    try {
      if (_childImageBase64 != null && _baseImageBase64 != null) {
        // Convert Base64 to temp files
        final baseFile = await _base64ToTempFile(
            _baseImageBase64!, 'base_${widget.gender ? 'happy' : 'happy'}.png');
        final childFile =
        await _base64ToTempFile(_childImageBase64!, 'child.png');

        if (baseFile != null && childFile != null) {
          // Call your Render backend
          processedImageBytes =
          await FaceSwapBackend.swapFaces(baseFile, childFile);

          // Clean up temp files
          await baseFile.delete();
          await childFile.delete();
        }
      }

      // Update story content
      if (widget.gender) {
        _story!.content_for_boy = res;
      } else {
        _story!.content = res;
      }

      // Save swapped image locally
      if (processedImageBytes != null) {
        final photoName = '${_story!.title}_${answers.values.first}.jpg';
        final xfile = XFile.fromData(processedImageBytes, name: photoName);
        localPhotoPath = await _saveImageLocally(xfile, photoName);
        if (localPhotoPath != null) {
          _story!.photo = localPhotoPath;
        }
      }
    } catch (e) {
      print('Error generating/saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Set createdAt and save to Firebase
    _story!.createdAt = DateTime.now();
    print(_story!.toMap().toString());

    String? id = await _firebaseService.addCustomizeStory(_story!);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في حفظ القصة'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isGeneratingStory = false);
      return;
    }

    StoryCustomization storyCustomization = StoryCustomization(
      storyId: id,
      childImage: processedImageBytes != null
          ? base64Encode(processedImageBytes)
          : null,
      storyText: res,
    );

    await _animationController.reverse();
    setState(() => _isGeneratingStory = false);
    widget.onCustomizationComplete(storyCustomization);
  }

  // Helper to convert URL to Base64 (if Hugging Face returns a URL)
  Future<String?> _urlToBase64(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      }
    } catch (e) {
      print('Error fetching image from URL: $e');
    }
    return null;
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Constants.kPrimaryColor),
                title: const Text('المعرض', style: TextStyle(fontFamily: 'Tajawal')),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.gallery);
                },
              ),
              Divider(height: 1, color: Colors.grey[300]),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Constants.kPrimaryColor),
                title: const Text('الكاميرا', style: TextStyle(fontFamily: 'Tajawal')),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
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
            value: _customizationQuestions.isEmpty
                ? 0
                : (_currentPage + 1) / _customizationQuestions.length,
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
                  ? const Icon(
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
        maxLines: 1,  // Added to prevent overflow for short inputs
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
            onPressed: _showImageSourceBottomSheet,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _showImageSourceBottomSheet,
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
              child: _isGeneratingStory
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : Text(
                _currentPage == _customizationQuestions.length - 1
                    ? 'إنهاء التخصيص 🎉'
                    : 'التالي',
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
    final question = _customizationQuestions[index].toLowerCase();
    if (index == _customizationQuestions.length - 1 || question.contains('لون')) {
      return Icons.color_lens;
    }
    if (question.contains('اسم') || question.contains('name')) {
      return Icons.person;
    }
    return Icons.help_outline;  // Default
  }

  String _getQuestionDescription(int index) {
    final question = _customizationQuestions[index].toLowerCase();
    if (index == _customizationQuestions.length - 1 || question.contains('لون')) {
      return 'اختر اللون المفضل الذي سيظهر في القصة';
    }
    if (question.contains('اسم') || question.contains('name')) {
      return 'أدخل اسم الشخصية';
    }
    return 'أجب على السؤال لتخصيص القصة';  // Dynamic default
  }

  String _getHintText(int index) {
    final question = _customizationQuestions[index].toLowerCase();
    if (question.contains('اسم') || question.contains('name')) {
      return 'اكتب اسم الشخصية...';
    }
    return 'اكتب هنا...';
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
      return const Scaffold(
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