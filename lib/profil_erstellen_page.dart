import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'data_input_formatter.dart';
import 'profil_erstellen2_page.dart';
import 'firestore_service.dart';

class ProfilErstellenPage extends StatefulWidget {
  @override
  _ProfilErstellenPageState createState() => _ProfilErstellenPageState();
}

class _ProfilErstellenPageState extends State<ProfilErstellenPage> {
  final FirestoreService _firestoreService = FirestoreService();

  PageController _pageController = PageController();
  int _currentPage = 0;
  int selectedGenderIndex = -1;

  TextEditingController _nameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  bool _isNameValid = true;
  bool _isGenderValid = true;
  bool _isDateValid = true;

  File? _selectedImage;
  String _errorMessage = '';

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  bool _validatePage1() {
    if (_nameController.text.isEmpty) {
      setState(() {
        _isNameValid = false;
      });
      return false;
    }
    setState(() {
      _isNameValid = true;
    });
    return true;
  }

  bool _validatePage2() {
    if (selectedGenderIndex == -1) {
      setState(() {
        _isGenderValid = false;
      });
      return false;
    }
    setState(() {
      _isGenderValid = true;
    });
    return true;
  }

  bool _validatePage3() {
    String input = _dateController.text;
    RegExp regExp =
        RegExp(r"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$");
    if (!regExp.hasMatch(input)) {
      setState(() {
        _isDateValid = false;
      });
      return false;
    }
    setState(() {
      _isDateValid = true;
    });
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // Upload image to Firebase Storage
      await _uploadImageToFirebase(_selectedImage!);
    }
  }

  Future<void> _uploadImageToFirebase(File image) async {
  try {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    String fileName = 'user_images/$userId/profile_image.jpg';

    // Upload image to Firebase Storage
    Reference ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(image);

    // Get the download URL
    String downloadURL = await ref.getDownloadURL();

    // Store the image URL in Firestore
    await _firestoreService.updateUserProfile({
      'profileImageUrl': downloadURL,
    });

    print('Image uploaded and URL stored in Firestore.');
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to upload image: $e';
    });
    print('Failed to upload image: $e');
  }
}


  void _nextPage() async {
    FocusScope.of(context).unfocus(); // This will dismiss the keyboard

    bool isValid = false;
    if (_currentPage == 0) {
      isValid = _validatePage1();
      if (isValid) {
        await _firestoreService.updateUserProfile({
          'name': _nameController.text,
        });
      }
    } else if (_currentPage == 1) {
      isValid = _validatePage2();
      if (isValid) {
        await _firestoreService.updateUserProfile({
          'gender': selectedGenderIndex,
        });
      }
    } else if (_currentPage == 2) {
      isValid = _validatePage3();
      if (isValid) {
        await _firestoreService.updateUserProfile({
          'birthdate': _dateController.text,
        });
      }
    } else {
      isValid = true;
    }

    if (isValid) {
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        await _firestoreService
            .markProfileStepCompleted('profileStep1Completed');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilErstellen2Page(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(
              top: 16.0, left: 24.0), // Adjust padding as needed
          child: GestureDetector(
            onTap: () {
              if (_currentPage == 0) {
                Navigator.pop(context);
              } else {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              width: 60, // Adjusted button size
              height: 60, // Adjusted button size
              child: SvgPicture.asset(
                'assets/graphics/prof_erstellen_back_button.svg',
                fit: BoxFit.contain, // Ensure the SVG fits within the container
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(
              top: 16.0), // Adjust the top padding as needed
          child: Text(
            'Profil erstellen',
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
              _buildPage4(),
            ],
          ),
          if (!isKeyboardVisible || _currentPage != 0) ...[
            Positioned(
              bottom: 80,
              right: 32,
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/graphics/prof_erstellen_weiter_button.svg',
                      width: 45,
                      height: 45,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicators(),
              ),
            ),
            // Skip Button
            Positioned(
              bottom: 100,
              left: 32,
              child: GestureDetector(
                onTap: () async {
                  await _firestoreService
                      .markProfileStepCompleted('profileStep1Completed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilErstellen2Page(),
                    ),
                  );
                },
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Color(0xFF414254),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Inter',
                    height: 1.41,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'So möchtest du von deinem Partner / deiner Partnerin genannt werden:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Name eingeben',
              hintStyle: TextStyle(color: Color(0xFF979797)),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
          if (!_isNameValid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte alle Felder ausfüllen',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    List<Map<String, String>> genderOptions = [
      {
        'label': 'Männlich',
        'icon': 'assets/graphics/männlich_icon.svg',
      },
      {
        'label': 'Weiblich',
        'icon': 'assets/graphics/weiblich_icon.svg',
      },
      {
        'label': 'Weiteres',
        'icon': 'assets/graphics/weiteres_icon.svg',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Gender:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns in the grid
                      crossAxisSpacing: 20.0, // Spacing between columns
                      mainAxisSpacing: 20.0, // Spacing between rows
                      childAspectRatio: 1.2, // Aspect ratio of each item
                    ),
                    itemCount: genderOptions.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedGenderIndex == index;
                      print(
                          'Rendering box $index, isSelected: $isSelected'); // Debugging statement
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedGenderIndex = index;
                            print(
                                'Selected Gender Index: $selectedGenderIndex'); // Debugging statement
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFFDDF1EA)
                                : Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(0),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black26,
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SvgPicture.asset(
                                genderOptions[index]['icon']!,
                                color: isSelected
                                    ? Color(0xFF7D4666)
                                    : Color(0xFF979797),
                                width: 50,
                                height: 50,
                              ),
                              SizedBox(height: 8),
                              Text(
                                genderOptions[index]['label']!,
                                style: TextStyle(
                                  color: Color(0xFF414254),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!_isGenderValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Text(
                      'Hinweis: Bitte eine Option auswählen',
                      style: TextStyle(
                        color: Color(0xFF7D4666),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Geburtsdatum:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          TextField(
            controller: _dateController,
            inputFormatters: [DateInputFormatter()],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'DD/MM/YYYY',
              hintStyle: TextStyle(color: Color(0xFF979797)),
              prefixIcon: Icon(
                Icons.calendar_today,
                color: Color(0xFF979797),
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
          if (!_isDateValid)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte ein gültiges Datum eingeben',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<PermissionStatus> _requestPhotoPermission() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    Permission permissionToRequest;

    if (androidInfo.version.sdkInt <= 32) {
      permissionToRequest = Permission.storage;
    } else {
      permissionToRequest = Permission.photos;
    }

    if (await permissionToRequest.isDenied) {
      return await permissionToRequest.request();
    }
    return permissionToRequest.status;
  }

  Future<void> _showImageSourceSelectionDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  Navigator.pop(context);
                  PermissionStatus permissionStatus =
                      await _requestPhotoPermission();
                  if (permissionStatus.isGranted) {
                    _pickImage(ImageSource.gallery);
                  } else {
                    setState(() {
                      _errorMessage = 'Galerieerlaubnis verweigert';
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  if (await Permission.camera.request().isGranted) {
                    _pickImage(ImageSource.camera);
                  } else {
                    setState(() {
                      _errorMessage = 'Kameraerlaubnis verweigert';
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage4() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 20),
          Text(
            'Ihr Foto hinzufügen:',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 100),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceSelectionDialog,
              child: _selectedImage == null
                  ? SvgPicture.asset(
                      'assets/graphics/pic_upload_icon.svg',
                      width: 250, // Adjust width as needed
                      height: 250, // Adjust height as needed
                    )
                  : Image.file(
                      _selectedImage!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicators() {
    return List<Widget>.generate(4, (int index) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 6.0),
        width: 40.0,
        height: 40.0,
        child: SvgPicture.asset(
          index <= _currentPage
              ? 'assets/graphics/leave_icon.svg'
              : 'assets/graphics/leave_icon_blass.svg',
        ),
      );
    });
  }
}
