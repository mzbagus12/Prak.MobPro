import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:game_app/model/detailgame.dart';
import 'package:game_app/viewmodel/fetchgame.dart';

class Detail extends StatefulWidget {
  final int gameTerpilih;
  const Detail({super.key, required this.gameTerpilih});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  late Future<DetailGame> game;

  Future<DetailGame> fetchData() async =>
      DetailGame.fromJson(await fetchDataFromAPI(widget.gameTerpilih));

  @override
  void initState() {
    super.initState();
    game = fetchData();
  }

  @override
  void didUpdateWidget(covariant Detail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameTerpilih != widget.gameTerpilih) game = fetchData();
  }

  Widget requirement(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: Text(title)),
      const Text(':  '),
      Expanded(flex: 8, child: Text(value)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.amberAccent.shade400,
    appBar: AppBar(title: const Text('Detail game')),
    body: FutureBuilder<DetailGame>(
      future: game,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Gagal memuat detail game'),
            TextButton(onPressed: () => setState(() { game = fetchData(); }), child: const Text('Coba lagi')),
          ]));
        }
        final data = snapshot.data!;
        final requirements = data.minimumSystemRequirements;
        return SingleChildScrollView(
          key: const Key('detail-scroll'),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
              child: Image.network(data.thumbnail, height: 250, fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, error, stack) => const SizedBox(height: 120, child: Icon(Icons.broken_image_outlined))),
            ),
            Padding(padding: const EdgeInsets.all(10), child: Text(data.title, style: Theme.of(context).textTheme.titleLarge)),
            Container(
              margin: const EdgeInsets.all(10), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Minimum System Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
                if (requirements == null) const Text('Tidak tersedia') else ...[
                  requirement('OS', requirements.os),
                  requirement('Processor', requirements.processor),
                  requirement('Memory', requirements.memory),
                  requirement('Graphics', requirements.graphics),
                  requirement('Storage', requirements.storage),
                ],
              ]),
            ),
            if (data.screenshots.isEmpty)
              const Padding(padding: EdgeInsets.all(10), child: Text('Screenshot tidak tersedia'))
            else SizedBox(height: 180, child: ListView.separated(
              padding: const EdgeInsets.all(10), scrollDirection: Axis.horizontal,
              itemCount: data.screenshots.length,
              separatorBuilder: (_, index) => const SizedBox(width: 15),
              itemBuilder: (_, index) => ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(data.screenshots[index].image, width: 250, fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  errorBuilder: (_, error, stack) => const SizedBox(width: 250, child: Icon(Icons.broken_image_outlined))),
              ),
            )),
            Padding(padding: const EdgeInsets.all(10), child: ReadMoreText(
              data.description, trimLines: 2, trimMode: TrimMode.Line,
              colorClickableText: Colors.blue.shade900,
              trimCollapsedText: 'more', trimExpandedText: 'less',
              style: const TextStyle(color: Colors.black87, height: 1.5),
            )),
          ]),
        );
      },
    ),
  );
}
