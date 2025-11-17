import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PlaceDetailsSkeleton extends StatelessWidget {
  const PlaceDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.grey.shade300),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + chip simulado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _skeletonBox(width: 180, height: 24),
                      _skeletonBox(width: 80, height: 28, borderRadius: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Descripción simulada
                  _skeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _skeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _skeletonBox(width: 200, height: 16),

                  const SizedBox(height: 24),

                  // Galería simulada
                  _skeletonBox(width: 100, height: 20),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, _) => _skeletonBox(
                        width: 100,
                        height: 80,
                        borderRadius: 12,
                      ),
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

  Widget _skeletonBox({
    double? width,
    double? height,
    double borderRadius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
