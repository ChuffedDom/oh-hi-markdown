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
  String siteName;

  FolderData({
    this.markdownFolderLocation = "",
    this.siteFolderLocation = "",
    this.markdownFiles = const [],
    this.siteName = "",
  });
}

class WebServer {
  HttpServer? _server;

  Future<void> startServer(String directoryPath, {int port = 8060}) async {
    final siteDirectory = Directory(directoryPath);

    if (!siteDirectory.existsSync()) {
      throw Exception('Site directory does not exist: $directoryPath');
    }

    // Start the HTTP server
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('Web server started at http://localhost:$port');

    // Open the browser to the server URL
    openBrowser('http://localhost:$port');

    // Listen for HTTP requests
    _server?.listen((HttpRequest request) async {
      final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
      final file = File('${siteDirectory.path}$path');

      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        request.response
          ..headers.contentType = ContentType.html
          ..add(fileBytes);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('404 Not Found');
      }

      await request.response.close();
    });
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      print('Web server stopped.');
    }
  }

  void openBrowser(String url) {
    try {
      if (Platform.isMacOS) {
        Process.run('open', [url]); // macOS
      } else if (Platform.isWindows) {
        Process.run('start', [url], runInShell: true); // Windows
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [url]); // Linux
      }
    } catch (e) {
      print('Could not open browser: $e');
    }
  }
}

/* STATE */

class FolderProvider with ChangeNotifier {
  FolderData _folderData = FolderData();
  WebServer _webserver = WebServer();
  bool _isServerRunning = false;
  bool _siteIsBuilt = false;
  bool _isBuilding = false;

  FolderData get folderData => _folderData;
  WebServer get webServer => _webserver;
  bool get isServerRunning => _isServerRunning;
  bool get siteIsBuilt => _siteIsBuilt;
  bool get isBuilding => _isBuilding;

  // Updates Below

  void updateFolderData(String newFolderPath) {
    _folderData.markdownFolderLocation = newFolderPath;

    print("Update folder: $newFolderPath");
    print(
        "Current Folder Data markdown Folder: ${_folderData.markdownFolderLocation}");
    loadMarkdownFiles();
    notifyListeners();
  }

  void updateIsServerRunningToggle() {
    if (_isServerRunning) {
      _isServerRunning = false;
    } else {
      _isServerRunning = true;
    }
    notifyListeners();
  }

  void updateSiteIsBuilt() {
    if (_siteIsBuilt) {
      _siteIsBuilt = false;
    } else {
      _siteIsBuilt = true;
    }
  }

  void updateIsBuildingToggle() {
    if (_isBuilding) {
      _isBuilding = false;
    } else {
      _isBuilding = true;
    }
  }

  // Utilities Below

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
    _folderData.siteName = folderName;
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
          <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
          <title>${slug.replaceAll('.html', '')}</title>
        </head>
        <body>
          <a href="/" style="margin-top: 20px;">Home</a>
          $htmlContent
          <a href="/" style="margin-top: 20px;">Home</a>
        </body>
        </html>
        ''',
      );

      print('Created HTML file: $filePath');
    }
  }

  Future<void> createIndexFile(String siteFolderPath) async {
    // Extract the folder name for the title
    final siteFolder = Directory(siteFolderPath);
    final folderName = siteFolder.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .last
        .replaceAll(' site', '');

    // Generate content for each Markdown file
    final List<String> fileSummaries = folderData.markdownFiles.map((file) {
      // Get the filename without .md
      final fileName = file.uri.pathSegments.last.replaceAll('.md', '');
      final slug = fileName.replaceAll(' ', '-').toLowerCase() + '.html';

      // Read the raw Markdown content
      final rawMarkdown = file.readAsStringSync();

      // Convert Markdown to plain text for preview (optional)
      final plainText = md
          .markdownToHtml(rawMarkdown)
          .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
          .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
          .trim();

      // Get the first 200 characters
      final snippet = plainText.length > 200
          ? plainText.substring(0, 200) + '...'
          : plainText;

      return '''
    <h2>${fileName}</h2>
    <p>${snippet}</p>
    <a href="/pages/$slug">Read more</a>
    <br>
    <br>
    <hr>
    ''';
    }).toList();

    // Combine summaries into HTML
    final bodyContent = fileSummaries.join('\n');

    // Path for the index.html file
    final indexFilePath = '${siteFolder.path}/index.html';
    final indexFile = File(indexFilePath);

    // Create or overwrite the index.html file
    indexFile.writeAsStringSync(
      '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
      <title>$folderName</title>
    </head>
    <body>
      <h1>$folderName</h1>
      $bodyContent
    </body>
    </html>
    ''',
    );

    print('Created index.html file: $indexFilePath');
  }
}

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

class SiteCard extends StatelessWidget {
  const SiteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: true);

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).colorScheme.primaryContainer),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(36.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folderProvider.folderData.siteName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            SizedBox(height: 30),
            Align(
              alignment: Alignment.bottomRight,
              child: OutlinedButton(
                onPressed: () async {
                  if (folderProvider.isServerRunning) {
                    await folderProvider.webServer.stopServer();
                    folderProvider.updateIsServerRunningToggle();
                  } else {
                    final siteFolderPath =
                        folderProvider.folderData.siteFolderLocation;
                    if (siteFolderPath.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No site folder to serve.')),
                      );
                      return;
                    }
                    await folderProvider.webServer.startServer(siteFolderPath);
                    folderProvider.updateIsServerRunningToggle();
                  }
                },
                child: Text(
                    folderProvider.isServerRunning ? "Stop Server" : "Preview"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
