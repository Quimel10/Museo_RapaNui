import 'dart:io';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🔐 Pega tu API key gratis de MapTiler (o cambia la URL por tu proveedor).
/// Crea la key en https://cloud.maptiler.com/ (plan free suficiente para vista previa)
String _mapTilerKey = Environment.maptilerKey;

class PlaceMapCard extends StatelessWidget {
  final double lat;
  final double lng;
  final String title;

  const PlaceMapCard({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
  });

  /// URL de tiles de un proveedor apto para producción (gratis con key).
  /// Importante: sin subdominios {s} y con attribution visible.
  String get _tilesUrl =>
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$_mapTilerKey';

  LatLng get point => LatLng(lat, lng);

  Future<void> _openExternalMaps() async {
    final label = Uri.encodeComponent(title);

    // 1) Android → intento con geo: (abre Google Maps / app por defecto)
    if (Platform.isAndroid) {
      final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 2) iOS → Apple Maps
    if (Platform.isIOS) {
      final apple = Uri.parse('http://maps.apple.com/?ll=$lat,$lng&q=$label');
      if (await canLaunchUrl(apple)) {
        await launchUrl(apple, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // 3) Fallback universal → Google Maps web
    final gmaps = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(gmaps, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            // 🔎 Vista previa del mapa (sin interacción)
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _tilesUrl, // ✅ proveedor con key
                  subdomains: const [], // ✅ sin {s}
                  userAgentPackageName:
                      'cl.looksgood.disfruta_antofagasta', // ⚠️ ajusta a tu paquete
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on, size: 40),
                    ),
                  ],
                ),
              ],
            ),

            // © Atribución requerida (OSM + proveedor)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '© OpenStreetMap • MapTiler',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // 🖱️ Overlay para abrir Maps al tocar
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.black12,
                  onTap: _openExternalMaps,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
