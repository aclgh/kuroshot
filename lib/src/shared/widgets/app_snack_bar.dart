import 'package:flutter/material.dart';

class AppSnackBar extends SnackBar {
  AppSnackBar(
    BuildContext context, {
    super.key,
    required String message,
    IconData? icon,
  }) : super(
         padding: EdgeInsets.zero,
         content: Container(
           padding: const EdgeInsets.all(16),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(
                     icon ?? _guessIcon(message),
                     size: 24,
                     color: Theme.of(context).colorScheme.onInverseSurface,
                   ),
                   const Spacer(),
                   InkWell(
                     onTap: () {
                       ScaffoldMessenger.of(context).hideCurrentSnackBar();
                     },
                     child: Icon(
                       Icons.close,
                       size: 20,
                       color: Theme.of(
                         context,
                       ).colorScheme.onInverseSurface.withValues(alpha: 0.6),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 8),
               Divider(
                 color: Theme.of(
                   context,
                 ).colorScheme.onInverseSurface.withValues(alpha: 0.2),
                 height: 1,
               ),
               const SizedBox(height: 8),
               Text(
                 message,
                 style: TextStyle(
                   color: Theme.of(context).colorScheme.onInverseSurface,
                   fontWeight: FontWeight.w500,
                   fontSize: 14,
                 ),
               ),
             ],
           ),
         ),
         behavior: SnackBarBehavior.floating,
         margin: EdgeInsets.only(
           left: (MediaQuery.of(context).size.width - 300).clamp(
             0.0,
             double.infinity,
           ),
           right: 24,
           bottom: 24,
         ),
         duration: const Duration(milliseconds: 2000),
         backgroundColor: Theme.of(
           context,
         ).colorScheme.inverseSurface.withValues(alpha: 0.85),
         elevation: 0,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: BorderSide(
             color: Theme.of(
               context,
             ).colorScheme.onSurface.withValues(alpha: 0.05),
             width: 1,
           ),
         ),
       );

  static IconData _guessIcon(String message) {
    if (message.contains('错误') || message.contains('失败')) {
      return Icons.error_outline;
    }
    return Icons.info_outline;
  }
}
