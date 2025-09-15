import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final String verificationStatus;
  final double? size;
  final bool showText;

  const VerificationBadge({
    Key? key,
    required this.verificationStatus,
    this.size,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (verificationStatus != 'verified') {
      return const SizedBox.shrink();
    }

    final badgeSize = size ?? 16.0;
    final textSize = badgeSize * 0.6;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize * 0.5,
        vertical: badgeSize * 0.25,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF48bb78),
        borderRadius: BorderRadius.circular(badgeSize * 0.75),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: Colors.white,
            size: badgeSize * 0.875,
          ),
          if (showText) ...[
            SizedBox(width: badgeSize * 0.25),
            Text(
              'VERIFIED',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserNameWithVerification extends StatelessWidget {
  final String name;
  final String verificationStatus;
  final TextStyle? nameStyle;
  final double? badgeSize;
  final bool showBadgeText;

  const UserNameWithVerification({
    Key? key,
    required this.name,
    required this.verificationStatus,
    this.nameStyle,
    this.badgeSize,
    this.showBadgeText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: nameStyle,
        ),
        if (verificationStatus == 'verified') ...[
          const SizedBox(width: 8),
          VerificationBadge(
            verificationStatus: verificationStatus,
            size: badgeSize,
            showText: showBadgeText,
          ),
        ],
      ],
    );
  }
}
