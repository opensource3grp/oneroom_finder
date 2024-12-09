import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택
//import 'dart:io'; // 이미지 파일 관련
import 'package:oneroom_finder/post/post_service.dart'; // PostService import
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore import
import 'package:oneroom_finder/post/room_details_screen.dart';

class PostCreateScreen extends StatefulWidget {
  final PostService postService;

  const PostCreateScreen({super.key, required this.postService});

  @override
  _PostCreateScreenState createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _floorController = TextEditingController(); // 층수
  final TextEditingController _maintenanceFeeController =
      TextEditingController(); // 관리비
  String selectedTag = '매매';
  String? title; // 타입 선택
  String? type; // 거래 유형
  String? roomLocation;
  bool parkingAvailable = false; // "주차 가능" -> true, "주차 불가능" -> false
  bool moveInDate = false; // "즉시 입주 가능" -> true, "즉시 입주 불가능" -> false
  final List<String> tags = ['양도', '매매'];
  final Map<String, IconData> optionIcons = {
    '냉장고': Icons.kitchen,
    '에어컨': Icons.ac_unit,
    '세탁기': Icons.local_laundry_service,
    'Wi-Fi': Icons.wifi,
    'TV': Icons.tv,
    '책상': Icons.desk,
    '가스레인지': Icons.fireplace,
    '침대': Icons.bed,
  }; //기본 옵션 정보
  final Set<String> selectedOptions = {}; // 선택된 옵션들
  File? selectedImage;

  final ImagePicker _picker = ImagePicker();
  String? nickname; // 로그인한 사용자의 닉네임
  String? job; // 로그인한 사용자의 직업

  Color? buttonColor;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 로그인한 사용자의 정보를 Firestore에서 가져오는 함수
  Future<void> _loadUserInfo() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          setState(() {
            nickname = userDoc['nickname'] ?? '알 수 없음';
            job = userDoc['job'] ?? '직업 없음';
            // 직업에 따른 색상 설정
            if (job == '학생') {
              buttonColor = Colors.orange; // 주황색
              backgroundColor = Colors.orange[200]!; // 배경 주황색
            } else if (job == '공인중개사') {
              buttonColor = Colors.blue; // 파란색
              backgroundColor = Colors.blue[200]!; // 배경 파란색
            } else {
              buttonColor = Colors.grey; // 기본 색상
              backgroundColor = Colors.grey[200]!; // 기본 배경색
            }
          });
        } else {
          // 문서가 존재하지 않을 경우
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자가 로그인하지 않았습니다.')),
        );
      }
    } catch (e) {
      // 예외 발생 시 오류 메시지 출력
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 정보를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매물 올리기'),
        backgroundColor: backgroundColor, // 직업에 맞는 배경 색상
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '태그 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedTag,
                items: tags.map((tag) {
                  return DropdownMenuItem(
                    value: tag,
                    child: Text(tag),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTag = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 타입 선택 (원룸, 투룸, 쓰리룸)
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
                  setState(() {
                    title = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // 거래 유형 (월세, 전세)
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
                  setState(() {
                    type = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // 위치 선택
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '위치 선택',
                  border: OutlineInputBorder(),
                ),
                value: roomLocation,
                items: ['옥계', '신평', '학교 앞']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    roomLocation = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              // 주차 여부 (주차 가능 / 불가능)
              _buildDropdown('주차 여부', parkingAvailable ? '주차 가능' : '주차 불가능',
                  ['주차 가능', '주차 불가능'], (value) {
                setState(() {
                  parkingAvailable = value == '주차 가능'; // true/false 변환
                });
              }),
              const SizedBox(height: 10),

              // 즉시 입주 가능 여부
              _buildDropdown('즉시 입주', moveInDate ? '즉시 입주 가능' : '즉시 입주 불가능',
                  ['즉시 입주 가능', '즉시 입주 불가능'], (value) {
                setState(() {
                  moveInDate = value == '즉시 입주 가능'; // true/false 변환
                });
              }),
              const SizedBox(height: 10),
              _buildTextField('층수', _floorController),
              const SizedBox(height: 10),
              _buildTextField('관리비', _maintenanceFeeController),
              const SizedBox(height: 16),

              // 기본 옵션 정보
              const Text(
                '기본 옵션 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                children: optionIcons.entries.map((entry) {
                  return _buildOptionChip(entry.key, entry.value);
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              // 이미지 선택 버튼
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectImage,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: buttonColor),
                    child: const Text('이미지 선택'),
                  ),
                  if (selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onDoubleTap: () {
                          setState(() {
                            selectedImage = null; // 더블클릭 시 이미지 삭제
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이미지가 삭제되었습니다.')),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SizedBox(
                              width: 150, // 이미지의 너비
                              height: 150, // 이미지의 높이
                              child: selectedImage != null
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: Image.file(
                                        selectedImage!, // File 타입 이미지를 Image 위젯으로 변환
                                        fit: BoxFit.cover, // 이미지가 공간을 꽉 채우도록 설정
                                      ),
                                    )
                                  : const Placeholder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      print("선택된 옵션들: $selectedOptions"); // 디버깅용 출력

                      // selectedOptions에서 선택된 옵션들을 Map<String, dynamic> 형태로 변환
                      List<Map<String, dynamic>> optionsList =
                          selectedOptions.map((option) {
                        return {'option': option}; // Map 형태로 변환
                      }).toList();

                      // 게시물 생성
                      final postId = await widget.postService.createPost(
                        context,
                        _titleController.text.trim(),
                        _contentController.text.trim(),
                        tag: selectedTag,
                        image: selectedImage,
                        type: type,
                        roomType: title,
                        location: roomLocation,
                        parkingAvailable: parkingAvailable,
                        moveInDate: moveInDate,
                        floor: _floorController.text.trim(),
                        maintenanceFee: _maintenanceFeeController.text.trim(),
                        options: optionsList, // 변환된 optionsList 전달
                      );

                      // RoomDetailsScreen으로 이동
                      if (!mounted) return; // BuildContext가 유효하지 않은 경우 종료
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailsScreen(
                            postId: postId, // Firebase에서 postId를 가져왔다고 가정
                            selectedOptions: selectedOptions.toList(),
                            parkingAvailable: parkingAvailable,
                            moveInDate: moveInDate,
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('게시물 생성 중 오류가 발생했습니다: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                  ),
                  child: const Text('작성하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  // 이미지 선택 메서드
  Future<void> _selectImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      // 이미지가 선택되지 않은 경우
      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택하지 않았습니다.')),
        );
        return; // 함수 종료
      }

      // 이미지 선택 시, 파일을 읽어서 상태를 갱신합니다.
      setState(() {
        selectedImage = File(pickedFile.path); // 이미지를 선택한 후 상태 갱신
      });

      // 선택된 이미지로 작업을 추가적으로 할 경우 필요한 코드
      final bytes = await pickedFile.readAsBytes();
      print("선택한 이미지의 바이트 크기: ${bytes.length}"); // 디버깅용 출력
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 옵션 필터칩 빌드
  Widget _buildOptionChip(String option, IconData icon) {
    return FilterChip(
      avatar: Icon(icon), // 아이콘을 표시
      label: Text(option), // 옵션 이름을 표시
      selected: selectedOptions.contains(option), // 선택 여부
      onSelected: (isSelected) {
        setState(() {
          if (isSelected) {
            selectedOptions.add(option);
          } else {
            selectedOptions.remove(option);
          }
        });
        print(selectedOptions);
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _floorController.dispose();
    _maintenanceFeeController.dispose();
    super.dispose();
  }
}
