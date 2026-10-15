import 'package:flutter/material.dart';

import 'memo_store.dart';

/// 내가 붙인 메모 목록 (로컬)
class MyMemosPage extends StatelessWidget {
  const MyMemosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MemoStore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('내 메모'),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final notes = store.notes;
          if (notes.isEmpty) {
            return Center(
              child: Text(
                '아직 붙인 메모가 없어요',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: ValueKey(note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => store.remove(note.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF59D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.text,
                        style: const TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      if (note.photoBytes != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            note.photoBytes!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(note.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$y.$m.$d $h:$min';
  }
}
