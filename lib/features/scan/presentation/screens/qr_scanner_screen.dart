import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:easy_localization/easy_localization.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  bool _flashOn = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController c) async {
    controller = c;

    // Setea estado inicial del flash si la lib lo soporta
    try {
      final status = await controller?.getFlashStatus();
      if (mounted && status != null) setState(() => _flashOn = status);
    } catch (_) {}

    c.scannedDataStream.listen((scanData) async {
      if (isProcessing) return;
      isProcessing = true;

      final code = scanData.code;
      if (code != null) {
        await _handleScan(code);
      }

      await Future.delayed(const Duration(seconds: 1));
      isProcessing = false;
    });
  }

  /// 👉 Lógica cuando se escanea un código
  Future<void> _handleScan(String rawCode) async {
    final code = rawCode.trim();

    // Tus QR traen el ID de la pieza (ej: "376")
    final id = int.tryParse(code);
    if (id == null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('scanner.invalid_title'.tr()),
          content: Text('scanner.invalid_body'.tr(namedArgs: {'code': code})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('scanner.close'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    // Pausa la cámara antes de navegar
    await controller?.pauseCamera();

    if (!mounted) return;

    // 🔁 Ruta al detalle de la pieza (ajustada a tu router)
    await context.push('/place/$id');

    // Cuando el usuario vuelve atrás, reanudamos la cámara
    await controller?.resumeCamera();
  }

  Future<void> _toggleFlash() async {
    await controller?.toggleFlash();
    try {
      final status = await controller?.getFlashStatus();
      if (mounted && status != null) {
        setState(() => _flashOn = status);
      } else {
        setState(() => _flashOn = !_flashOn);
      }
    } catch (_) {
      setState(() => _flashOn = !_flashOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOut = size.width * 0.72;

    // Parámetros visuales del marco
    const cornerStrokeWidth = 4.0;
    const cornerLength = 28.0;
    const borderRadius = 22.0;
    final overlayOpacity = 0.48;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 📷 Cámara a pantalla completa
          QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),

          /// 🟣 Overlays oscuros + marco central
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                final cutLeft = (width - cutOut) / 2;
                final cutTop = (height - cutOut) / 2;

                return Stack(
                  children: [
                    // Zonas oscuras
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: cutTop,
                      child: Container(
                        color: Colors.black.withOpacity(overlayOpacity),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cutTop,
                      child: Container(
                        color: Colors.black.withOpacity(overlayOpacity),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: cutLeft,
                      top: cutTop,
                      bottom: cutTop,
                      child: Container(
                        color: Colors.black.withOpacity(overlayOpacity),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      width: cutLeft,
                      top: cutTop,
                      bottom: cutTop,
                      child: Container(
                        color: Colors.black.withOpacity(overlayOpacity),
                      ),
                    ),

                    // 🟩 Recuadro central con esquinas “pro” tipo Louvre
                    Positioned(
                      left: cutLeft,
                      top: cutTop,
                      width: cutOut,
                      height: cutOut,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ScannerFramePainter(
                            cornerColor: Colors.white,
                            strokeWidth: cornerStrokeWidth,
                            cornerLength: cornerLength,
                            borderRadius: borderRadius,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          /// 🔹 Barra superior (SIN X) + título traducible + flash
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // ✅ Sin botón X (eliminado a propósito)
                  Text(
                    // Reusa tu key existente para no tocar más JSON:
                    // "tabs.scan": "Escanear QR"
                    'tabs.scan'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Pintor del marco de escaneo (esquinas limpias y profesionales)
class _ScannerFramePainter extends CustomPainter {
  final Color cornerColor;
  final double strokeWidth;
  final double cornerLength;
  final double borderRadius;

  _ScannerFramePainter({
    required this.cornerColor,
    required this.strokeWidth,
    required this.cornerLength,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Para que las esquinas respeten un pequeño radio
    final r = borderRadius;

    // ↖ Esquina superior izquierda
    canvas.drawLine(
      Offset(r, strokeWidth / 2),
      Offset(r + cornerLength, strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(strokeWidth / 2, r),
      Offset(strokeWidth / 2, r + cornerLength),
      paint,
    );

    // ↗ Esquina superior derecha
    canvas.drawLine(
      Offset(w - r - cornerLength, strokeWidth / 2),
      Offset(w - r, strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(w - strokeWidth / 2, r),
      Offset(w - strokeWidth / 2, r + cornerLength),
      paint,
    );

    // ↙ Esquina inferior izquierda
    canvas.drawLine(
      Offset(r, h - strokeWidth / 2),
      Offset(r + cornerLength, h - strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(strokeWidth / 2, h - r - cornerLength),
      Offset(strokeWidth / 2, h - r),
      paint,
    );

    // ↘ Esquina inferior derecha
    canvas.drawLine(
      Offset(w - r - cornerLength, h - strokeWidth / 2),
      Offset(w - r, h - strokeWidth / 2),
      paint,
    );
    canvas.drawLine(
      Offset(w - strokeWidth / 2, h - r - cornerLength),
      Offset(w - strokeWidth / 2, h - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.cornerColor != cornerColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
