# Html Text Editor

A customizable rich text editor for Flutter applications with powerful formatting tools, document editing capabilities, and flexible toolbar customization.

## Features

- Rich text formatting
- Bold, italic, underline, and strikethrough
- Text alignment
- Numbered and bullet lists
- Paragraph formatting
- Font size selection
- Text color and highlighting
- Link conversion
- Image insertion
- Shape insertion
- Table support
- HTML conversion
- JSON conversion
- Document change callbacks
- Customizable toolbar
- Custom editor height
- Custom border and selected tab colors

## Demo

Add your short MP4 demo video here.

## Installation

```bash
flutter pub add html_text_editor
```

## Usage

Import the package:

```dart
import 'package:html_text_editor/html_text_editor.dart';;
```

### Basic Example

```dart
 final GlobalKey<CustomRichTextEditorState> _editorKey =
      GlobalKey<CustomRichTextEditorState>();
       String _plainText = '';
  final TextEditingController _bodyController = TextEditingController();

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
)
```

### Parameters

| Parameter | Type | Default |
|---|---|---|
| `controller` | `TextEditingController` | Required |
| `onInsertMarkup` | `void Function(String)` | Required |
| `initialText` | `String` | `''` |
| `hintText` | `String` | `'Write something...'` |
| `minHeight` | `double` | `300` |
| `onChanged` | `void Function(String)?` | `null` |
| `onDocumentChanged` | `void Function(List<EditorBlock>)?` | `null` |
| `isBold` | `bool` | `true` |
| `isItalic` | `bool` | `true` |
| `isUnderLine` | `bool` | `true` |
| `isStrikeThrough` | `bool` | `true` |
| `isParagraph` | `bool` | `true` |
| `numbericPoint` | `bool` | `true` |
| `bulletPoint` | `bool` | `true` |
| `isAlighnment` | `bool` | `true` |
| `isLinkConvert` | `bool` | `true` |
| `isImage` | `bool` | `true` |
| `isShape` | `bool` | `true` |
| `isTable` | `bool` | `true` |
| `isSelectFontSize` | `bool` | `true` |
| `textColor` | `bool` | `true` |
| `heighlight` | `bool` | `true` |
| `borderColor` | `Color?` | `null` |
| `selectedTabColor` | `Color?` | `null` |

All formatting options are enabled by default and can be disabled individually.

## Example

See the [example](example) directory for a complete implementation.


## License

MIT License
