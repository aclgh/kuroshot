import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/library_controller.dart';

class LibrarySearchBar extends StatefulWidget {
  const LibrarySearchBar({super.key});

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  bool _isSearching = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _focusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _controller.clear();
    });
    context.read<LibraryController>().search('');
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<LibraryController>().search(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSearching) {
      return Container(
        width: 250,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索应用、标题、标签...',
            hintStyle: TextStyle(fontSize: 13, color: colorScheme.outline),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _stopSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            prefixIcon: const Icon(Icons.search, size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: _onSearchChanged,
        ),
      );
    }

    return TextButton.icon(
      onPressed: _startSearch,
      icon: const Icon(Icons.search, size: 20),
      label: const Text("搜索"),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}
