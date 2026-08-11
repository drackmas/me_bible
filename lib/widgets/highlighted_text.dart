import 'package:flutter/material.dart';
import '../models/commentary.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final List<Highlight> highlights;
  final TextStyle? style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlights,
    this.style,
  });

  Color _colorFromName(String name, {required bool isDark}) {
    switch (name.toLowerCase()) {
      case 'green':
        return isDark ? Colors.green.shade700 : Colors.green.shade200;
      case 'blue':
        return isDark ? Colors.blue.shade700 : Colors.blue.shade200;
      case 'pink':
        return isDark ? Colors.pink.shade700 : Colors.pink.shade200;
      case 'orange':
        return isDark ? Colors.orange.shade700 : Colors.orange.shade200;
      case 'purple':
        return isDark ? Colors.purple.shade700 : Colors.purple.shade200;
      case 'yellow':
      default:
        return isDark ? Colors.yellow.shade800 : Colors.yellow.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return Text(text, style: style);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spans = <TextSpan>[];
    int currentIndex = 0;
    final lowerText = text.toLowerCase();

    while (currentIndex < text.length) {
      int nearestStart = -1;
      Highlight? nearestHighlight;
      int nearestLength = 0;

      for (final h in highlights) {
        final phrase = h.text.toLowerCase();
        if (phrase.isEmpty) continue;

        final idx = lowerText.indexOf(phrase, currentIndex);
        if (idx != -1 && (nearestStart == -1 || idx < nearestStart)) {
          nearestStart = idx;
          nearestHighlight = h;
          nearestLength = h.text.length;
        }
      }

      if (nearestStart == -1) {
        spans.add(TextSpan(text: text.substring(currentIndex), style: style));
        break;
      }

      if (nearestStart > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, nearestStart),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(nearestStart, nearestStart + nearestLength),
        style: (style ?? const TextStyle()).copyWith(
          backgroundColor:
              _colorFromName(nearestHighlight!.color, isDark: isDark),
          fontWeight: FontWeight.w600,
        ),
      ));

      currentIndex = nearestStart + nearestLength;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
