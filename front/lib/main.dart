import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'my_memos_page.dart';
import 'stick_memo_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 카메라 대기하면 iOS Safari에서 흰 화면으로 멈춤 → UI 먼저 띄움
  runApp(const YogiApp());
}

class YogiApp extends StatelessWidget {
  const YogiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOGI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4D35E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CameraHomeScreen(),
    );
  }
}

/// 앱 첫화면: 카메라 풀스크린 + 하단 포스트잇 메뉴
class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  CameraController? _controller;
  String? _cameraError;
  // false로 시작 → 카메라 실패해도 메뉴는 바로 보임
  bool _initializing = false;

  // 하단 탭: 0 주변 / 1 붙이기 / 2 내메모
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // 다음 프레임 후 카메라 시도 — UI 먼저 그림
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  Future<void> _initCamera() async {
    // 웹(특히 iOS Safari): 카메라 API가 앱 전체를 죽이거나 멈춤
    // AR 카메라는 네이티브 앱에서 보고, 웹은 플레이스홀더 + 메뉴만
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _cameraError = '웹에서는 카메라 대신 미리보기 화면이에요';
      });
      return;
    }

    setState(() => _initializing = true);

    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <CameraDescription>[],
      );
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _cameraError = '카메라를 찾을 수 없어요';
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize().timeout(const Duration(seconds: 5));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
        _cameraError = null;
      });
    } catch (_) {
      await _controller?.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = '카메라 권한이 필요해요';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onTab(int index) async {
    setState(() => _tabIndex = index);

    if (index == 1) {
      // 붙이기 → 포스트잇 작성
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const StickMemoPage()),
      );
      if (!mounted) return;
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모를 붙였어요'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
      return;
    }

    if (index == 2) {
      // 내메모 목록
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyMemosPage()),
      );
      return;
    }

    // 주변: 아직 GPS/서버 없음
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('주변 메모 — 준비 중'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2430),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 카메라 (또는 플레이스홀더) — 실패해도 아래 메뉴는 항상 보임
          _buildCameraLayer(),

          // 2) 위쪽 그라데이션 + 브랜드
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
                child: SizedBox(height: 120),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'YOGI',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
            ),
          ),

          // 3) 하단 포스트잇 메뉴 — 카메라와 무관하게 항상 표시
          Align(
            alignment: Alignment.bottomCenter,
            child: _PostItBottomBar(
              selectedIndex: _tabIndex,
              onTap: _onTab,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    final controller = _controller;
    if (_initializing) {
      return const ColoredBox(
        color: Color(0xFF1B2430),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFFF59D),
          ),
        ),
      );
    }

    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      );
    }

    return _CameraPlaceholder(message: _cameraError);
  }
}

/// 카메라 없을 때 배경 (웹/권한 없음)
class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B2430),
            Color(0xFF3D2C29),
            Color(0xFF2A3A2E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '카메라 미리보기',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '앱에서는 카메라가 켜져요',
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

/// 하단 메뉴 — 가운데만 포스트잇 버튼
class _PostItBottomBar extends StatelessWidget {
  const _PostItBottomBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xCC141414),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.place_outlined,
                  label: '주변',
                  selected: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              GestureDetector(
                onTap: () => onTap(1),
                child: Transform.rotate(
                  angle: -0.06,
                  child: Container(
                    width: 72,
                    height: 72,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF59D),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 10,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.push_pin, color: Color(0xFFC62828), size: 20),
                        SizedBox(height: 2),
                        Text(
                          '붙이기',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.sticky_note_2_outlined,
                  label: '내메모',
                  selected: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFFFF59D) : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
