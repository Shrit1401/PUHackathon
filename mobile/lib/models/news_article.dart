class NewsArticle {
  NewsArticle({
    required this.title,
    required this.source,
    required this.url,
    required this.summary,
    required this.published,
    required this.disasterType,
    required this.query,
  });

  final String title;
  final String source;
  final String url;
  final String summary;
  final String published;
  final String disasterType;
  final String query;

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      title: (map['title'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      published: (map['published'] ?? '').toString(),
      disasterType: (map['disaster_type'] ?? '').toString(),
      query: (map['query'] ?? '').toString(),
    );
  }
}

class NewsResponse {
  NewsResponse({
    required this.articles,
    required this.total,
    required this.scrapedAt,
  });

  final List<NewsArticle> articles;
  final int total;
  final String scrapedAt;

  factory NewsResponse.fromMap(Map<String, dynamic> map) {
    final raw = (map['articles'] as List?) ?? const [];
    return NewsResponse(
      articles: raw
          .map((e) => NewsArticle.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: (map['total'] as num?)?.toInt() ?? raw.length,
      scrapedAt: (map['scraped_at'] ?? '').toString(),
    );
  }
}
