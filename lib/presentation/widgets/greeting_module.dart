import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }
}
