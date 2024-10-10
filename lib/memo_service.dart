import 'dart:convert';

import 'package:flutter/material.dart';

import 'main.dart';

// Memo 데이터의 형식을 정해줍니다. 추후 isPinned, updatedAt 등의 정보도 저장할 수 있습니다.
class Memo {
  Memo({
    required this.content,
    // required this.isPinned, // 이렇게 해줘도 되고
    this.isPinned = false,
    this.updatedAt,
  });

  String content;
  bool isPinned;
  DateTime? updatedAt;

  Map toJson() {
    return {
      'content': content,
      'isPinned': isPinned,
      'updateAt': updatedAt?.toIso8601String(),
    };
  }

  factory Memo.fromJson(json) {
    return Memo(
      content: json['content'],
      isPinned: json['isPinned'] ?? false,
      updatedAt:
          json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt']),
    );
  }
}

// Memo 데이터는 모두 여기서 관리
class MemoService extends ChangeNotifier {
  MemoService() {
    loadMemoList();
  }

  List<Memo> memoList = [
    Memo(content: '장보기 목록: 과자, 양파'), // 더미(dummy) 데이터
    Memo(content: '새 메모'), // 더미(dummy) 데이터
  ];

  createMemo({required String content}) {
    Memo memo = Memo(content: content, updatedAt: DateTime.now());
    memoList.add(memo);
    notifyListeners(); // Consumer<MemoService>의 builder 부분을 호출해서 화면 새로고침
    saveMemoList();
  }

  updateMemo({required int index, required String content}) {
    Memo memo = memoList[index];
    memo.content = content;
    memo.updatedAt = DateTime.now();
    notifyListeners();
    saveMemoList();
  }

  updatePinMemo({required int index}) {
    Memo memo = memoList[index];
    memo.isPinned = !memo.isPinned; // true는 false로, false는 true로
    memoList = [
      // ... 은 iterable list 와 유사하게 여러요소들이 같이 들어있는 요소들을 풀어헤쳐주는 것
      ...memoList.where((element) => element.isPinned), // 위에
      ...memoList.where((element) => !element.isPinned) // 밑에
    ];
    notifyListeners();
    saveMemoList();
  }

  deleteMemo({required int index}) {
    memoList.removeAt(index);
    notifyListeners();
    saveMemoList();
  }

  saveMemoList() {
    List memoJsonList = memoList.map((memo) => memo.toJson()).toList();
    // [{"content": "1"}, {"content": "2"}]

    String jsonString = jsonEncode(memoJsonList);
    // '[{"content": "1"}, {"content": "2"}]'

    prefs.setString('memoList', jsonString);
  }

  loadMemoList() {
    String? jsonString = prefs.getString('memoList');
    // '[{"content": "1"}, {"content": "2"}]'

    if (jsonString == null) return; // null 이면 로드하지 않음

    List memoJsonList = jsonDecode(jsonString);
    // [{"content": "1"}, {"content": "2"}]

    memoList = memoJsonList.map((json) => Memo.fromJson(json)).toList();
  }
}
