import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'screen_arguments.dart';
import 'tujuan.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    this.client,
    this.requestTimeout = const Duration(seconds: 15),
  });

  final http.Client? client;
  final Duration requestTimeout;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String title = '', thumbnail = '', shortDescription = '', description = '';
  String genre = '', platform = '', release = '', cover = '', publisher = '';
  String? gameid;
  String? error;
  late final http.Client client = widget.client ?? http.Client();

  Future<void> getGame(String id) async {
    setState(() {
      error = null;
      gameid = null;
    });
    try {
      final response = await client
          .get(Uri.parse('https://www.freetogame.com/api/game?id=$id'))
          .timeout(widget.requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('HTTP ${response.statusCode}');
      }
      final results = jsonDecode(response.body);
      if (results is! Map<String, dynamic> ||
          results['title'] is! String ||
          (results['title'] as String).trim().isEmpty) {
        throw const FormatException('Data game kosong');
      }
      if (!mounted) return;
      String text(String key) =>
          results[key] is String ? results[key] as String : '';
      final screenshots = results['screenshots'];
      setState(() {
        gameid = id;
        title = text('title');
        thumbnail = text('thumbnail');
        shortDescription = text('short_description');
        description = text('description');
        genre = text('genre');
        platform = text('platform');
        publisher = text('publisher');
        release = text('release_date');
        cover =
            screenshots is List &&
                screenshots.isNotEmpty &&
                screenshots.first is Map &&
                screenshots.first['image'] is String
            ? screenshots.first['image'] as String
            : thumbnail;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Gagal memuat game';
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.client == null) client.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getGame('475');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0081c9),
      body: SafeArea(
        child: Center(
          child: error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    ElevatedButton(
                      onPressed: () => getGame('475'),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                )
              : gameid == null
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              if (thumbnail.isNotEmpty)
                                Image.network(
                                  thumbnail,
                                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image),
                                ),
                              const SizedBox(height: 15),
                              Text(title, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 20,
                                runSpacing: 10,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Genre: $genre"),
                                      Text("Platform: $platform"),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Publisher: $publisher"),
                                      Text("Release: $release"),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Tujuan.routeName,
                            arguments: ScreenArguments(
                              cover,
                              title,
                              description,
                              shortDescription,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
