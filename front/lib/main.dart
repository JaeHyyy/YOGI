import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 웹/권한 없는 환경에서도 앱은 뜨게 — 카메라는 있으면 쓰고 없으면 플레이스홀더
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (_) {
    cameras = [];
  }

  runApp(YogiApp(cameras: cameras));
}

class YogiApp extends StatelessWidget {
  const YogiApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

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
      home: CameraHomeScreen(cameras: cameras),
    );
  }
}

/// 앱 첫화면: 카메라 풀스크린 + 하단 포스트잇 메뉴
class CameraHomeScreen extends StatefulWidget {
  const CameraHomeScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends State<CameraHomeScreen> {
  CameraController? _controller;
  String? _cameraError;
  bool _initializing = true;

  // 하단 탭: 0 주변 / 1 붙이기 / 2 내메모
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // 상태바를 카메라 위에 얹는 느낌
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _initializing = false;
        _cameraError = '카메라를 찾을 수 없어요';
      });
      return;
    }

    final controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      await controller.dispose();
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

  void _onTab(int index) {
    setState(() => _tabIndex = index);
    // ponytail: 아직 화면 전환 없음. 나중에 주변/작성/내메모 연결.
    final labels = ['주변 메모', '메모 붙이기', '내 메모'];
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${labels[index]} — 준비 중'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 카메라 (또는 플레이스홀더)
          _buildCameraLayer(),

          // 2) 위쪽 살짝 그라데이션 — 상태/브랜드만
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

          // 3) 하단 포스트잇 메뉴
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
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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

    // 웹/권한 없을 때 — 카메라 느낌 플레이스홀더
    return _CameraPlaceholder(message: _cameraError);
  }
}

/// 카메라 없을 때 배경 (웹 터널 확인용)
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
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '실기기/권한 허용 시 카메라가 켜져요',
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
              // 가운데: 포스트잇 "붙이기"
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
