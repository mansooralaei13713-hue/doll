import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const DollStudioApp());

class DollStudioApp extends StatelessWidget {
  const DollStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF9A6BCE);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'عروسک‌ساز',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFFFF8FC),
        fontFamily: 'Roboto',
      ),
      home: const DollEditorPage(),
    );
  }
}

class DollEditorPage extends StatefulWidget {
  const DollEditorPage({super.key});

  @override
  State<DollEditorPage> createState() => _DollEditorPageState();
}

class _DollEditorPageState extends State<DollEditorPage> {
  final GlobalKey _canvasKey = GlobalKey();
  Color skin = const Color(0xFFFFD5B5);
  Color hair = const Color(0xFF593B2D);
  Color outfit = const Color(0xFFB99AE8);
  Color background = const Color(0xFFFFEEF5);
  int hairstyle = 0;
  int outfitStyle = 0;
  int eyes = 0;
  bool addBow = true;
  bool showCheeks = true;
  bool busy = false;

  final skinColors = const [
    Color(0xFFFFE0C2), Color(0xFFFFD0AD), Color(0xFFD99A6C),
    Color(0xFFAD704B), Color(0xFF75452F),
  ];
  final hairColors = const [
    Color(0xFF593B2D), Color(0xFF241B20), Color(0xFFB96D35),
    Color(0xFFE0B64E), Color(0xFF9B536D), Color(0xFF6B67B5),
  ];
  final outfitColors = const [
    Color(0xFFB99AE8), Color(0xFFFF8FAB), Color(0xFF79C8C1),
    Color(0xFFFFC857), Color(0xFF6F9CEB), Color(0xFFEC7965),
    Color(0xFF8DBB75), Color(0xFF48445C),
  ];
  final backgrounds = const [
    Color(0xFFFFEEF5), Color(0xFFEAF7FF), Color(0xFFFFF6D9),
    Color(0xFFE9F7E8), Color(0xFFF0E9FF), Color(0xFFFFFFFF),
  ];

