import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class WatchAnimeWorldClient extends MProvider {
  WatchAnimeWorldClient({required this.source});

  final MSource source;

  @override
  String get name => "WatchAnimeWorld";

  @override
  String get lang => "en";

  @override
  String get baseUrl => "https://watchanimeworld.in";

  @override
  bool get supportsLatest => true;

  @override
  String get id => "watchanimeworld";

  @override
  String get version => "8.0.7"; // Updated version with better season support

  String _buildUrl(String path) {
    if (path.startsWith("http")) return path;
    if (path.startsWith("//")) return "https:$path";
    return baseUrl + (path.startsWith("/") ? path : "/$path");
  }

  String _cleanText(String text, [int maxLength = 1000]) {
    if (text.isEmpty) return "";
    text = text.replaceAll(RegExp(r'<[^>]+>'), '')
               .replaceAll(RegExp(r'\s{2,}'), ' ')
               .trim();
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  Future<MPages> _parseAnimeList(String body) async {
    final mangaList = <MManga>[];
    
    final items = RegExp(
      r'<li\b[^>]*class="[^"]*post-\d+[^"]*"[^>]*>(.*?)</li>',
      dotAll: true,
    ).allMatches(body);
    
    for (final item in items) {
      final itemHtml = item.group(0) ?? "";
      if (itemHtml.isEmpty) continue;

      String title = "Unknown";
      final titleMatch = RegExp(r'<h2[^>]*>(.*?)</h2>').firstMatch(itemHtml);
      if (titleMatch != null) {
        title = _cleanText(titleMatch.group(1) ?? "Unknown", 80);
      }

      String link = "";
      final linkMatch = RegExp(r'<a\s[^>]*href="([^"]+)"[^>]*class="[^"]*lnk-blk\b').firstMatch(itemHtml);
      if (linkMatch != null && linkMatch.group(1) != null) {
        link = linkMatch.group(1)!;
        if (!link.contains("/series/")) continue;
      } else {
        continue;
      }

      String imageUrl = "";
      final imageMatch = RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(itemHtml);
      if (imageMatch != null && imageMatch.group(1) != null) {
        imageUrl = imageMatch.group(1)!;
        if (!imageUrl.startsWith("http")) {
          imageUrl = _buildUrl(imageUrl);
        }
      }
      
      if (imageUrl.isEmpty) {
        imageUrl = "https://placehold.co/200x300/000000/FFFFFF?text=No+Image";
      }

      mangaList.add(MManga(
        name: title,
        link: _buildUrl(link),
        imageUrl: imageUrl,
      ));
    }
    
    return MPages(mangaList, mangaList.isNotEmpty);
  }

  Future<Response> _safeGet(String url) async {
    final client = Client();
    try {
      return await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        }
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<MPages> getPopular(int page) async {
    try {
      final res = await _safeGet("$baseUrl/series/page/$page/");
      return _parseAnimeList(res.body);
    } catch (e) {
      return MPages([], false);
    }
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    try {
      final res = await _safeGet("$baseUrl/latest/page/$page/");
      return _parseAnimeList(res.body);
    } catch (e) {
      return MPages([], false);
    }
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final res = await _safeGet("$baseUrl/search/$encodedQuery/page/$page/");
      final body = res.body;
      final mangaList = <MManga>[];
      final items = RegExp(
        r'<li[^>]*class="[^"]*(series|movies)[^"]*"[^>]*>(.*?)</li>',
        dotAll: true,
      ).allMatches(body);
      for (final item in items) {
        final itemHtml = item.group(0) ?? "";
        if (itemHtml.isEmpty) continue;
        String title = "Unknown";
        final titleMatch = RegExp(r'<h2[^>]*class="entry-title"[^>]*>(.*?)</h2>').firstMatch(itemHtml);
        if (titleMatch != null) {
          title = _cleanText(titleMatch.group(1) ?? "Unknown", 80);
        }
        String link = "";
        final linkMatch = RegExp(r'<a[^>]*href="([^"]+)"[^>]*class="lnk-blk"').firstMatch(itemHtml);
        if (linkMatch != null && linkMatch.group(1) != null) {
          link = linkMatch.group(1)!;
        } else {
          continue;
        }
        String imageUrl = "";
        final imageMatch = RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(itemHtml);
        if (imageMatch != null && imageMatch.group(1) != null) {
          imageUrl = imageMatch.group(1)!;
          if (!imageUrl.startsWith("http")) {
            imageUrl = _buildUrl(imageUrl);
          }
        }
        if (imageUrl.isEmpty) {
          imageUrl = "https://placehold.co/200x300/000000/FFFFFF?text=No+Image";
        }
        mangaList.add(MManga(
          name: title,
          link: link,
          imageUrl: imageUrl,
        ));
      }
      // Fallback: If no results, try direct /series/ and /category/franchise/ URLs
      if (mangaList.isEmpty && page == 1) {
        final fallbackSlugs = [query.toLowerCase().replaceAll(" ", "-"), query.toLowerCase().replaceAll(" ", "")];
        for (final slug in fallbackSlugs) {
          final directUrls = [
            "$baseUrl/series/$slug/",
            "$baseUrl/category/franchise/$slug/"
          ];
          for (final url in directUrls) {
            try {
              final detailRes = await _safeGet(url);
              if (detailRes.statusCode == 200) {
                // Try to extract title and image
                String title = slug;
                final titleMatch = RegExp(r'<h1[^>]*>(.*?)</h1>').firstMatch(detailRes.body);
                if (titleMatch != null && titleMatch.group(1) != null) {
                  title = _cleanText(titleMatch.group(1)!, 80);
                }
                String imageUrl = "https://placehold.co/200x300/000000/FFFFFF?text=No+Image";
                final imageMatch = RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(detailRes.body);
                if (imageMatch != null && imageMatch.group(1) != null) {
                  imageUrl = imageMatch.group(1)!;
                  if (!imageUrl.startsWith("http")) {
                    imageUrl = _buildUrl(imageUrl);
                  }
                }
                mangaList.add(MManga(
                  name: title,
                  link: url,
                  imageUrl: imageUrl,
                ));
                break;
              }
            } catch (_) {}
          }
        }
      }
      return MPages(mangaList, mangaList.isNotEmpty);
    } catch (e) {
      return MPages([], false);
    }
  }

  @override
  Future<MManga> getDetail(String url) async {
    try {
      final res = await _safeGet(url);
      final body = res.body;
      
      // Detect page type
      final isSeriesPage = url.contains('/series/');
      final isFranchisePage = url.contains('/category/franchise/');

      // Title extraction
      String title = "Unknown";
      RegExp? titleReg;
      if (isSeriesPage) {
        titleReg = RegExp(r'<h1[^>]*class="entry-title"[^>]*>(.*?)</h1>');
      } else if (isFranchisePage) {
        titleReg = RegExp(r'<h1[^>]*>(.*?)</h1>');
      }
      final titleMatch = titleReg?.firstMatch(body);
      if (titleMatch != null && titleMatch.group(1) != null) {
        title = _cleanText(titleMatch.group(1)!, 100);
      }

      // Image extraction
      String imageUrl = "https://placehold.co/200x300/000000/FFFFFF?text=No+Image";
      RegExp? imageReg;
      if (isSeriesPage) {
        imageReg = RegExp(r'<img[^>]*style="[^"]*height: 14rem;[^"]*"[^>]*src="([^"]+)"');
      } else if (isFranchisePage) {
        imageReg = RegExp(r'<img[^>]*src="([^"]+)"[^>]*class="[^"]*cover[^"]*"');
      }
      final imageMatch = imageReg?.firstMatch(body);
      if (imageMatch != null && imageMatch.group(1) != null) {
        imageUrl = imageMatch.group(1)!;
        if (imageUrl.startsWith("Limage.")) {
          imageUrl = "https://image." + imageUrl.substring(7);
        }
        if (!imageUrl.startsWith("http")) {
          imageUrl = _buildUrl(imageUrl);
        }
      }

      // Description extraction
      String description = "No description available";
      RegExp? descReg;
      if (isSeriesPage) {
        descReg = RegExp(r'<div[^>]*class="description"[^>]*>(.*?)</div>', dotAll: true);
      } else if (isFranchisePage) {
        descReg = RegExp(r'<div[^>]*class="synopsis"[^>]*>(.*?)</div>', dotAll: true);
      }
      final descMatch = descReg?.firstMatch(body);
      if (descMatch != null && descMatch.group(1) != null) {
        description = _cleanText(descMatch.group(1)!, 500);
      }

      // Status detection
      MStatus status = MStatus.unknown;
      if (body.contains("Status:") || body.contains("status:")) {
        final statusMatch = RegExp(
          r'Status:.*?<span[^>]*>(.*?)</span>',
          caseSensitive: false,
          dotAll: true
        ).firstMatch(body);
        if (statusMatch != null && statusMatch.group(1) != null) {
          final statusText = statusMatch.group(1)!.toLowerCase();
          if (statusText.contains("ongoing")) {
            status = MStatus.ongoing;
          } else if (statusText.contains("completed")) {
            status = MStatus.completed;
          }
        }
      }

      // Genre extraction
      final genres = <String>[];
      RegExp? genreReg;
      if (isSeriesPage) {
        genreReg = RegExp(r'<p[^>]*class="genres"[^>]*>(.*?)</p>', dotAll: true);
      } else if (isFranchisePage) {
        genreReg = RegExp(r'<div[^>]*class="genres"[^>]*>(.*?)</div>', dotAll: true);
      }
      final genreMatch = genreReg?.firstMatch(body);
      if (genreMatch != null && genreMatch.group(1) != null) {
        final genreHtml = genreMatch.group(1)!;
        final genreLinks = RegExp(r'<a[^>]*>(.*?)</a>').allMatches(genreHtml);
        for (final match in genreLinks) {
          if (match.group(1) != null) {
            final genre = _cleanText(match.group(1)!, 30);
            if (genre.length > 2 && !genres.contains(genre)) {
              genres.add(genre);
            }
          }
        }
      }

      // Get chapters (episodes)
      final chapters = await getChapters(url);

      return MManga(
        name: title,
        link: url,
        imageUrl: imageUrl,
        description: description,
        author: "Unknown",
        status: status,
        genre: genres,
        chapters: chapters,
      );
    } catch (e) {
      return MManga(
        name: "Error Loading",
        link: url,
        imageUrl: "https://placehold.co/200x300/000000/FFFFFF?text=Error",
        description: "Failed to load details: $e",
        author: "Unknown",
        status: MStatus.unknown,
        genre: [],
        chapters: [],
      );
    }
  }

  @override
  Future<List<MChapter>> getChapters(String mangaUrl) async {
    try {
      final res = await _safeGet(mangaUrl);
      final body = res.body;
      final chapterList = <MChapter>[];

      // Extract all seasons from the season selector
      final seasonLinks = RegExp(
        r'<a[^>]*data-post="(\d+)"[^>]*data-season="(\d+)"[^>]*>',
        caseSensitive: false
      ).allMatches(body);

      if (seasonLinks.isEmpty) {
        // Fallback to original parsing if no seasons found
        return _parseChaptersFromHTML(body);
      }

      for (final match in seasonLinks) {
        final postId = match.group(1)!;
        final seasonValue = match.group(2)!;
        final seasonName = seasonValue;

        print("Requesting Season $seasonName (season=$seasonValue, post=$postId)");

        try {
          final client = Client();
          final response = await client.post(
            Uri.parse('$baseUrl/wp-admin/admin-ajax.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
              'Referer': mangaUrl,
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: {
              'action': 'action_select_season',
              'season': seasonValue,
              'post': postId,
            },
          );
          client.close();

          if (response.statusCode == 200 && response.body.trim() != '0') {
            final seasonChapters = _parseChaptersFromHTML(response.body, seasonName);
            print("Found \u001b[32m[1m${seasonChapters.length}[0m episodes for Season $seasonName (AJAX)");
            chapterList.addAll(seasonChapters);
          } else {
            print("No episodes found for Season $seasonName (AJAX response empty or invalid)");
          }
          await Future.delayed(Duration(milliseconds: 500));
        } catch (e) {
          print("Error getting episodes for Season $seasonName: $e");
          continue;
        }
      }

      print("Total episodes found: [32m${chapterList.length}");
      // Force reverse order before returning
      return chapterList.reversed.toList();
    } catch (e) {
      print("Error in getChapters: $e");
      return <MChapter>[];
    }
  }

  List<MChapter> _parseChaptersFromHTML(String html, [String? seasonPrefix]) {
    final chapterList = <MChapter>[];
    
    // Find episode container - try multiple patterns
    String containerHtml = "";
    
    // Pattern 1: Direct ul with id
    final containerMatch1 = RegExp(
      r'<ul[^>]*id="episode_by_temp"[^>]*>(.*?)</ul>',
      dotAll: true
    ).firstMatch(html);
    
    if (containerMatch1 != null) {
      containerHtml = containerMatch1.group(1) ?? "";
    } else {
      // Pattern 2: Look for episode list in response
      final containerMatch2 = RegExp(
        r'<ul[^>]*class="[^"]*episode-list[^"]*"[^>]*>(.*?)</ul>',
        dotAll: true
      ).firstMatch(html);
      
      if (containerMatch2 != null) {
        containerHtml = containerMatch2.group(1) ?? "";
      } else {
        // Pattern 3: Direct li elements (for AJAX responses)
        containerHtml = html;
      }
    }

    if (containerHtml.isEmpty) {
      print("No episode container found for season $seasonPrefix");
      return chapterList;
    }

    // Each episode is a <li>...</li>
    final episodes = RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true).allMatches(containerHtml);
    
    print("Found \u001b[32m${episodes.length}[0m episode elements for season $seasonPrefix");
    
    int episodeIndex = 1; // Start episode numbering from 1 for each season
    for (final episode in episodes) {
      final episodeHtml = episode.group(1) ?? "";
      if (episodeHtml.isEmpty) continue;

      // Extract episode link - try multiple patterns
      String link = "";
      
      // Pattern 1: lnk-blk class
      final linkMatch1 = RegExp(
        r'<a[^>]*href="([^"]+)"[^>]*class="[^"]*lnk-blk[^"]*"', 
        caseSensitive: false
      ).firstMatch(episodeHtml);
      
      if (linkMatch1 != null) {
        link = linkMatch1.group(1) ?? "";
      } else {
        // Pattern 2: Any link
        final linkMatch2 = RegExp(r'<a[^>]*href="([^"]+)"').firstMatch(episodeHtml);
        if (linkMatch2 != null) {
          link = linkMatch2.group(1) ?? "";
        }
      }
      
      if (link.isEmpty) continue;

      // Extract episode number (keep for chapterNumber)
      String episodeNum = "0";
      final numMatch = RegExp(
        r'<span[^>]*class="num-epi"[^>]*>(.*?)</span>', 
        caseSensitive: false
      ).firstMatch(episodeHtml);
      
      if (numMatch != null && numMatch.group(1) != null) {
        episodeNum = _cleanText(numMatch.group(1)!).replaceAll("x", ".");
        } else {
        // Try to extract number from link or title
        final urlNumMatch = RegExp(r'episode-(\d+)').firstMatch(link);
        if (urlNumMatch != null) {
          episodeNum = urlNumMatch.group(1)!;
        }
      }

      // Extract episode title
      String title = "Episode";
      final titleMatch = RegExp(
        r'<h2[^>]*class="entry-title"[^>]*>(.*?)</h2>', 
        caseSensitive: false
      ).firstMatch(episodeHtml);
      
      if (titleMatch != null && titleMatch.group(1) != null) {
        title = _cleanText(titleMatch.group(1)!);
      } else {
        // Try alternative title patterns
        final altTitleMatch = RegExp(
          r'<span[^>]*class="title"[^>]*>(.*?)</span>', 
          caseSensitive: false
        ).firstMatch(episodeHtml);
        
        if (altTitleMatch != null && altTitleMatch.group(1) != null) {
          title = _cleanText(altTitleMatch.group(1)!);
        }
      }

      // Format title with season info if available, using incremental episode number
      String finalTitle = title;
      String chapterNumber = episodeNum;
      
      if (seasonPrefix != null && seasonPrefix.isNotEmpty) {
        finalTitle = "S$seasonPrefix E$episodeIndex - $title";
        chapterNumber = "$seasonPrefix.$episodeNum";
      } else {
        finalTitle = "Episode $episodeIndex - $title";
      }

      chapterList.add(MChapter(
        name: finalTitle,
        url: _buildUrl(link),
        dateUpload: DateTime.now().millisecondsSinceEpoch.toString(),
        chapterNumber: chapterNumber,
      ));
      episodeIndex++;
    }
    
    print("Parsed \u001b[32m\u001b[1m\u001b[0m episodes for season $seasonPrefix");
    // Robust sort: last season last episode to first season first episode (reverse chronological)
    try {
      chapterList.sort((a, b) {
        double parseSeason(String s) {
          final parts = s.split('.');
          return parts.isNotEmpty ? double.tryParse(parts[0]) ?? 0 : 0;
        }
        double parseEpisode(String s) {
          final parts = s.split('.');
          return parts.length > 1 ? double.tryParse(parts[1]) ?? 0 : 0;
        }
        final aSeason = parseSeason(a.chapterNumber);
        final bSeason = parseSeason(b.chapterNumber);
        if (aSeason != bSeason) {
          return bSeason.compareTo(aSeason); // Descending by season (last season first)
        }
        final aEp = parseEpisode(a.chapterNumber);
        final bEp = parseEpisode(b.chapterNumber);
        if (aEp != bEp) {
          return bEp.compareTo(aEp); // Descending by episode (last episode first)
        }
        // Fallback: compare chapterNumber as string to avoid infinite loop
        return b.chapterNumber.compareTo(a.chapterNumber);
      });
    } catch (e) {
      print('Error during sorting: $e');
    }
    return chapterList;
  }

  @override
  Future<List<String>> getPageList(String chapterUrl) async {
    try {
      final res = await _safeGet(chapterUrl);
      final body = res.body;

      // Direct video source detection
      final videoMatch = RegExp(r'<iframe[^>]*src="(https?://[^"]+)"').firstMatch(body);
      if (videoMatch != null && videoMatch.group(1) != null) {
        return [videoMatch.group(1)!];
      }

      return ["about:blank"];
    } catch (e) {
      return ["about:blank"];
    }
  }

  Future<String?> _fetchIframeUrlForServer({
    required String episodeId,
    required String serverId,
    required String referer,
  }) async {
    final client = Client();
    try {
      final response = await client.post(
        Uri.parse('https://watchanimeworld.in/wp-admin/admin-ajax.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': referer,
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: {
          'action': 'action_select_server',
          'episode': episodeId,
          'server': serverId,
        },
      );
      if (response.statusCode == 200) {
        final iframeUrlMatch = RegExp(r'src="(https?://[^"]+)"').firstMatch(response.body);
        if (iframeUrlMatch != null) {
          return iframeUrlMatch.group(1);
        }
      }
      return null;
    } finally {
      client.close();
    }
  }

  // Helper to extract episodeId and serverIds from HTML
  Map<String, String> _extractEpisodeAndServers(String body) {
    // Try to extract episode id from data-episode or similar attribute
    final episodeIdMatch = RegExp(r'data-episode="(\d+)"').firstMatch(body);
    String episodeId = episodeIdMatch?.group(1) ?? "";
    // Extract server ids from server selection buttons
    final serverIdMatches = RegExp(r'data-id="(\d+)"').allMatches(body);
    final serverIds = <String>[];
    for (final match in serverIdMatches) {
      if (match.group(1) != null) serverIds.add(match.group(1)!);
    }
    return {"episodeId": episodeId, "serverIds": serverIds.join(",")};
  }

  // Helper to extract qualities and audios from a master .m3u8 playlist
  Future<List<MVideo>> _extractQualitiesAndAudiosFromM3U8(String masterUrl, Map<String, String> headers) async {
    final client = Client();
    final videos = <MVideo>[];
    try {
      final res = await client.get(Uri.parse(masterUrl), headers: headers);
      if (res.statusCode == 200) {
        final lines = res.body.split('\n');
        // Parse audio tracks
        final audios = <MTrack>[];
        for (final line in lines) {
          if (line.startsWith('#EXT-X-MEDIA:') && line.contains('TYPE=AUDIO')) {
            final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
            final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
            if (uriMatch != null && nameMatch != null) {
              final audio = MTrack();
              audio.label = nameMatch.group(1)!;
              audio.file = uriMatch.group(1)!;
              audios.add(audio);
            }
          }
        }
        final reversedAudios = audios.reversed.toList();
        // Parse video variants
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('#EXT-X-STREAM-INF')) {
            // Extract resolution
            final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
            String quality = 'Auto';
            if (resMatch != null) {
              quality = '${resMatch.group(2)}p'; // Use height for label
            }
            // Next line should be the URL
            if (i + 1 < lines.length && !lines[i + 1].startsWith('#')) {
              final url = lines[i + 1].trim();
              final fullUrl = url.startsWith('http') ? url : masterUrl.replaceFirst(RegExp(r'/[^/]+$'), '/') + url;
              final video = MVideo(
                fullUrl,
                'Pixfusion $quality',
                fullUrl,
                headers: headers,
              );
              video.audios = reversedAudios; // Attach audios in reverse order (Hindi to Japanese)
              videos.add(video);
            }
          }
        }
      }
    } finally {
      client.close();
    }
    return videos;
  }

  @override
  Future<List<MVideo>> getVideoList(String chapterUrl) async {
    try {
      final res = await _safeGet(chapterUrl);
      final body = res.body;
      print('--- HTML BODY START ---');
      print(body);
      print('--- HTML BODY END ---');
      final List<MVideo> videoList = [];

      // 1. Extract Pixfusion iframe data-src
      final pixfusionPattern = RegExp(r'data-src="(https://x\.pixfusion\.in/video/([a-zA-Z0-9]+))"', caseSensitive: false);
      final pixfusionMatches = pixfusionPattern.allMatches(body);
      print('Found ${pixfusionMatches.length} Pixfusion matches');
      
      // Determine audio language from source
      String audioLang = source.lang == "hi" ? "hi" : "ja";
      for (final match in pixfusionMatches) {
        final iframeUrl = match.group(1);
        final videoId = match.group(2);
        print('Extracted Pixfusion iframe URL: $iframeUrl');
        print('Extracted video ID: $videoId');
        
        if (iframeUrl != null && videoId != null && iframeUrl.isNotEmpty && videoId.isNotEmpty) {
          final client = Client();
          // 2. Fetch the iframe/player page to get the cookie
          print('Fetching iframe page: $iframeUrl');
          final iframeRes = await client.get(Uri.parse(iframeUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Referer': 'https://watchanimeworld.in/',
          });

          print('Iframe response status: ${iframeRes.statusCode}');
          print('Iframe headers: ${iframeRes.headers}');

          // 3. Extract the fireplayer_player cookie
          String? fireplayerCookie;
          if (iframeRes.headers['set-cookie'] != null) {
            final cookies = iframeRes.headers['set-cookie']!;
            print('Set-Cookie header: $cookies');
            
            // Try multiple regex patterns for cookie extraction
            RegExp? match;
            
            // Pattern 1: fireplayer_player=value;
            match = RegExp(r'fireplayer_player=([^;]+);').firstMatch(cookies);
            if (match == null) {
              // Pattern 2: fireplayer_player=value (no semicolon)
              match = RegExp(r'fireplayer_player=([^;\s]+)').firstMatch(cookies);
            }
            if (match == null) {
              // Pattern 3: just look for the value after fireplayer_player=
              match = RegExp(r'fireplayer_player=([a-zA-Z0-9]+)').firstMatch(cookies);
            }
            
            if (match != null) {
              fireplayerCookie = 'fireplayer_player=${match.group(1)}';
              print('Extracted fireplayer cookie: $fireplayerCookie');
            } else {
              print('No fireplayer_player cookie found in Set-Cookie header');
              print('Available cookies: $cookies');
            }
          } else {
            print('No Set-Cookie header found');
            print('Available headers: ${iframeRes.headers.keys}');
          }

          // 4. POST to the player endpoint with all cookies and headers
          final playerUrl = 'https://x.pixfusion.in/player/index.php?data=$videoId&do=getVideo';
          print('POSTing to player URL: $playerUrl');
          print('Using cookie: $fireplayerCookie');
          
          var playerRes;
          
          // Try with cookie first
          if (fireplayerCookie != null) {
            playerRes = await client.post(
              Uri.parse(playerUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                'Accept': '*/*',
                'Origin': 'https://x.pixfusion.in',
                'X-Requested-With': 'XMLHttpRequest',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Referer': iframeUrl,
                'Cookie': fireplayerCookie,
              },
            );
            
            print('Player response status (with cookie): ${playerRes.statusCode}');
            print('Player response body starts with: ${playerRes.body.startsWith('{') ? 'JSON' : 'HTML'}');
            
            // If we got HTML instead of JSON, try without cookie
            if (!playerRes.body.startsWith('{')) {
              print('Got HTML response, trying without cookie...');
              playerRes = await client.post(
                Uri.parse(playerUrl),
                headers: {
                  'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                  'Accept': '*/*',
                  'Origin': 'https://x.pixfusion.in',
                  'X-Requested-With': 'XMLHttpRequest',
                  'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                  'Referer': iframeUrl,
                },
              );
              print('Player response status (without cookie): ${playerRes.statusCode}');
            }
          } else {
            // No cookie available, try without it
            playerRes = await client.post(
              Uri.parse(playerUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                'Accept': '*/*',
                'Origin': 'https://x.pixfusion.in',
                'X-Requested-With': 'XMLHttpRequest',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Referer': iframeUrl,
              },
            );
            print('Player response status (no cookie): ${playerRes.statusCode}');
          }

          // --- ADDED DEBUG PRINTS ---
          print('Raw player response body: ${playerRes.body}');
                     try {
             final playerData = jsonDecode(playerRes.body);
             print('Parsed Pixfusion JSON: $playerData');
             print('JSON keys: ${playerData.keys}');
             final String? securedLink = playerData['securedLink'];
             final String? videoSource = playerData['videoSource'];
            print('Extracted securedLink: $securedLink');
            print('Extracted videoSource: $videoSource');
                         if (securedLink != null && securedLink.isNotEmpty && securedLink.contains('.m3u8')) {
              final qualities = await _extractQualitiesAndAudiosFromM3U8(securedLink, {
                'Referer': playerUrl,
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
              });
              if (qualities.isNotEmpty) {
                videoList.addAll(qualities);
              } else {
                videoList.add(MVideo(
                  securedLink,
                  "Pixfusion HLS (secured)",
                  securedLink,
                  headers: {
                    'Referer': playerUrl,
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                  },
                ));
              }
                         } else if (videoSource != null && videoSource.isNotEmpty && videoSource.contains('.m3u8')) {
              final qualities = await _extractQualitiesAndAudiosFromM3U8(videoSource, {
                'Referer': playerUrl,
                'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
              });
              if (qualities.isNotEmpty) {
                videoList.addAll(qualities);
              } else {
                videoList.add(MVideo(
                  videoSource,
                  "Pixfusion HLS",
                  videoSource,
                  headers: {
                    'Referer': playerUrl,
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                  },
                ));
              }
            } else {
              if (securedLink != null && securedLink.isNotEmpty) {
                videoList.add(MVideo(
                  securedLink,
                  "Pixfusion HLS (secured)",
                  securedLink,
                  headers: {
                    'Referer': playerUrl,
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                  },
                ));
              }
              if (videoSource != null && videoSource.isNotEmpty) {
                videoList.add(MVideo(
                  videoSource,
                  "Pixfusion HLS",
                  videoSource,
                  headers: {
                    'Referer': playerUrl,
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Mobile Safari/537.36',
                  },
                ));
              }
            }
          } catch (e) {
            print('JSON parse error: $e');
            print('Response body that failed to parse: ${playerRes.body}');
          }
          client.close();
        } else {
          print('Invalid iframe URL or video ID: iframeUrl=$iframeUrl, videoId=$videoId');
        }
      }

      if (videoList.isEmpty) {
        print('No Pixfusion videos found, adding fallback');
        videoList.add(MVideo(
          chapterUrl,
          "Episode Page",
          chapterUrl,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ));
      }

      print('Final videoList length: ${videoList.length}');
      for (int i = 0; i < videoList.length; i++) {
        print('Video $i: url=${videoList[i].url}, quality=${videoList[i].quality}');
      }

      return videoList;
    } catch (e) {
      print('Error in getVideoList: $e');
      return <MVideo>[
        MVideo(
          chapterUrl,
          "Error: $e",
          chapterUrl,
          headers: {},
        ),
      ];
    }
  }
}


// At the end of the file, export both sources
final sources = [
  MSource(
    id: 1,
    name: "WatchAnimeWorld (Hindi)",
    lang: "hi",
    baseUrl: "https://watchanimeworld.in",
  ),
  MSource(
    id: 2,
    name: "WatchAnimeWorld (Japanese)",
    lang: "ja",
    baseUrl: "https://watchanimeworld.in",
  ),
];

WatchAnimeWorldClient main(MSource source) {
  return WatchAnimeWorldClient(source: source);
}
