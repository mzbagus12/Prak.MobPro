import 'package:flutter/material.dart';

import 'package:game_app/model/game.dart';
import 'package:game_app/viewmodel/fetchgame.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Game>> gameList;
  String query = '';

  void retry() => setState(() { gameList = fetchGames(); });

  Widget recovery(String text) => Column(children: [
    Text(text),
    TextButton(onPressed: retry, child: const Text('Coba lagi')),
  ]);

  @override
  void initState() {
    super.initState();
    gameList = fetchGames();
  }

  void openGame(Game game) {
    Navigator.pushNamed(context, '/detail', arguments: game.id);
  }

  TextField _searchBar() {
    return TextField(
      onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
      cursorColor: Colors.blue,
      decoration: InputDecoration(
        fillColor: Colors.blue.shade50,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 0,
          horizontal: 20,
        ),
        prefixIcon: const Icon(
          Icons.search_outlined,
          color: Colors.blue,
          size: 30,
        ),
        hintText: 'Cari game',
        hintStyle:
            const TextStyle(fontSize: 14, color: Color(0xFF616161)),
      ),
    );
  }

  Card _listItem(Game game) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => openGame(game),
        tileColor: Colors.blue.shade50,
        leading: SizedBox(
          width: 75,
          height: 75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              game.thumbnail,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined),
              scale: 3,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(game.title),
        subtitle: Text(game.genre),
        trailing: const Icon(Icons.more_vert),
        isThreeLine: false,
        titleAlignment: ListTileTitleAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent.shade400,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              _searchBar(),
              const SizedBox(
                height: 10,
              ),
              FutureBuilder<List<Game>>(
                future: gameList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return recovery('Gagal memuat game');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return recovery('Tidak ada data game.');
                  } else {
                    final games = snapshot.data!.where((game) => game.title.toLowerCase().contains(query)).take(25).toList();
                    if (games.isEmpty) return const Text('Game tidak ditemukan.');

                    return Expanded(
                      child: ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return _listItem(game);
                        },
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}