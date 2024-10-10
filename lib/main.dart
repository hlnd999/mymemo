import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memo_service.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  // MultiProvider로 MyApp을 감싸서 모든 위젯들의 최상단에 provider들을 등록
  // MultiProvider: 위젯트리 꼭대기에 여러 Service 들을 등록할 수 있도록 만들 때 사용
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemoService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List<String> memoList = ['장보기 목록: 사과, 양파', '새 메모']; // 전체 메모 목록

  // setState()는 build 를 계속해서 실행한다면,
  // Provider는 Consumer아래부분만 계속 실행
  @override
  Widget build(BuildContext context) {
    // print('HomePage build');
    // MemoService에 있는 memoList 값을 가져와서 HomePage에 보여줘야 함
    // Consumer 위젯을 이용하면 위젯트리 꼭대기에 등록된 MemoService에 접근할 수 있음
    // Scaffold()를 Builder()로 감싸주고 Builder를 Consumer<MemoService>로 변경
    // Consumer()는 (context, memoService, child) 세개의 매개변수를 가지고 있어야 함
    return Consumer<MemoService>(
      builder: (context, memoService, child) {
        // print('Consumer build');
        // memoService로 부터 memoList 가져오기
        List<Memo> memoList = memoService.memoList;
        // Provider 등록 이후는 위 memoList 사용 -> List<String> memoList 주석처리!

        return Scaffold(
          appBar: AppBar(
            title: Text("mymemo"),
          ),
          // body: (조건문)
          //      ? (참일때 실행)
          //      : (거짓일때 실행)
          body: memoList.isEmpty
              ? Center(child: Text("메모를 작성해 주세요"))
              : ListView.builder(
                  itemCount: memoList.length, // memoList 개수 만큼 보여주기
                  itemBuilder: (context, index) {
                    Memo memo = memoList[index]; // index에 해당하는 memo 가져오기
                    return ListTile(
                      // 메모 고정 아이콘
                      leading: IconButton(
                        icon: Icon(memo.isPinned
                            ? CupertinoIcons.pin_fill
                            : CupertinoIcons.pin),
                        onPressed: () {
                          memoService.updatePinMemo(index: index);
                        },
                      ),
                      // 메모 내용 (최대 3줄까지만 보여주도록)
                      title: Text(
                        // memo -> memo.content 로 변경
                        memo.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(memo.updatedAt == null
                          ? ""
                          : memo.updatedAt.toString().substring(1, 19)),
                      onTap: () async {
                        // 아이템 클릭시
                        await Navigator.push(
                          // push가 비동기 함수기 때문에 await 걸어주고 -> async도 함께
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(
                              // memoList: memoList,
                              index: index,
                            ),
                          ),
                        );
                        // DetailPage로 가서 지우면 해당 메모가 비어있으면 삭제하는 로직
                        if (memo.content.isEmpty) {
                          memoService.deleteMemo(index: index);
                        }
                      },
                    );
                  },
                ),
          // + 버튼 클릭시 메모 생성 및 수정 페이지로 이동
          // String memo = ''; // 빈 메모 내용 추가
          // // RangeError 에러 이후 memoList.add(memo); 붙여넣기
          // // 새메모 추가하고 리스트로 돌아왔을때 새 메모가 안보이는(화면에서만) ->
          // // -> 상태변화 필요 setState()함수로 감싸줌
          // setState(() {
          //   memoList.add(memo);
          // });
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => DetailPage(
          //       index: memoList.indexOf(memo),
          //       memoList: memoList,
          //       // index 와 memoList 가지고 DetailPage 로 넘어가거라! 명령
          //     ),
          //   ),
          // );
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              // + 버튼 클릭시, memoService에 있는 createMemo실행되도록!
              memoService.createMemo(content: '');
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    index: memoService.memoList.length - 1,
                  ),
                ),
              );
              // (+) 버튼 클릭 후 아무것도 입력하지 않았을때: 비어있으면 삭제 로직
              if (memoList.last.content.isEmpty) {
                memoService.deleteMemo(index: memoList.length - 1);
              }
            },
          ),
        );
      },
    );
  }
}

// 메모 생성 및 수정 페이지
class DetailPage extends StatelessWidget {
  // DetailPage({super.key, required this.memoList, required this.index});
  // final List<String> memoList;
  // memoList 관련한것을 다 없애줌
  DetailPage({super.key, required this.index});

  final int index;
  // 위를 붙여주면 DetailPage에 RangeError 에러 뜸
  // memoList 와 index 변수를 만들어줬는데 생성자가 없어서
  // 생성자 = 클래스이름과 똑같은 함수 이함수는 클래스가 객체를 통해서 만들어질때 실행되는 함수

  TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // contentController 는 초기값을 설정할수 있는데
    // 넘겨받은 memoList로 구현

    // contentController.text = memoList[index]; // 대신, 아래 붙여넣기!
    MemoService memoService = context.read<MemoService>();
    Memo memo = memoService.memoList[index];
    // context.read<클래스명>();를 이용하면 위젯 트리 상단의 Provider로 등록한 클래스에 접근할 수 있음
    // Consumer 를 사용 : 변화에 따라 화면을 새로 그려줄 필요가 있을 때!
    // context.read<클래스명>() 를 사용 : 화면을 새로고침할 필요없이 MemoService 의 변수나 함수만 이용할때

    contentController.text = memo.content;

    // 리스트에서 (+) 버튼 누르면 에러 -> RangeError (length): Invalid value:
    // Not in inclusive range 0..1 : -1
    // floatingActionButton (+버튼) ->
    // memo 에 있는 몇번째 인덱스인지 찾으려고 했는데 없음

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              // 삭제 버튼 클릭시 showDialog를 리펙토링해서, extract method 를 통해
              showDeleteDialog(context, memoService);
            },
            icon: Icon(Icons.delete),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: contentController,
          decoration: InputDecoration(
            hintText: "메모를 입력하세요",
            border: InputBorder.none,
          ),
          autofocus: true,
          maxLines: null,
          expands: true,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            // 텍스트필드 안의 값이 변할 때
            // memoList[index] = value;
            // 화면에 바로바로 반영되게 하는 setState 사용 불가!
            // 내용 수정은 DetailPage 에서, 내용을 보여주는건 HomePage에서 했기 때문
            memoService.updateMemo(index: index, content: value);
            // value 는 onChanged: 에서 넘겨받은값,
            // index는 DetailPage 시작부분 final int index; 에서 설정해준
          },
        ),
      ),
    );
  }

  // Future<dynamic> showDeleteDialog( 에서,
  // Future<dynamic>를 void 로 변경
  // return showDialog( 에서 return 삭제
  void showDeleteDialog(BuildContext context, MemoService memoService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("정말로 삭제하시겠습니까?"),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("취소"),
            ),
            // 확인 버튼
            TextButton(
              onPressed: () {
                // memoList.removeAt(index); // index에 해당하는 항목 삭제
                memoService.deleteMemo(index: index); // Producer 생성 이후
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // HomePage 로 가기
              },
              child: Text(
                "확인",
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        );
      },
    );
  }
}
