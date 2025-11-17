import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryChipsList extends StatelessWidget {
  const CategoryChipsList({
    super.key,
    required this.items,
    this.selectedId,
    required this.onChanged,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
    this.separation = 8,
  });

  final List<CategoryEntity> items;
  final int? selectedId;
  final void Function(CategoryEntity tapped) onChanged;
  final double height;
  final EdgeInsets padding;
  final double separation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: separation),
        itemBuilder: (context, i) {
          final cat = items[i];
          final c = const Color(0xFF1C9FE2);
          final selected = cat.id == selectedId;
          const target = Color(0xFF21527D); // == Color.fromRGBO(33, 82, 125, 1)
          return Material(
            color: selected ? c.withAlpha(100) : AppColors.sandLight,
            shape: StadiumBorder(
              side: BorderSide(
                color: (c == target) ? AppColors.bluePrimaryLight : c,
                width: 1.4,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(cat),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CategoryIcon(url: cat.icono, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      cat.name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.sandLight : c,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.url, this.size = 18});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url ?? '',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) =>
            const Icon(Icons.image_not_supported, size: 16),
      ),
    );
  }
}
