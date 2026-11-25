import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const _indigo = Color(0xFF1A237E);
const _success = Color(0xFF256029);
const _error = Color(0xFFB3261E);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    MyApp(titleStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
  );
}

class Post {
  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String title;
  final String body;
  final DateTime createdAt;

  factory Post.fromJson(String source, {DateTime? createdAt}) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic> ||
        json['id'] is! int ||
        json['title'] is! String ||
        json['body'] is! String) {
      throw const FormatException('Respons post tidak valid.');
    }
    return Post(
      id: json['id'] as int,
      userId: json['userId'] is int ? json['userId'] as int : 1,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.client, this.titleStyle, this.fontFamily});

  final http.Client? client;
  final TextStyle? titleStyle;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo CRUD Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: fontFamily,
        colorSchemeSeed: _indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F5FA),
        appBarTheme: AppBarTheme(
          backgroundColor: _indigo,
          foregroundColor: Colors.white,
          titleTextStyle: (titleStyle ?? TextStyle(fontFamily: fontFamily))
              .copyWith(color: Colors.white, fontSize: 20),
        ),
      ),
      home: HomePage(client: client),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.client});

  final http.Client? client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final _posts = Uri.https('jsonplaceholder.typicode.com', '/posts');
  static final _sample = _posts.replace(path: '/posts/1');
  static const _headers = {'Content-Type': 'application/json; charset=UTF-8'};

  late final http.Client _client = widget.client ?? http.Client();
  Post? createdPost;
  bool _busy = false;

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  void _notify(String message, {bool failed = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: failed ? _error : _success,
        ),
      );
  }

  Future<void> _run(
    Future<http.Response> request,
    int successCode,
    String message, {
    bool delete = false,
    DateTime? createdAt,
  }) async {
    setState(() => _busy = true);
    try {
      final response = await request.timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (response.statusCode != successCode) {
        _notify(
          'Permintaan gagal (HTTP ${response.statusCode}).',
          failed: true,
        );
        return;
      }
      final result = delete
          ? null
          : Post.fromJson(
              utf8.decode(response.bodyBytes),
              createdAt: createdAt,
            );
      setState(() => createdPost = result);
      _notify(message);
    } on TimeoutException {
      if (mounted) _notify('Server terlalu lama merespons.', failed: true);
    } on FormatException {
      if (mounted) _notify('Respons post tidak valid.', failed: true);
    } on http.ClientException {
      if (mounted) _notify('Koneksi ke server gagal.', failed: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> readPost() =>
      _run(_client.get(_sample), 200, 'Post contoh berhasil dimuat.');

  Future<void> createPost(String title, String body) => _run(
    _client.post(
      _posts,
      headers: _headers,
      body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
    ),
    201,
    'Post berhasil ditambahkan.',
  );

  Future<void> updatePost(Post post, String title, String body) => _run(
    _client.put(
      _sample,
      headers: _headers,
      body: jsonEncode({
        'id': 1,
        'title': title,
        'body': body,
        'userId': post.userId,
      }),
    ),
    200,
    'Post berhasil diperbarui.',
    createdAt: post.createdAt,
  );

  Future<void> deletePost() => _run(
    _client.delete(_sample),
    200,
    'Post berhasil dihapus.',
    delete: true,
  );

  Future<void> _edit([Post? post]) async {
    final input = await showDialog<({String title, String body})>(
      context: context,
      builder: (_) => _PostDialog(post: post),
    );
    if (!mounted || input == null) return;
    if (post == null) {
      await createPost(input.title, input.body);
    } else {
      await updatePost(post, input.title, input.body);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi hapus'),
        content: const Text('Hapus post dari tampilan praktikum?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: _error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) await deletePost();
  }

  @override
  Widget build(BuildContext context) {
    final post = createdPost;
    return Scaffold(
      appBar: AppBar(title: const Text('Demo CRUD client-server')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah post'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            const Text(
              'JSONPlaceholder menyimulasikan perubahan. Hasil berlaku selama aplikasi berjalan.',
            ),
            const SizedBox(height: 20),
            if (_busy)
              const LinearProgressIndicator(semanticsLabel: 'Memproses post'),
            if (post == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belum ada post',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Baca satu post contoh atau tambah post untuk mencoba CRUD.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _busy ? null : readPost,
                        child: const Text('Baca contoh'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          PopupMenuButton<bool>(
                            tooltip: 'Opsi post',
                            enabled: !_busy,
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: true, child: Text('Update')),
                              PopupMenuItem(
                                value: false,
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (update) =>
                                update ? _edit(post) : _confirmDelete(),
                          ),
                        ],
                      ),
                      Text(post.body),
                      const SizedBox(height: 16),
                      Text('ID respons: ${post.id}'),
                      Text(
                        'Waktu dicatat: ${DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt)}',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostDialog extends StatefulWidget {
  const _PostDialog({this.post});

  final Post? post;

  @override
  State<_PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<_PostDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.post?.title);
  late final _body = TextEditingController(text: widget.post?.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.post == null ? 'Tambah post' : 'Update post'),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Nama'),
              validator: (value) =>
                  value!.trim().isEmpty ? 'Nama wajib diisi' : null,
            ),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Pekerjaan'),
              validator: (value) =>
                  value!.trim().isEmpty ? 'Pekerjaan wajib diisi' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (
                title: _title.text.trim(),
                body: _body.text.trim(),
              ));
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
