import 'package:flutter/material.dart';

class PunchButtons extends StatelessWidget {
  final bool busy;
  final VoidCallback onIn;
  final VoidCallback onOut;
  final String? lastType; // 👈 add this
  const PunchButtons({
    super.key,
    required this.busy,
    required this.onIn,
    required this.onOut,
    this.lastType,
  });

  @override
  Widget build(BuildContext context) {
    final disableIn = lastType == 'IN';
    final disableOut = lastType == 'OUT';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: (busy || disableIn) ? null : onIn,
            icon: const Icon(Icons.login),
            label: const Text('Clock In'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: (busy || disableOut) ? null : onOut,
            icon: const Icon(Icons.logout),
            label: const Text('Clock Out'),
          ),
        ),
      ],
    );
  }
}
