import 'package:flutter/material.dart';

class InsertLinkDialog extends StatefulWidget {
  const InsertLinkDialog({super.key});

  @override
  State<InsertLinkDialog> createState() => InsertLinkDialogState();
}

class InsertLinkDialogState extends State<InsertLinkDialog> {
  final TextEditingController urlController = TextEditingController();

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Link'),
      content: TextField(
        controller: urlController,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(hintText: 'https://example.com'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, urlController.text.trim());
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}
