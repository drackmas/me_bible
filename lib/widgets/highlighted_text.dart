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

  Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'green':
        return Colors.green.shade200;
      case 'blue':
        return Colors.blue.shade200;
      case 'pink':
        return Colors.pink.shade200;
      case 'orange':
        return Colors.orange.shade200;
      case 'purple':
        return Colors.purple.shade200;
      case 'yellow':
      default:
        return Colors.yellow.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return Text(text, style: style);
    }

    // Simple approach: highlight every occurrence of each phrase
    final spans = <TextSpan>[];
    String remaining = text;
    int currentIndex = 0;

    // We will process the text sequentially
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
        // No more highlights
        spans.add(TextSpan(text: text.substring(currentIndex), style: style));
        break;
      }

      // Add normal text before the highlight
      if (nearestStart > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, nearestStart),
          style: style,
        ));
      }

      // Add the highlighted part
      spans.add(TextSpan(
        text: text.substring(nearestStart, nearestStart + nearestLength),
        style: (style ?? const TextStyle()).copyWith(
          backgroundColor: _colorFromName(nearestHighlight!.color),
          fontWeight: FontWeight.w600,
        ),
      ));

      currentIndex = nearestStart + nearestLength;
    }

    return Text.rich(TextSpan(children: spans));
  }
}
