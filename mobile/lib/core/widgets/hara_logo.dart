import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The HARA logo for the top bar, which is black in both themes: the logo's mark (the H with the pin) in its own colours
/// and the name in gold. Together they stay readable at the size of a bar, where the logo's own small lettering is not.
class HaraLogo extends StatelessWidget {
  const HaraLogo({this.height = 32, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => Row(
        key: const Key('appLogo'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Image.asset('assets/logo/mark.png', height: height, filterQuality: FilterQuality.medium),
          ),
          const SizedBox(width: 10),
          Text(
            'HARA',
            style: TextStyle(color: AppTheme.gold, fontSize: height * 0.62, fontWeight: FontWeight.w700, letterSpacing: 3),
          ),
        ],
      );
}
