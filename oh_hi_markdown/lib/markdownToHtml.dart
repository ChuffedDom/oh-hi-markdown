/* CLASSES */

// All managed folders for Markdown files and HTML
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:markdown/markdown.dart' as md;

class FolderData {
  String markdownFolderLocation;
  String siteFolderLocation;
  List<File> markdownFiles;

  FolderData({
    this.markdownFolderLocation = "",
    this.siteFolderLocation = "",
    this.markdownFiles = const [],
  });
}

/* STATE */

class FolderProvider with ChangeNotifier {
  FolderData _folderData = FolderData();

  FolderData get folderData => _folderData;

  void updateFolderData(String newFolderPath) {
    _folderData.markdownFolderLocation = newFolderPath;

    print("Update folder: $newFolderPath");
    print(
        "Current Folder Data markdown Folder: ${_folderData.markdownFolderLocation}");
    loadMarkdownFiles();
    notifyListeners();
  }

  void loadMarkdownFiles() {
    if (_folderData.markdownFolderLocation.isEmpty) {
      print('No folder selected for markdown files.');
      _folderData.markdownFiles = [];
      return;
    }

    final folderPath = _folderData.markdownFolderLocation;
    final directory = Directory(folderPath);

    if (!directory.existsSync()) {
      print('Markdown folder does not exist.');
      _folderData.markdownFiles = [];
      return;
    }

    final files = directory.listSync().whereType<File>().where((file) {
      return file.path.endsWith('.md');
    }).toList();

    _folderData.markdownFiles = files;
    notifyListeners();
  }

  Future<String> createSiteFolder() async {
    // Get the name of the markdown folder
    final markdownFolder = Directory(_folderData.markdownFolderLocation);
    final folderName = markdownFolder.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .last;

    // Get the Markdown directory and create site string for path
    final newFolderPathForSite = '${markdownFolder.path}/$folderName site';

    // Create the new folder
    final newFolder = Directory(newFolderPathForSite);
    if (!newFolder.existsSync()) {
      newFolder.createSync();
    }

    // Get the Markdown directory and create site string for path
    final newFolderPathForPages =
        '${markdownFolder.path}/$folderName site/pages';

    // Create the new folder
    final newFolderPages = Directory(newFolderPathForPages);
    if (!newFolderPages.existsSync()) {
      newFolderPages.createSync();
    }

    _folderData.siteFolderLocation = newFolderPathForSite;
    notifyListeners();

    return newFolderPathForSite;
  }

  Future<void> createSlugFiles(
      List<String> slugs, String siteFolderPath) async {
    final pagesDirectory = Directory('$siteFolderPath/pages');
    if (!pagesDirectory.existsSync()) {
      print('Pages directory does not exist.');
      return;
    }

    for (int i = 0; i < slugs.length; i++) {
      final slug = slugs[i];
      final markdownFile = _folderData.markdownFiles[i];

      // Read the raw content of the Markdown file
      final rawMarkdown = markdownFile.readAsStringSync();

      // Convert Markdown to HTML
      final htmlContent = md.markdownToHtml(rawMarkdown);

      // Create the HTML file
      final filePath = '${pagesDirectory.path}/$slug';
      final file = File(filePath);

      if (!file.existsSync()) {
        file.createSync();
      }

      // Write the HTML content to the file
      file.writeAsStringSync(
        '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>${slug.replaceAll('.html', '')}</title>
          <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
        </head>
        <body>
          $htmlContent
        </body>
        </html>
        ''',
      );

      print('Created HTML file: $filePath');
    }
  }
}

/* FORM DATA */
/* COMPONENTS */

class FolderSelector extends StatelessWidget {
  const FolderSelector({super.key});

  Future<Directory> getRootDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: true);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TextField(
            controller: TextEditingController(
                text: folderProvider.folderData.markdownFolderLocation),
            onChanged: (newValue) {
              folderProvider.updateFolderData(newValue);
            },
            decoration: InputDecoration(
              labelText: 'Folder Location',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(width: 24),
        IconButton(
            onPressed: () async {
              // Open the directory picker
              final String? directoryPath = await getDirectoryPath(
                initialDirectory:
                    await getRootDirectory().then((dir) => dir.path),
                confirmButtonText: 'Select Folder',
              );

              if (directoryPath != null) {
                folderProvider.updateFolderData(directoryPath);
                print('Selected Directory: $directoryPath');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: $directoryPath')),
                );
              } else {
                print('No directory selected.');
              }
            },
            icon: Icon(Icons.folder_open_outlined))
      ],
    );
  }
}
