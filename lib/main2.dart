import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnLoginStatus();
  }

  Future<void> _navigateBasedOnLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLogin = prefs.getBool('autoLogin') ?? false;

    await Future.delayed(const Duration(seconds: 3)); // 스플래시 화면 표시 시간

    if (autoLogin) {
      developer.log('자동 로그인 성공');
      _navigateToHome(); // 자동 로그인 시 홈 화면으로 이동
    } else {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    }
  }

  void _navigateToHome() {
    // 홈 화면으로 이동하는 코드 작성
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 추가
            Image.asset('assets/logo.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const Text(
              '원룸알리미',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            const Text(
              '대학로의 모든 원룸 제공 서비스',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// 로그인/회원가입 화면
class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool isLogin = true;
  String? selectedJob;
  bool isAutoLogin = false;

  final List<String> jobOptions = ['학생', '공인중개사'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸알리미'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLogin) ...[
                const Text(
                  '안녕하세요\n휴대폰 번호로 로그인해 주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildPhoneNumberField(),
                _buildPasswordField(),
                _buildAutoLoginCheckbox(),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    developer.log('Login button clicked');
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool('autoLogin', isAutoLogin);
                    Navigator.pushReplacement(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('로그인'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = false;
                    });
                  },
                  child: const Text('회원가입'),
                ),
              ] else ...[
                const Text(
                  '안녕하세요\n휴대폰 번호로 회원가입 해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildPhoneNumberField(),
                _buildPasswordField(),
                _buildPasswordConfirmField(),
                _buildTextField('닉네임'),
                _buildDropdownField('직업 선택', jobOptions, selectedJob, (value) {
                  setState(() {
                    selectedJob = value;
                  });
                }),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    developer.log('Signup button clicked');
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('회원가입'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = true;
                    });
                  },
                  child: const Text('로그인으로 돌아가기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '휴대폰 번호(숫자만 입력)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: '비밀번호',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buildPasswordConfirmField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: '비밀번호 확인',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedItem, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: selectedItem,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAutoLoginCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: isAutoLogin,
          onChanged: (value) {
            setState(() {
              isAutoLogin = value ?? false;
            });
          },
        ),
        const Text('자동 로그인'),
      ],
    );
  }
}

// 홈 화면 디자인
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> posts = [
    {
      'title': '원룸 (월세)',
      'location': '학교앞',
      'price': '200/33',
      'author': '공인중개사',
      'detail': '관리비 5만원',
      'image': null,
      'isFavorite': false, // 좋아요 상태 추가
    },
    {
      'title': '투룸 (전세)',
      'location': '학교앞',
      'price': '200/45',
      'author': '학생',
      'detail': '관리비 5만원',
      'image': null,
      'isFavorite': false, // 좋아요 상태 추가
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '원룸알리미',
          style: TextStyle(color: Colors.orange),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildListingCard(
            post['title'] ?? '',
            post['location'] ?? '',
            post['price'] ?? '',
            post['author'] ?? '',
            post['detail'] ?? '',
            post['image'],
            post['isFavorite'], // 좋아요 상태 전달
            () {
              setState(() {
                posts[index]['isFavorite'] = !post['isFavorite']; // 좋아요 상태 토글
              });
            },
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PostDetailScreen(post: post), // 게시물 상세 화면으로 이동
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPost,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: '메시지'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }

  Widget _buildListingCard(
    String title,
    String location,
    String price,
    String author,
    String detail,
    File? image,
    bool isFavorite,
    VoidCallback onFavoritePressed,
    VoidCallback onCardPressed, // 게시물 클릭 시 호출되는 콜백
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onCardPressed, // 카드 클릭 시 실행
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (price.isNotEmpty)
                Text(price,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$title/$location/$detail',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text('작성자 : $author',
                  style: const TextStyle(color: Colors.redAccent)),
              if (image != null) ...[
                const SizedBox(height: 8),
                Image.file(image,
                    width: double.infinity, height: 150, fit: BoxFit.cover),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '후기 0개',
                    style: TextStyle(color: Colors.grey),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                    ),
                    onPressed: onFavoritePressed, // 좋아요 버튼 클릭 시
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPost() async {
    String? title = '원룸'; // 기본값 설정
    String? type = '월세'; // 기본값 설정
    String? location;
    String? price;
    String? author;
    String? detail;
    File? selectedImage;

    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시물 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown for title selection
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '타입 선택',
                    border: OutlineInputBorder(),
                  ),
                  value: title,
                  items: ['원룸', '투룸', '쓰리룸']
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                const SizedBox(height: 10),
                // Dropdown for type (월세/전세)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: '거래 유형',
                    border: OutlineInputBorder(),
                  ),
                  value: type,
                  items: ['월세', '전세']
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ))
                      .toList(),
                  onChanged: (value) {
                    type = value;
                  },
                ),
                const SizedBox(height: 10),
                _buildTextField('위치', (value) => location = value),
                _buildTextField('가격', (value) => price = value),
                _buildTextField('작성자', (value) => author = value),
                _buildTextField('상세 정보', (value) => detail = value),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        selectedImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: const Text('사진 추가'),
                ),
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(selectedImage!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  posts.add({
                    'title': '$title ($type)', // Add type to title
                    'location': location ?? '',
                    'price': price ?? '',
                    'author': author ?? '',
                    'detail': detail ?? '',
                    'image': selectedImage,
                    'isFavorite': false, // 새 게시물은 기본적으로 좋아요 미선택
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
        keyboardType: TextInputType.text,
      ),
    );
  }
}

// 게시물 상세 화면
class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post['title']),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '가격: ${post['price']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('위치: ${post['location']}'),
            Text('작성자: ${post['author']}'),
            const SizedBox(height: 8),
            Text('상세: ${post['detail']}'),
            if (post['image'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(post['image'], fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}
