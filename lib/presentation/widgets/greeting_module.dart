import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class GreetingModule extends StatelessWidget {
  final String greetingText;

  const GreetingModule({
    super.key,
    this.greetingText = 'Good morning Uzair\nFocus mode active',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              greetingText,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary,
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
