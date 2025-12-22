import 'package:flutter/material.dart';

class SettingsGroup extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  State<SettingsGroup> createState() => _SettingsGroupState();
}

class _SettingsGroupState extends State<SettingsGroup>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween = CurveTween(
    curve: Curves.easeIn,
  );
  static final Animatable<double> _halfTween = Tween<double>(
    begin: 0.0,
    end: 0.5,
  );

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _handleTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 24, color: colorScheme.onSurface),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _iconTurns,
                      child: const Icon(Icons.expand_more),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller.view,
            child: Column(children: widget.children),
            builder: (BuildContext context, Widget? child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
