import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsNumberPicker extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int step;
  final int min;

  const SettingsNumberPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 10,
    this.min = 1,
  });

  @override
  State<SettingsNumberPicker> createState() => _SettingsNumberPickerState();
}

class _SettingsNumberPickerState extends State<SettingsNumberPicker> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value.toString());
  }

  // 当外部 value 改变（比如点加减号）时同步输入框
  @override
  void didUpdateWidget(SettingsNumberPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _textController.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(Icons.remove, () {
            final newValue = widget.value - widget.step;
            widget.onChanged(newValue < widget.min ? widget.min : newValue);
          }),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (v) {
                final val = int.tryParse(v);
                if (val != null) {
                  widget.onChanged(val < widget.min ? widget.min : val);
                }
              },
            ),
          ),
          _buildButton(Icons.add, () {
            widget.onChanged(widget.value + widget.step);
          }),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
    );
  }
}
