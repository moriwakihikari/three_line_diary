import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ユーザー情報の受け渡しを行うためのProvider
final userProvider = StateProvider((ref) {
  return FirebaseAuth.instance.currentUser;
});

// エラー情報の受け渡しを行うためのProvider
// ※ autoDisposeを付けることで自動的に値をリセットできます
final infoTextProvider = StateProvider.autoDispose((ref) {
  return '';
});

// メールアドレスの受け渡しを行うためのProvider
// ※ autoDisposeを付けることで自動的に値をリセットできます
final emailProvider = StateProvider.autoDispose((ref) {
  return '';
});

// パスワードの受け渡しを行うためのProvider
// ※ autoDisposeを付けることで自動的に値をリセットできます
final passwordProvider = StateProvider.autoDispose((ref) {
  return '';
});

// メッセージの受け渡しを行うためのProvider
// ※ autoDisposeを付けることで自動的に値をリセットできます
final messageTextProvider = StateProvider.autoDispose((ref) {
  return '';
});

// StreamProviderを使うことでStreamも扱うことができる
// ※ autoDisposeを付けることで自動的に値をリセットできます
final postsQueryProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('date')
      .snapshots();
});

void main() async {
  // 初期化処理
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    // Riverpodでデータを受け渡しできる状態にする
    ProviderScope(
      child: ThreeLineDiary(),
    ),
  );
}

class ThreeLineDiary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreeLineDiary',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから値を受け取る
    final infoText = ref.watch(infoTextProvider);
    final email = ref.watch(emailProvider);
    final password = ref.watch(passwordProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('ログイン'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // メールアドレス入力
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  // Providerから値を更新
                  ref.read(emailProvider.state).state = value;
                },
              ),
              // パスワード入力
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  // Providerから値を更新
                  ref.read(passwordProvider.state).state = value;
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                // ユーザー登録ボタン
                child: ElevatedButton(
                  child: Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                          email: email, password: password);
                      // ユーザー情報を更新
                      // userState.setUser(result.user!);
                      // ユーザー登録に成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ThreeLineDiaryPage();
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      // Providerから値を更新
                      ref.read(infoTextProvider.state).state =
                          "登録に失敗しました：${e.toString()}";
                    }
                  },
                ),
              ),
              const SizedBox(height: 0),
              Container(
                  width: double.infinity,
                  child: OutlinedButton(
                      child: Text('ログイン'),
                      onPressed: () async {
                        try {
                          // メール/パスワードでログイン
                          final FirebaseAuth auth = FirebaseAuth.instance;
                          final result = await auth.signInWithEmailAndPassword(
                              email: email, password: password);

                          // ユーザー情報を更新
                          // userState.setUser(result.user!);
                          // ログインに成功した場合
                          // チャット画面に遷移＋ログイン画面を破棄
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                              return ThreeLineDiaryPage();
                            }),
                          );
                        } catch (e) {
                          // ログインに失敗した場合
                          ref.read(infoTextProvider.state).state =
                              "ログインに失敗しました。";
                          print(e);
                        }
                      }))
            ],
          ),
        ),
      ),
    );
  }
}

// 日記投稿ページ
class ThreeLineDiaryPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providerから値を受け取る
    final User user = ref.watch(userProvider)!;
    return Scaffold(
        appBar: AppBar(title: Text('ThreeLineDiaryPage'), actions: <Widget>[
          IconButton(
              onPressed: () async {
                // ログアウト処理
                // 内部で保持しているログイン情報等が初期化される
                // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
                await FirebaseAuth.instance.signOut(); // ログイン画面に遷移＋チャット画面を破棄
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) {
                    return LoginPage();
                  }),
                );
              },
              icon: Icon(Icons.close))
        ]),
        body: Column(
          children: [
            Container(
                padding: EdgeInsets.all(8), child: Text('ログイン情報:${user.email}'))
          ],
        ));
  }
}
<<<<<<< Updated upstream
=======

DateTime _focused = DateTime.now();
DateTime? _selected; //追記

class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  State<Calender> createState() => _CalenderState();
}

class _CalenderState extends State<Calender> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ThreeLineDiaryPage'), actions: <Widget>[
        IconButton(
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut(); // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
            icon: Icon(Icons.close))
      ]),
      body: Center(
        child: TableCalendar(
          firstDay: DateTime.utc(2022, 4, 1),
          lastDay: DateTime.utc(2025, 12, 31),
          selectedDayPredicate: (day) {
            return isSameDay(_selected, day);
          },
          // --追記----------------------------------
          onDaySelected: (selected, focused) {
            if (!isSameDay(_selected, selected)) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
            }
          },
          focusedDay: _focused,
          // --追記----------------------------------
        ),
      ),
      // フローティングアクションボタンを追加
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 投稿画面に遷移する処理
          // _selected が null でないことを確認
          if (_selected != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return PostPage(selectedDate: _selected!);
              }),
            );
          } else {
            // 選択された日付がない場合の処理（例：エラーメッセージの表示）
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('日付が選択されていません。')),
            );
          }
        },
        child: Icon(Icons.add), // プラスアイコン
      ),
    );
  }
}

class PostPage extends StatelessWidget {
  final DateTime selectedDate;

  // コンストラクタで日付を受け取る
  PostPage({Key? key, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('投稿画面'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ('選択された日付: ${selectedDate.toLocal()}'),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: '良かったこと'),
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: '悪かったこと'),
            ),
            SizedBox(height: 20),
            TextFormField(
              decoration: InputDecoration(labelText: '明日の目標'),
            ),
            SizedBox(height: 20),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(labelText: '補足'),
            ),
            SizedBox(height: 20),
            Center(
              // Centerウィジェットを使用して中央に配置
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return Calender();
                    }),
                  );
                },
                child: Text('登録する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> Stashed changes
