// lib/features/qr/presentation/screens/qr_scanner_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/config/router/routes.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  /// ✅ Permite "reactivar" el scanner desde el BottomNav
  static final ValueNotifier<int> _ping = ValueNotifier<int>(0);
  static void ping() => _ping.value++;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? controller;
  StreamSubscription<Barcode>? _scanSub;

  bool _flashOn = false;

  bool _handlingScan = false;
  bool _dialogOpen = false;

  String? _lastRaw;
  DateTime? _lastScanAt;

  // ✅ Debounce real para evitar initCamera called twice
  bool _cameraOpBusy = false;
  DateTime? _lastResumeAt;
  DateTime? _lastPauseAt;

  // ✅ SOLO URLs del museo (ajusta si usas más dominios)
  static const Set<String> _allowedHosts = {'sitio1.unbcorp.cl'};

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
      validateStatus: (code) => code != null && code >= 200 && code < 500,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Re-activar scanner cuando el usuario re-selecciona el tab
    QrScannerScreen._ping.addListener(_onPing);
  }

  void _onPing() {
    if (!mounted) return;

    // si hay dialog abierto, no molestamos
    if (_dialogOpen) return;

    // reactivar cámara y resetear anti-spam
    _resetScanMemory();
    _safeResume(reason: 'bottom_nav_ping');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    QrScannerScreen._ping.removeListener(_onPing);

    _scanSub?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload
    if (Platform.isAndroid) {
      _safePause(reason: 'reassemble_android');
    }
    _safeResume(reason: 'reassemble');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _safeResume(reason: 'app_resumed');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _safePause(reason: 'app_paused');
    }
  }

  // ✅ Detecta si el tab/pantalla realmente está visible
  bool _isScannerVisible() {
    final tickerEnabled = TickerMode.of(context);
    if (!tickerEnabled) return false;

    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent == false) return false;

    return true;
  }

  Future<void> _safeResume({required String reason}) async {
    if (!mounted) return;
    if (!_isScannerVisible()) return;
    if (_dialogOpen) return;
    if (controller == null) return;

    final now = DateTime.now();
    if (_lastResumeAt != null &&
        now.difference(_lastResumeAt!).inMilliseconds < 700) {
      return;
    }
    _lastResumeAt = now;

    if (_cameraOpBusy) return;
    _cameraOpBusy = true;

    try {
      await Future.delayed(const Duration(milliseconds: 80));
      await controller?.resumeCamera();
    } catch (_) {
      // ignore
    } finally {
      _cameraOpBusy = false;
    }
  }

  Future<void> _safePause({required String reason}) async {
    if (!mounted) return;
    if (controller == null) return;

    final now = DateTime.now();
    if (_lastPauseAt != null &&
        now.difference(_lastPauseAt!).inMilliseconds < 400) {
      return;
    }
    _lastPauseAt = now;

    if (_cameraOpBusy) return;
    _cameraOpBusy = true;

    try {
      await controller?.pauseCamera();
    } catch (_) {
      // ignore
    } finally {
      _cameraOpBusy = false;
    }
  }

  void _onQRViewCreated(QRViewController c) async {
    controller = c;

    // Suscripción única
    await _scanSub?.cancel();
    _scanSub = c.scannedDataStream.listen((scanData) async {
      if (!mounted) return;
      if (!_isScannerVisible()) return;
      if (_dialogOpen) return;

      final raw = scanData.code?.trim();
      if (raw == null || raw.isEmpty) return;

      // anti-multiple reads
      final now = DateTime.now();
      if (_lastRaw == raw &&
          _lastScanAt != null &&
          now.difference(_lastScanAt!).inMilliseconds < 900) {
        return;
      }
      _lastRaw = raw;
      _lastScanAt = now;

      if (_handlingScan) return;
      _handlingScan = true;

      try {
        await _handleScan(raw);
      } finally {
        _handlingScan = false;
      }
    });

    // Estado flash
    try {
      final status = await c.getFlashStatus();
      if (mounted && status != null) setState(() => _flashOn = status);
    } catch (_) {}

    _safeResume(reason: 'onCreated');
  }

  String _getPuntoPath() {
    final base = Environment.apiUrl.toLowerCase();
    if (base.contains('/wp-json/app/v1')) return '/get_punto';
    if (base.contains('/wp-json/')) return '/app/v1/get_punto';
    return '/wp-json/app/v1/get_punto';
  }

  Future<_PreflightResult> _preflightPlace(int id) async {
    final lang = context.locale.languageCode;

    try {
      final res = await _dio.get(
        _getPuntoPath(),
        queryParameters: {'post_id': id, 'lang': lang},
      );

      if (res.statusCode == 200) return _PreflightResult.ok;

      final data = res.data;
      if (res.statusCode == 404 &&
          data is Map &&
          data['code'] == 'not_translated') {
        return _PreflightResult.notTranslated;
      }

      return _PreflightResult.notFound;
    } catch (_) {
      return _PreflightResult.networkError;
    }
  }

  Future<void> _handleScan(String raw) async {
    await _safePause(reason: 'scan_detected');

    final id = _extractMuseumNumericId(raw);

    if (id == null) {
      await _showInvalidQrDialog();
      if (!mounted) return;

      _resetScanMemory();
      await _safeResume(reason: 'invalid_keep_scanning');
      return;
    }

    final pre = await _preflightPlace(id);
    if (!mounted) return;

    if (pre == _PreflightResult.ok) {
      await context.push('/place/$id');
      if (!mounted) return;

      _resetScanMemory();
      await _safeResume(reason: 'after_place_return');
      return;
    }

    if (pre == _PreflightResult.notTranslated) {
      await _showNotTranslatedDialog();
      if (!mounted) return;

      _resetScanMemory();
      await _safeResume(reason: 'not_translated_keep_scanning');
      return;
    }

    if (pre == _PreflightResult.networkError) {
      final retry = await _showNetworkDialog();
      if (!mounted) return;

      if (!retry) {
        _resetScanMemory();
        await _safeResume(reason: 'network_cancel_keep_scanning');
        return;
      }

      final pre2 = await _preflightPlace(id);
      if (!mounted) return;

      if (pre2 == _PreflightResult.ok) {
        await context.push('/place/$id');
        if (!mounted) return;
        _resetScanMemory();
        await _safeResume(reason: 'after_place_return_retry');
      } else if (pre2 == _PreflightResult.notTranslated) {
        await _showNotTranslatedDialog();
        if (!mounted) return;
        _resetScanMemory();
        await _safeResume(reason: 'not_translated_after_retry');
      } else {
        await _showNotFoundDialog();
        if (!mounted) return;
        _resetScanMemory();
        await _safeResume(reason: 'retry_failed_keep_scanning');
      }
      return;
    }

    await _showNotFoundDialog();
    if (!mounted) return;

    _resetScanMemory();
    await _safeResume(reason: 'not_found_keep_scanning');
  }

  void _resetScanMemory() {
    _lastRaw = null;
    _lastScanAt = null;
  }

  // ✅ NUEVO: Cerrar modal + ir a Inicio (y evitar cámara zombie)
  void _closeDialogAndGoHome(BuildContext dialogContext) {
    // 1) cerrar el diálogo
    Navigator.of(dialogContext).pop();

    // 2) en el siguiente frame: pausar cámara + ir a inicio
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _safePause(reason: 'dialog_close_go_home');
      if (!mounted) return;
      context.go(AppPath.home);
    });
  }

  int? _extractMuseumNumericId(String raw) {
    final trimmed = raw.trim();

    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;

    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.scheme == 'museorapanui') {
      final qp = uri.queryParameters;
      for (final key in ['id', 'post_id', 'p', 'piece_id', 'place_id']) {
        final v = int.tryParse(qp[key] ?? '');
        if (v != null) return v;
      }
      for (int i = uri.pathSegments.length - 1; i >= 0; i--) {
        final v = int.tryParse(uri.pathSegments[i]);
        if (v != null) return v;
      }
    }

    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.toLowerCase();
      final allowed = _allowedHosts.any(
        (h) => host == h || host.endsWith('.$h'),
      );

      if (!allowed) {
        final lower = trimmed.toLowerCase();
        final looksMuseum =
            lower.contains('rapanui') ||
            lower.contains('museo') ||
            lower.contains('get_punto') ||
            lower.contains('ant_q');
        if (!looksMuseum) return null;
      }

      final qp = uri.queryParameters;
      for (final key in ['id', 'post_id', 'p', 'piece_id', 'place_id']) {
        final v = int.tryParse(qp[key] ?? '');
        if (v != null) return v;
      }

      for (int i = uri.pathSegments.length - 1; i >= 0; i--) {
        final v = int.tryParse(uri.pathSegments[i]);
        if (v != null) return v;
      }
    }

    final match = RegExp(r'(\d{2,})').firstMatch(trimmed);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  Future<void> _showInvalidQrDialog() async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => _baseDialog(
        dialogContext,
        title: 'scanner.invalid_title'.tr(),
        body: 'scanner.invalid_body'.tr(),
        leftText: 'scanner.scan_again'.tr(),
        rightText: 'scanner.close'.tr(),
        onLeft: () => Navigator.of(dialogContext).pop(),
        onRight: () => _closeDialogAndGoHome(dialogContext), // ✅ CAMBIO
      ),
    );
    _dialogOpen = false;
  }

  Future<void> _showNotTranslatedDialog() async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => _baseDialog(
        dialogContext,
        title: 'scanner.not_translated_title'.tr(),
        body: 'scanner.not_translated_body'.tr(),
        leftText: 'scanner.scan_again'.tr(),
        rightText: 'scanner.close'.tr(),
        onLeft: () => Navigator.of(dialogContext).pop(),
        onRight: () => _closeDialogAndGoHome(dialogContext), // ✅ CAMBIO
      ),
    );
    _dialogOpen = false;
  }

  Future<bool> _showNetworkDialog() async {
    _dialogOpen = true;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => _baseDialog(
        dialogContext,
        title: 'scanner.network_title'.tr(),
        body: 'scanner.network_body'.tr(),
        leftText: 'scanner.scan_again'.tr(),
        rightText: 'scanner.retry'.tr(),
        onLeft: () => Navigator.of(dialogContext).pop(false),
        onRight: () => Navigator.of(dialogContext).pop(true),
      ),
    );

    _dialogOpen = false;
    return res ?? false;
  }

  Future<void> _showNotFoundDialog() async {
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => _baseDialog(
        dialogContext,
        title: 'scanner.not_found_title'.tr(),
        body: 'scanner.not_found_body'.tr(),
        leftText: 'scanner.scan_again'.tr(),
        rightText: 'scanner.close'.tr(),
        onLeft: () => Navigator.of(dialogContext).pop(),
        onRight: () => _closeDialogAndGoHome(dialogContext), // ✅ CAMBIO
      ),
    );
    _dialogOpen = false;
  }

  Widget _baseDialog(
    BuildContext dialogContext, {
    required String title,
    required String body,
    required String leftText,
    required String rightText,
    required VoidCallback onLeft,
    required VoidCallback onRight,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.white.withOpacity(0.25)),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onLeft,
                    child: Text(
                      leftText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: onRight,
                    child: Text(
                      rightText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (!_isScannerVisible()) return;
    if (controller == null) return;

    try {
      await controller?.toggleFlash();
      final status = await controller?.getFlashStatus();
      if (mounted && status != null) setState(() => _flashOn = status);
    } catch (_) {
      setState(() => _flashOn = !_flashOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _isScannerVisible();

    // ✅ No hagas async directo en build: post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (active) {
        _safeResume(reason: 'post_frame_active');
      } else {
        _safePause(reason: 'post_frame_inactive');
      }
    });

    final size = MediaQuery.of(context).size;
    final cutOut = size.width * 0.72;

    return WillPopScope(
      onWillPop: () async {
        _safePause(reason: 'back_pressed');
        if (mounted) context.go(AppPath.home);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),

            // Overlay simple
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),
            ),
            Center(
              child: Container(
                width: cutOut,
                height: cutOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.transparent,
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
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
      ),
    );
  }
}

enum _PreflightResult { ok, notTranslated, notFound, networkError }
