import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// 로컬 임시 메모 (서버 연동 전)
class MemoNote {
  MemoNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.photoBytes,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final Uint8List? photoBytes; // 사진 최대 1장
}

/// ponytail: 앱 메모리에만 보관. 나중에 Spring API로 교체.
class MemoStore extends ChangeNotifier {
  MemoStore._();
  static final MemoStore instance = MemoStore._();

  final List<MemoNote> _notes = [];

  List<MemoNote> get notes => List.unmodifiable(_notes);

  void add({required String text, Uint8List? photoBytes}) {
    _notes.insert(
      0,
      MemoNote(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text.trim(),
        createdAt: DateTime.now(),
        photoBytes: photoBytes,
      ),
    );
    notifyListeners();
  }

  void remove(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
