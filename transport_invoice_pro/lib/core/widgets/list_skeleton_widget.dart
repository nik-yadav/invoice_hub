import 'package:flutter/material.dart';
import 'skeleton_widget.dart';
import '../theme/app_colors.dart';

class ListSkeletonWidget extends StatelessWidget {
  final int itemCount;

  const ListSkeletonWidget({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonWidget(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const SkeletonWidget(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    SkeletonWidget(width: MediaQuery.of(context).size.width * 0.4, height: 14),
                    const SizedBox(height: 8),
                    const SkeletonWidget(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
