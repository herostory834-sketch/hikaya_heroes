import 'package:flutter/material.dart';
import 'package:hikaya_heroes/models/story.dart';
import 'package:hikaya_heroes/utils/constants.dart';
import 'package:hikaya_heroes/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../services/gemini_service.dart';

class StoryCustomizationPage extends StatefulWidget {
  final String storyId;
  final Function(StoryCustomization) onCustomizationComplete;

  const StoryCustomizationPage({
    super.key,
    required this.storyId,
    required this.onCustomizationComplete,
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
  String? _baseCartonImageBase64;
  String? _selectedColor;
  bool _isLoading = true;
  Story? _story;
  List<String> _customizationQuestions = [];
  bool _loading = false;
  String? _customizedStory;
  Uint8List? _cartoonImage;
  Uint8List? _finalMergedImage;

  // New variable for image mode selection
  String _selectedImageMode = 'real'; // 'real' or 'cartoon'

  // Enhanced color options with better visual representation
  static const List<Map<String, dynamic>> _colors = [
    {'name': 'أحمر', 'color': Colors.red, 'emoji': '🔴'},
    {'name': 'أزرق', 'color': Colors.blue, 'emoji': '🔵'},
    {'name': 'أخضر', 'color': Colors.green, 'emoji': '🟢'},
    {'name': 'أصفر', 'color': Colors.yellow, 'emoji': '🟡'},
    {'name': 'أرجواني', 'color': Colors.purple, 'emoji': '🟣'},
    {'name': 'برتقالي', 'color': Colors.orange, 'emoji': '🟠'},
    {'name': 'وردي', 'color': Colors.pink, 'emoji': '🌸'},
    {'name': 'بني', 'color': Colors.brown, 'emoji': '🟤'},
  ];

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _imagePicker = ImagePicker();

  // Loading states for better UX
  bool _isGeneratingStory = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _loadStory();
    _loadBaseImage();
    _loadBaseCartonImage();
  }

  Future<void> _loadBaseCartonImage() async {
    try {
      ByteData bytes = await rootBundle.load('assets/images/grandmother.png');
      Uint8List buffer = bytes.buffer.asUint8List();
      _baseCartonImageBase64 = base64Encode(buffer);
    } catch (e) {
      print('Error loading base cartoon image: $e');
    }
  }

  Future<void> _loadBaseImage() async {
    try {
      ByteData bytes = await rootBundle.load('assets/images/real_photo.png');
      Uint8List buffer = bytes.buffer.asUint8List();
      _baseImageBase64 = base64Encode(buffer);
    } catch (e) {
      print('Error loading base image: $e');
    }
  }

  Future<void> _generateStoryAndImages(Map<String, String> answers) async {
    if (_baseImageBase64 == null) {
      _showErrorSnackBar('خطأ في تحميل الصورة الأساسية');
      return;
    }

    setState(() => _isGeneratingStory = true);

    // Show comprehensive loading dialog
    _showProcessingDialog();

    try {
      // 1️⃣ Generate customized story
      final storyText = _customizedStory ?? _story?.content ?? "قصة افتراضية.";
      final newStory = await GeminiService.generateCustomizedStory(storyText, answers);

      // 2️⃣ Generate image based on selected mode
      String? generatedImageBase64;
      if (_childImageBase64 != null) {
        setState(() => _isUploadingImage = true);

        if (_selectedImageMode == 'cartoon') {
          print('_baseCartonImageBase64');
          print(_baseCartonImageBase64);
          // Use cartoon mode
          generatedImageBase64 = await GeminiService.generateFamilyPhotoFromCarton(
            baseImageBase64: _baseCartonImageBase64!,
            childImageBase64: _childImageBase64!,
          );
        } else {
          // Use real mode (default)
          generatedImageBase64 = await GeminiService.generateFamilyPhoto(
            baseImageBase64: _baseImageBase64!,
            childImageBase64: _childImageBase64!,
          );
        }

        setState(() => _isUploadingImage = false);
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      _showSuccessSnackBar('تم إنشاء القصة بنجاح!');

      // 3️⃣ Send result to parent
      final customization = StoryCustomization(
        storyId: widget.storyId,
        storyText: newStory ?? _story?.content ?? "قصة افتراضية.",
        childImage: generatedImageBase64,
        imageMode: _selectedImageMode,
      );

      widget.onCustomizationComplete(customization);

    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('خطأ في إنشاء القصة: $e');
      print('Error generating story: $e');
    } finally {
      setState(() => _isGeneratingStory = false);
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: _isGeneratingStory ? 1 : 0,
              duration: const Duration(seconds: 2),
              child: Image.asset('assets/images/ai_icon.png', width: 60, height: 60),
            ),
            const SizedBox(height: 20),
            Text(
              _isUploadingImage ? 'جاري معالجة الصورة...' : 'الذكاء الاصطناعي يصنع قصتك...',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_isUploadingImage) ...[
              const SizedBox(height: 10),
              Text(
                'النمط: ${_selectedImageMode == 'cartoon' ? 'كرتوني' : 'واقعي'}',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Constants.kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 15),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Constants.kPrimaryColor),
            ),
            const SizedBox(height: 10),
            Text(
              'هذا قد يستغرق بضع ثوانٍ...',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
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
          _customizedStory = story.content;
          // Create controllers for all questions except the last one (color)
          _controllers = List.generate(
            _customizationQuestions.length - 1,
                (index) => TextEditingController(),
          );
          _isLoading = false;
        });
      } else {
        throw Exception('Story not found');
      }
    } catch (e) {
      print('Error loading story: $e');
      _showErrorSnackBar('خطأ في تحميل القصة: $e');
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

  void _generateStory() async {
    if (_customizationQuestions.isEmpty) {
      _showWarningSnackBar('لا توجد أسئلة تخصيص متاحة');
      return;
    }

    // Validate required fields
    if (_currentPage == _customizationQuestions.length - 1 && _selectedColor == null) {
      _showWarningSnackBar('يرجى اختيار اللون');
      return;
    }

    // Collect all answers
    Map<String, String> answers = {};
    for (int i = 0; i < _customizationQuestions.length; i++) {
      if (i < _controllers.length) {
        answers[_customizationQuestions[i]] = _controllers[i].text.isNotEmpty ? _controllers[i].text : 'غير محدد';
      } else if (i == _customizationQuestions.length - 1) {
        answers[_customizationQuestions[i]] = _selectedColor ?? 'أزرق';
      }
    }

    _generateStoryAndImages(answers);
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

  // Add image mode selection widget
  Widget _buildImageModeSelection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'اختر نمط الصورة:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeOption('real', 'واقعي', Icons.photo),
            const SizedBox(width: 20),
            _buildModeOption('cartoon', 'كرتوني', Icons.animation),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _selectedImageMode == 'cartoon'
              ? 'سيتم تحويل الصورة إلى نمط كرتوني جميل'
              : 'سيتم الحفاظ على النمط الواقعي للصورة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModeOption(String mode, String label, IconData icon) {
    final isSelected = _selectedImageMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageMode = mode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Constants.kPrimaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Constants.kPrimaryColor : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Constants.kPrimaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Constants.kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Constants.kPrimaryColor,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidPNG(Uint8List bytes) {
    // PNG signature check
    if (bytes.length < 8) return false;
    return bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  // Enhanced snackbar methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
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
              if (index == 0) ...[
                _buildImageSelection(),
                _buildImageModeSelection(), // Add mode selection on first page
              ],
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color['color'],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: color['color'].withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(Icons.check, color: Colors.white, size: 20),
                  Text(
                    color['emoji'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    color['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return TextField(
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
              onPressed: _isGeneratingStory ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isGeneratingStory ? Colors.grey : Constants.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isGeneratingStory
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Text(
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
    if (index == _customizationQuestions.length - 1) return Icons.color_lens;
    if (index == 0) return Icons.add_photo_alternate;
    return Icons.person;
  }

  String _getQuestionDescription(int index) {
    if (index == _customizationQuestions.length - 1) return 'اختر اللون المفضل الذي سيظهر في القصة';
    if (index == 0) return 'يمكنك إضافة صورة شخصية واختيار نمطها لدمجها في القصة';
    return 'أدخل اسم الشخصية أو التفاصيل المطلوبة';
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Constants.kPrimaryColor)),
              const SizedBox(height: 20),
              const Text('جاري تحميل القصة...', style: TextStyle(fontFamily: 'Tajawal')),
            ],
          ),
        ),
      );
    }

    if (_story == null || _customizationQuestions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'خطأ: لا توجد أسئلة تخصيص متاحة',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة', style: TextStyle(fontFamily: 'Tajawal')),
              ),
            ],
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
                            onPressed: _isGeneratingStory ? null : () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back, color: _isGeneratingStory ? Colors.grey : Colors.white),
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
                        'قم بتخصيص القصة وجعلها أكثر متعة وتشويقاً',
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
                physics: _isGeneratingStory ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
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