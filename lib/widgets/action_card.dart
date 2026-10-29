

import 'package:attendo/widgets/app_color.dart';
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  const ActionCard ({
      super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColor.accentGlow,
        highlightColor: AppColor.accentGlow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              // ignore: deprecated_member_use
              color: AppColor.accent.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: AppColor.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: AppColor.accentLight, size: 26),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColor.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColor.accentLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}