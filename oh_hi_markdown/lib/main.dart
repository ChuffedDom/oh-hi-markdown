import 'package:flutter/material.dart';
import 'package:oh_hi_markdown/markdownToHtml.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FolderProvider()),
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oh Hi Markdown',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Oh Hi Markdown'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderProvider = Provider.of<FolderProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Source Markdown Folder",
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            SizedBox(height: 30),

            FolderSelector(),

            SizedBox(height: 30),
            FilledButton(
              onPressed: () async {
                if (folderProvider.folderData.markdownFiles.isNotEmpty) {
                  final slugs =
                      folderProvider.folderData.markdownFiles.map((file) {
                    final fileName =
                        file.uri.pathSegments.last.replaceAll('.md', '');
                    final sanitized = fileName
                        .replaceAll(RegExp(r'[^a-zA-Z0-9\- ]'),
                            '') // Remove invalid characters
                        .replaceAll(' ', '-') // Replace spaces
                        .toLowerCase(); // Convert to lowercase
                    return '$sanitized.html';
                  }).toList();

                  // Create the new folder
                  final newFolderPath = await folderProvider.createSiteFolder();
                  print('New folder created: $newFolderPath');

                  // Create files for each slug
                  await folderProvider.createSlugFiles(slugs, newFolderPath);

                  print('Generated URLs: $slugs');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generated ${slugs.length} URLs')),
                  );
                } else {
                  print('No markdown files found.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No markdown files to process.')),
                  );
                }
              },
              child: Text("Generate Site"),
            ),
            // State display
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 64),
                Text(
                  "Markdown Folder:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Folder: ${folderProvider.folderData.markdownFolderLocation}",
                ),
                SizedBox(height: 16),
                Text(
                  "Site Folder:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Folder: ${folderProvider.folderData.siteFolderLocation}",
                ),
                SizedBox(height: 16),
                Text(
                  'Markdown Files:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ...folderProvider.folderData.markdownFiles
                    .map((file) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(file.path),
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
