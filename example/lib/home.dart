import 'package:custom_editor/custom_editor.dart';
import 'package:flutter/material.dart';

class EditorHomeScreen extends StatefulWidget {
  const EditorHomeScreen({super.key});

  @override
  State<EditorHomeScreen> createState() => _EditorHomeScreenState();
}

class _EditorHomeScreenState extends State<EditorHomeScreen> {
  final GlobalKey<CustomRichTextEditorState> _editorKey =
      GlobalKey<CustomRichTextEditorState>();

  String _plainText = '';
  final TextEditingController _bodyController = TextEditingController();

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  void _submitDocument() {
    final editor = _editorKey.currentState;

    if (editor == null) return;

    final html = editor.toHtml();
    final json = editor.toJsonString();
    final text = editor.toPlainText();

    debugPrint('HTML: $html');
    debugPrint('JSON: $json');
    debugPrint('TEXT: $text');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document data generated successfully')),
    );
  }

  void _previewDocument() {
    final html = _editorKey.currentState?.toHtml() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HTML Preview'),
        content: SingleChildScrollView(child: SelectableText(html)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Rich Text Editor',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Preview HTML',
            onPressed: _previewDocument,
            icon: const Icon(Icons.visibility_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Document',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B4D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Write and format your document using the editor.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Document Content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          CustomRichTextEditor(
                            controller: _bodyController,
                            onInsertMarkup: (value) {},
                            key: _editorKey,
                            hintText: 'Start writing your document...',
                            minHeight: 450,
                            onChanged: (value) {
                              setState(() {
                                _plainText = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Characters: ${_plainText.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previewDocument,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _submitDocument,
                      icon: const Icon(Icons.check),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
