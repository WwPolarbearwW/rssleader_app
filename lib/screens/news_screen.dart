import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:webfeed_plus/domain/rss_feed.dart';
import 'package:webfeed_plus/domain/rss_item.dart';
import 'webview_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<RssItem> _newsItems = [];
  bool _isLoading = true;
  String _selectedRegion = '全てのニュース'; // デフォルトの地域名

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });

    const rssUrl =
        'https://api.allorigins.win/get?url=https://news.yahoo.co.jp/rss/media/gifuweb/all.xml';

    try {
      final response = await http.get(Uri.parse(rssUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['contents'] as String;

        final decodedContent = utf8.decode(content.runes.toList());
        final feed = RssFeed.parse(decodedContent);

        // 選択した地域名に基づいてフィルタリング
        _newsItems = (feed.items ?? []).where((item) {
          return _selectedRegion == '全てのニュース' ||
              (item.title?.toLowerCase().contains(_selectedRegion.toLowerCase()) ?? false) ||
              (item.description?.toLowerCase().contains(_selectedRegion.toLowerCase()) ?? false);
        }).toList();
      } else {
        throw Exception('Failed to load RSS feed');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
    _fetchNews(); // ニュースを再取得
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ニュース'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _updateRegion,
            itemBuilder: (BuildContext context) {
              return {
                '全てのニュース',
                '岐阜市',
                '羽島市',
                '山県市',
                '瑞穂市',
                '羽島郡',
                '本巣郡',
                '大垣市',
                '海津市',
                '養老郡',
                '不破郡',
                '安八郡',
                '揖斐郡',
                '関市',
                '美濃加茂市',
                '可児市',
                '郡上市',
                '加茂郡',
                '可児郡',
                '多治見市',
                '中津川市',
                '瑞浪市',
                '恵那市',
                '土岐市',
                '高山市',
                '飛騨市',
                '下呂市',
                '大野郡',
                'その他の地域', // 追加した地域名
              }.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _newsItems.length,
              itemBuilder: (context, index) {
                final item = _newsItems[index];
                return FutureBuilder<OgpData?>(
                  future: _fetchOgpData(item.link),
                  builder: (context, snapshot) {
                    final ogpData = snapshot.data;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: InkWell(
                        onTap: () => _openArticle(item.link),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                              ),
                              child: ogpData?.image != null
                                  ? Image.network(
                                      ogpData!.image!,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.article,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ogpData?.title ?? item.title ?? 'No title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    ogpData?.description ??
                                        item.pubDate?.toLocal().toString() ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<OgpData?> _fetchOgpData(String? url) async {
    if (url == null) return null;
    try {
      return await OgpDataExtract.execute(url);
    } catch (e) {
      print('Failed to fetch OGP data: $e');
      return null;
    }
  }

  void _openArticle(String? url) {
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: url),
        ),
      );
    }
  }
}
