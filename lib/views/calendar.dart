import 'dart:collection';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:three_line_diary/views/post_page.dart';
import 'package:three_line_diary/views/login.dart';

// カレンダーの受け渡しを行うためのProvider
final selectedDateProvider = StateProvider<DateTime?>((ref) {
  return DateTime.now(); // 現在の日時を初期値として設定;
});

// カレンダーの受け渡しを行うためのProvider
final focusedCalendarProvider = StateProvider<DateTime?>((ref) {
  return DateTime.now(); // 現在の日時を初期値として設定;
});

// StreamProviderを使うことでStreamも扱うことができる
// ※ autoDisposeを付けることで自動的に値をリセットできます
final postsQueryProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance
      .collection('diary')
      .orderBy('updatedAt')
      .snapshots();
});

DateTime _focused = DateTime.now();
DateTime? _selected; //追記

class Calendar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int getHashCode(DateTime key) {
      return key.day * 1000000 + key.month * 10000 + key.year;
    }

    final AsyncValue<QuerySnapshot> asyncPostsQuery =
        ref.watch(postsQueryProvider);
    final _eventsList = asyncPostsQuery.when(
      data: (QuerySnapshot snapshot) {
        // イベントを格納する新しいマップを作成
        final Map<DateTime, List<String>> events = {};

        // スナップショット内の各ドキュメントをイテレート
        for (final document in snapshot.docs) {
          // 'date'がドキュメントのTimestampフィールドであると仮定
          final Timestamp timestamp = document.get('createdAt');
          final DateTime date = timestamp.toDate();
          final String diaryEntry =
              document.get('tomorrowGoals'); // 実際のフィールド名に置き換えてください

          // その日付のリストが既に存在するかを確認し、なければ作成
          events.putIfAbsent(date, () => []);
          // その日付のリストに日記エントリを追加
          events[date]!.add(diaryEntry);
        }

        return events;
      },
      loading: () => <DateTime, List<String>>{}, // ロード中は空のマップを返す
      error: (e, stack) => <DateTime, List<String>>{}, // エラー時は空のマップを返す
    );
    //--追記--------------------------------------------------------------

    final _events = LinkedHashMap<DateTime, List<String>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(_eventsList);

    List getEvent(DateTime day) {
      return _events[day] ?? [];
    }

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
          Center(
            child: TableCalendar(
              firstDay: DateTime.utc(2022, 4, 1),
              lastDay: DateTime.utc(2025, 12, 31),
              eventLoader: getEvent,
              selectedDayPredicate: (day) {
                return isSameDay(ref.watch(selectedDateProvider), day);
              },
              // --追記----------------------------------
              onDaySelected: (selected, focused) {
                if (!isSameDay(ref.watch(selectedDateProvider), selected)) {
                  ref.read(selectedDateProvider.state).state = selected;
                  ref.read(focusedCalendarProvider.state).state = focused;
                }
              },
              focusedDay: _focused,
              // --追記----------------------------------
            ),
          ),
          Expanded(
            child: asyncPostsQuery.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('エラーが発生しました: $err'),
              data: (QuerySnapshot snapshot) {
                // Firestoreのデータをリストとして表示
                return ListView(
                  children: snapshot.docs.map((document) {
                    return ListTile(
                      title: Text(
                          document['positiveAspects']), // 例: 'title'フィールドを表示
                      subtitle: Text(
                          document['challenges']), // 例: 'description'フィールドを表示
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      // フローティングアクションボタンを追加
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 投稿画面に遷移する処理
          // _selected が null でないことを確認
          if ((ref.watch(selectedDateProvider)) != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return PostPage();
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
