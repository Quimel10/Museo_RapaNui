import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset(
        'assets/pdf/antofagasta-mapa-turistico-mobile-small.pdf',
      ),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bluePrimaryDark,
      body: SafeArea(
        child: PdfViewPinch(
          controller: _pdfController,
          scrollDirection: Axis.vertical, // 👈 scroll vertical
        ),
      ),
    );
  }
}
