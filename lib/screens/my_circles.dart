import 'package:flutter/material.dart';

class MyCircles extends StatefulWidget {
  const MyCircles({super.key});

  @override
  State<MyCircles> createState() => _MyCirclesState();
}

class _MyCirclesState extends State<MyCircles> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meine Kreise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.add))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 0.0),
        child: Column(
          children: [
            // Searchbar
            SearchBar(
              controller: _searchController,
              hintText: 'Kreise suchen...',
              elevation: const WidgetStatePropertyAll(0),

              // textcolor - height - Border
              textStyle: WidgetStatePropertyAll(
                TextStyle(color: Theme.of(context).colorScheme.outline),
              ),

              constraints: const BoxConstraints(
                minHeight: 44.0,
                maxHeight: 44.0,
              ),

              side: WidgetStatePropertyAll(
                BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.0,
                ),
              ),

              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(64.0),
                ),
              ),

              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),

              // searching & icon
              onChanged: null,
              leading: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),

            const SizedBox(height: 32.0),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Meine Favoriten',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
