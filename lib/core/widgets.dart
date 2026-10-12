import 'package:flutter/material.dart';
import 'theme.dart';

/// Minimal design-system widgets.
class YmScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomBar;
  final List<Widget>? actions;
  const YmScaffold(
      {super.key,
      required this.title,
      required this.body,
      this.bottomBar,
      this.actions});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: SafeArea(child: body),
        bottomNavigationBar: bottomBar,
      );
}

class YmCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const YmCard({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
}

class YmField extends StatelessWidget {
  final String hint;
  final TextEditingController? ctrl;
  final int maxLines;
  const YmField({super.key, required this.hint, this.ctrl, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      );
}

class YmChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const YmChip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

class Stars extends StatelessWidget {
  final double v;
  const Stars(this.v, {super.key});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: YmColors.accent),
          const SizedBox(width: 4),
          Text(v.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}

class YmEmpty extends StatelessWidget {
  final String text;
  const YmEmpty(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
}

/// Giant one-tap SOS button.
class SosButton extends StatelessWidget {
  final VoidCallback onTap;
  const SosButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: YmColors.sos,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: YmColors.sos.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 4),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('SOS',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
        ),
      );
}
