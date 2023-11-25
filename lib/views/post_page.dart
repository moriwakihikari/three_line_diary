import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:three_line_diary/views/calendar.dart';
import 'package:three_line_diary/views/login.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class PostPage extends ConsumerWidget {
  final TextEditingController positiveAspectController =
      TextEditingController();
  final TextEditingController challengeController = TextEditingController();
  final TextEditingController tomorrowGoalController = TextEditingController();
  final TextEditingController additionalNoteController =
      TextEditingController();
  // コンストラクタで日付を受け取る
  PostPage();

  void registerData(BuildContext context, WidgetRef ref) async {
    final User user = ref.watch(userProvider)!;
    String userId = user.uid; // ユーザーIDを適切に設定してください。
    await FirebaseFirestore.instance.collection('diary').add({
      'positiveAspects': positiveAspectController.text,
      'challenges': challengeController.text,
      'tomorrowGoals': tomorrowGoalController.text,
      'additionalNotes': additionalNoteController.text,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'userId': userId,
    });

    // データ登録後の処理（例：ダイアログ表示、ページ遷移など）をここに追加。
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider)!;
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
              ('選択された日付: ${DateFormat('yyyy/MM/dd').format(selectedDate.toLocal())}'),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: positiveAspectController,
              decoration: InputDecoration(labelText: '良かったこと'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: challengeController,
              decoration: InputDecoration(labelText: '悪かったこと'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: tomorrowGoalController,
              decoration: InputDecoration(labelText: '明日の目標'),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: additionalNoteController,
              maxLines: 3,
              decoration: InputDecoration(labelText: '補足'),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  registerData(context, ref);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return Calendar(); // Calendarの実装に合わせてください。
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