  Future<void> exportPng() async {
    setState(() => busy = true);
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) throw Exception('PNG conversion failed');
      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/my_doll_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        title: 'عروسک طراحی‌شده من',
        text: 'عروسکم را با عروسک‌ساز طراحی کردم!',
        files: [XFile(file.path, mimeType: 'image/png')],
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تصویر PNG آماده شد؛ از پنجره اشتراک‌گذاری ذخیره‌اش کن.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ساخت تصویر ناموفق بود: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget colorChoices(List<Color> colors, Color selected, ValueChanged<Color> onPick) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: colors.map((c) => InkWell(
        onTap: () => onPick(c),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected == c ? 36 : 30,
          height: selected == c ? 36 : 30,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected == c ? const Color(0xFF5A3A73) : Colors.black12,
              width: selected == c ? 3 : 1,
            ),
          ),
          child: selected == c
              ? const Icon(Icons.check, size: 17, color: Colors.white)
              : null,
        ),
      )).toList(),
    );
  }

  Widget optionChips(String label, List<String> options, int selected, ValueChanged<int> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (i) => ChoiceChip(
            label: Text(options[i]),
            selected: selected == i,
            onSelected: (_) => onPick(i),
          )),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عروسک‌ساز ✨', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: const Color(0xFFFFF8FC),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: CustomPaint(
                        painter: DollPainter(
                          skin: skin, hair: hair, outfit: outfit,
                          background: background, hairstyle: hairstyle,
                          outfitStyle: outfitStyle, eyes: eyes,
                          addBow: addBow, showCheeks: showCheeks,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      const Text('ظاهر عروسکت را بساز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      const Text('رنگ پوست', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      colorChoices(skinColors, skin, (v) => setState(() => skin = v)),
                      const SizedBox(height: 16),
                      const Text('رنگ مو', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      colorChoices(hairColors, hair, (v) => setState(() => hair = v)),
                      const SizedBox(height: 16),
                      const Text('رنگ لباس', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      colorChoices(outfitColors, outfit, (v) => setState(() => outfit = v)),
                      const SizedBox(height: 16),
                      const Text('پس‌زمینه', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      colorChoices(backgrounds, background, (v) => setState(() => background = v)),
                      const SizedBox(height: 18),
                      optionChips('مدل مو', ['کوتاه', 'بلند', 'دم‌اسبی'], hairstyle,
                          (v) => setState(() => hairstyle = v)),
                      const SizedBox(height: 16),
                      optionChips('مدل لباس', ['پیراهن', 'دامن', 'شنل'], outfitStyle,
                          (v) => setState(() => outfitStyle = v)),
                      const SizedBox(height: 16),
                      optionChips('چشم‌ها', ['گرد', 'لبخندی', 'درشت'], eyes,
                          (v) => setState(() => eyes = v)),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('پاپیون مو'),
                        value: addBow,
                        onChanged: (v) => setState(() => addBow = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('گونه‌های صورتی'),
                        value: showCheeks,
                        onChanged: (v) => setState(() => showCheeks = v),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: busy ? null : exportPng,
                        icon: busy
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.image_outlined),
                        label: Text(busy ? 'در حال آماده‌سازی...' : 'خروجی تصویر PNG'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'نکته: تصویر از بخش پیش‌نمایش گرفته می‌شود. در پنجره اشتراک‌گذاری می‌توانی آن را در فایل‌ها یا برنامه دلخواه ذخیره کنی.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DollPainter extends CustomPainter {
  final Color skin, hair, outfit, background;
  final int hairstyle, outfitStyle, eyes;
  final bool addBow, showCheeks;

  DollPainter({
    required this.skin, required this.hair, required this.outfit,
    required this.background, required this.hairstyle,
    required this.outfitStyle, required this.eyes,
    required this.addBow, required this.showCheeks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360;
    final sy = size.height / 440;
    canvas.save();
    canvas.scale(sx, sy);
    final p = Paint()..isAntiAlias = true;
    final outline = Paint()
      ..color = const Color(0xFF49364F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Floating decorative stars
    p.color = const Color(0xFFFFD166);
    for (final o in const [Offset(58, 72), Offset(298, 104), Offset(285, 280), Offset(73, 322)]) {
      _star(canvas, o, 9, p);
    }
    p.color = const Color(0xFFFFB7CF);
    canvas.drawCircle(const Offset(54, 190), 5, p);
    canvas.drawCircle(const Offset(308, 205), 6, p);

    // Hair behind head
    p.color = hair;
    if (hairstyle == 1) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(113, 87, 134, 151), const Radius.circular(62)), p);
    } else if (hairstyle == 2) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(119, 83, 122, 130), const Radius.circular(55)), p);
      canvas.drawCircle(const Offset(239, 123), 27, p);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(124, 91, 112, 115), const Radius.circular(48)), p);
    }

    // Neck
    p.color = skin;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(159, 201, 42, 44), const Radius.circular(14)), p);

    // Arms
    p.color = skin;
    final leftArm = Path()..moveTo(133, 244)..quadraticBezierTo(111, 261, 105, 292)..quadraticBezierTo(104, 305, 116, 307)..quadraticBezierTo(126, 305, 130, 291)..lineTo(151, 265)..close();
    final rightArm = Path()..moveTo(227, 244)..quadraticBezierTo(249, 261, 255, 292)..quadraticBezierTo(256, 305, 244, 307)..quadraticBezierTo(234, 305, 230, 291)..lineTo(209, 265)..close();
    canvas.drawPath(leftArm, p); canvas.drawPath(leftArm, outline);
    canvas.drawPath(rightArm, p); canvas.drawPath(rightArm, outline);

    // Legs and shoes
    p.color = skin;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(151, 335, 24, 54), const Radius.circular(12)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(185, 335, 24, 54), const Radius.circular(12)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(139, 376, 42, 20), const Radius.circular(10)), Paint()..color = const Color(0xFF8B6BC1));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(179, 376, 42, 20), const Radius.circular(10)), Paint()..color = const Color(0xFF8B6BC1));

    // Outfit
    p.color = outfit;
    final dress = Path();
    if (outfitStyle == 0) {
      dress.moveTo(148, 232); dress.lineTo(212, 232); dress.quadraticBezierTo(226, 277, 246, 344);
      dress.quadraticBezierTo(180, 363, 114, 344); dress.quadraticBezierTo(134, 277, 148, 232);
    } else if (outfitStyle == 1) {
      dress.moveTo(148, 232); dress.lineTo(212, 232); dress.lineTo(232, 289);
      dress.quadraticBezierTo(180, 309, 128, 289); dress.close();
    } else {
      dress.moveTo(148, 232); dress.lineTo(212, 232); dress.lineTo(246, 330);
      dress.lineTo(114, 330); dress.close();
    }
    dress.close();
    canvas.drawPath(dress, p); canvas.drawPath(dress, outline);
    // Collar and buttons
    p.color = const Color(0xFFFFF7FC);
    canvas.drawCircle(const Offset(180, 239), 8, p);
    p.color = const Color(0xFFFFD166);
    for (int i = 0; i < 3; i++) canvas.drawCircle(Offset(180, 267 + i * 17.0), 3.5, p);

    // Head
    p.color = skin;
    canvas.drawOval(const Rect.fromLTWH(125, 88, 110, 130), p);
    canvas.drawOval(const Rect.fromLTWH(125, 88, 110, 130), outline);

    // Fringe / hair cap
    p.color = hair;
    final fringe = Path()
      ..moveTo(126, 145)
      ..quadraticBezierTo(119, 91, 173, 84)
      ..quadraticBezierTo(220, 75, 235, 121)
      ..quadraticBezierTo(211, 111, 198, 128)
      ..quadraticBezierTo(177, 145, 153, 125)
      ..quadraticBezierTo(143, 143, 126, 145)
      ..close();
    canvas.drawPath(fringe, p);

    // Eyes
    if (eyes == 1) {
      canvas.drawArc(const Rect.fromLTWH(146, 150, 24, 16), 0.15, 2.8, false, outline);
      canvas.drawArc(const Rect.fromLTWH(190, 150, 24, 16), 0.15, 2.8, false, outline);
    } else {
      p.color = const Color(0xFF342B3A);
      final r = eyes == 2 ? 7.0 : 5.0;
      canvas.drawCircle(const Offset(158, 157), r, p);
      canvas.drawCircle(const Offset(202, 157), r, p);
      p.color = Colors.white;
      canvas.drawCircle(const Offset(160, 155), 1.8, p);
      canvas.drawCircle(const Offset(204, 155), 1.8, p);
    }
    // Nose and smile
    p.color = const Color(0xFFCB8C7A);
    canvas.drawCircle(const Offset(180, 174), 2.4, p);
    canvas.drawArc(const Rect.fromLTWH(165, 174, 30, 22), 0.2, 2.7, false, outline);
    if (showCheeks) {
      p.color = const Color(0x55F16D9A);
      canvas.drawOval(const Rect.fromLTWH(137, 173, 20, 10), p);
      canvas.drawOval(const Rect.fromLTWH(203, 173, 20, 10), p);
    }

    if (addBow) {
      p.color = const Color(0xFFFF729F);
      final bow = Path()..moveTo(217, 105)..quadraticBezierTo(236, 88, 239, 107)..quadraticBezierTo(235, 120, 217, 105)..close();
      final bow2 = Path()..moveTo(218, 105)..quadraticBezierTo(199, 89, 198, 108)..quadraticBezierTo(202, 121, 218, 105)..close();
      canvas.drawPath(bow, p); canvas.drawPath(bow2, p);
      p.color = const Color(0xFFFFD166); canvas.drawCircle(const Offset(218, 105), 4, p);
    }

    // Little label
    final tp = TextPainter(
      text: const TextSpan(text: 'MY LITTLE DOLL', style: TextStyle(
        color: Color(0xFF9B7BA6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((360 - tp.width) / 2, 412));
    canvas.restore();
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 3.14159265 / 5;
      final r = i.isEven ? radius : radius * 0.42;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) { path.moveTo(point.dx, point.dy); } else { path.lineTo(point.dx, point.dy); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DollPainter oldDelegate) =>
      skin != oldDelegate.skin || hair != oldDelegate.hair ||
      outfit != oldDelegate.outfit || background != oldDelegate.background ||
      hairstyle != oldDelegate.hairstyle || outfitStyle != oldDelegate.outfitStyle ||
      eyes != oldDelegate.eyes || addBow != oldDelegate.addBow ||
      showCheeks != oldDelegate.showCheeks;
}
