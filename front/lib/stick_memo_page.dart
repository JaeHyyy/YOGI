import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'memo_store.dart';

/// 포스트잇에 글/사진 붙이는 작성 화면
class StickMemoPage extends StatefulWidget {
  const StickMemoPage({super.key});

  @override
  State<StickMemoPage> createState() => _StickMemoPageState();
}

class _StickMemoPageState extends State<StickMemoPage> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // 갤러리에서 1장만 — 카메라 촬영은 나중에 AR 플로우와 합침
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _photoBytes = bytes);
  }

  void _clearPhoto() => setState(() => _photoBytes = null);

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메모 내용을 적어주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    MemoStore.instance.add(text: text, photoBytes: _photoBytes);
    if (!mounted) return;
    Navigator.of(context).pop(true); // 저장 완료
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('메모 붙이기'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              '붙이기',
              style: TextStyle(
                color: _saving ? Colors.white38 : const Color(0xFFFFF59D),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // 실제 포스트잇 느낌 카드
            Transform.rotate(
              angle: -0.02,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF59D),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 16,
                      offset: Offset(4, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.push_pin,
                        color: Color(0xFFC62828),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      minLines: 5,
                      maxLength: 280,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: const Color(0xFFC62828),
                      decoration: const InputDecoration(
                        hintText: '이 자리에 남길 말을 적어봐…',
                        hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: Color(0xFF757575)),
                      ),
                    ),
                    if (_photoBytes != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_photoBytes!, fit: BoxFit.cover),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _clearPhoto,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 사진 최대 1장
            OutlinedButton.icon(
              onPressed: _photoBytes == null ? _pickPhoto : null,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _photoBytes == null ? '사진 추가 (최대 1장)' : '사진이 이미 있어요',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFF59D),
                side: const BorderSide(color: Color(0x66FFF59D)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '지금은 기기에만 저장돼요. 서버 연동은 다음 단계.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
