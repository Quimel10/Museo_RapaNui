import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';

class PlaceSkeleton extends StatelessWidget {
  const PlaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.sandLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
