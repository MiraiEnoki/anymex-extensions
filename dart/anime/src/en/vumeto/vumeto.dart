import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class Vumeto extends MProvider {
  Vumeto({required this.source});

  MSource source;

  final Client client = Client(source);

  @override
  bool get supportsLatest => false;

  @override
  Map<String, String> get headers => {};
  
  @override
  Future<MPages> getPopular(int page) async {
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final url = 'https://vumeto.com/search?q=$query';
    final resp = await client.get(Uri.parse(url));
    
    final document = parseHtml(resp.body);
    
    return MPages(scrapeAnimeList(document), false);
  }
  
  String fixUrl(String encodedUrl) {
  return encodedUrl
      .split('url=').last
      .split('&w').first
      .replaceAll('%3A', ':')
      .replaceAll('%2F', '/')
      .replaceAll('%3F', '?')
      .replaceAll('%3D', '=')
      .replaceAll('%26', '&');
}

  
List<MManga> scrapeAnimeList(MDocument document) {
  List<MElement>? animeElements = document.getElementsByClassName('relative group border-0');
  List<MManga> results = [];

  if (animeElements != null) {
    for (var anime in animeElements) {
      String? title = anime.selectFirst('h3')?.text ?? '';
      String? animeUrl = anime.selectFirst('a')?.attr('href') ?? '';
      String? imageUrl = anime.selectFirst('img')?.attr('src') ?? '';

     MManga manga = MManga();
     manga.name = title;
    manga.link =  "https://vumeto.com/watch/" + animeUrl.replaceAll('/info/', '').split('/').first + '?ep=1';
    manga.imageUrl = fixUrl(imageUrl.split('url=').last);


      results.add(manga);
    }
  }
  return results;
}

@override
Future<MManga> getDetail(String url) async {
  final uri = Uri.parse(url);
  final resp = await client.get(uri);
  final document = parseHtml(resp.body);
  final mainContainer = document.selectFirst(".mx-auto.w-full.p-2"); 
  
final title = mainContainer.selectFirst("h1.text-lg.md\\:text-2xl.leading-6.font-semibold.w-fit")?.text ?? '';

final description = mainContainer
        .selectFirst("p.text-sm.max-md\\:hidden.text-muted-foreground.text-center.line-clamp-6.md\\:text-left.md\\:line-clamp-3")
        ?.text ??
    mainContainer
        .selectFirst("p.text-sm.md\\:hidden.text-muted-foreground.line-clamp-6.mt-2")
        ?.text ??
    '';

final imgElement = mainContainer.selectFirst("img");
final srcset = imgElement?.attr("srcset") ?? '';
final imageUrl = srcset.split(", ").last.split(" ").first;

print(title);
print(description);
print(imageUrl);


  String status = "";
  final infoContainer = mainContainer?.selectFirst("div.flex.flex-col.gap-2.text-sm");

  if (infoContainer != null) {
    final allDivs = infoContainer.select("div") ?? [];
    
    for (var div in allDivs) {
      final divText = div.text ?? "";
      if (divText.contains("Status:")) {
        status = divText.replaceAll("Status:", "").trim();
        print("Found status: $status");
      }
    }
  }

final genreLinks = mainContainer.select("a[href^='/genre/']") ?? [];

final genres = genreLinks
    .map((MElement? e) => e.text ?? '')
    .toList();
  

  
  List<MChapter> chapters = [];
  final scripts = document.getElementsByTagName("script");

  String jsonData = "";
  for (var script in scripts!) {
    if (script.text!.contains("episodesData")) {
      final regex = RegExp(r'self\.__next_f\.push\(\[1,".*?",null,(.*?)\]\)',
          dotAll: true);
      print("Found episodesData in script!");
      final match = regex.firstMatch(script.text!);

      if (match != null && match.groupCount >= 1) {
        String cleaned = match.group(1)!.replaceAll(r'\', '');

        jsonData = cleaned.substring(0, cleaned.length - 3);
        break;
      } else {
        print("Regex did not match.");
      }
    }
  }
  Map<String, dynamic> parsedData = json.decode(jsonData);
  List<dynamic> episodesData = parsedData['episodesData'];
      for (var ep in episodesData) {
      MChapter ch = MChapter();
      final number = (ep?['episodeNo'] ?? episodesData.indexOf(ep) + 1).toString();

        ch.name = "Episode $number";

      ch.url = url.split('?').first + '?ep=$number';


      if (!chapters.any((c) => c.name == ch.name)) {
        chapters.add(ch);
      }  
    }

  MManga result = MManga();
  result.name = title;
  result.link = "https://vumeto.com";
  result.imageUrl = fixUrl(imageUrl);
  result.description = description;
  result.status = status == "Releasing" ? MStatus.ongoing : MStatus.completed;
  result.genre = genres;
  result.chapters = chapters;
  
  return result;
}

  
  String stripTags(String htmlString) {
  final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  return htmlString.replaceAll(exp, '').trim();
}

  
List<MChapter> getChaps(MDocument document, String url) {
  List<MChapter> chapters = [];
  final scripts = document.getElementsByTagName("script");

  String jsonData = "";
  for (var script in scripts!) {
    if (script.text!.contains("episodesData")) {
      final regex = RegExp(r'self\.__next_f\.push\(\[1,".*?",null,(.*?)\]\)',
          dotAll: true);
      print("Found episodesData in script!");
      final match = regex.firstMatch(script.text!);

      if (match != null && match.groupCount >= 1) {
        String cleaned = match.group(1)!.replaceAll(r'\', '');

        jsonData = cleaned.substring(0, cleaned.length - 3);
        break;
      } else {
        print("Regex did not match.");
      }
    }
  }

  try {
    Map<String, dynamic> parsedData = json.decode(jsonData);
    List<dynamic> episodesData = parsedData['episodesData'];
    for (var ep in episodesData) {
      MChapter ch = MChapter();
//      ch.name = "Episode ${ep['episodeNo']}: ${ep['title']}";
 //     ch.url = url.split('?').first + '?ep=' + ep['episodeNo'];
       ch.name = "Episode";
       ch.url = '';

      final existingChapter = chapters.firstWhere(
        (c) => c.url == ch.url,
        orElse: () => null,
      );
      
      return chapters;

      if (existingChapter == null) {
        chapters.add(ch);
        print("Extracted: ${ch.title} -> ${ch.url}");
      } else {
        print("Chapter already exists: ${ch.title}");
      }
    }
    return chapters;
  } catch (e) {
    print("JSON Parsing Error: $e");
  }

  return chapters;
}
  
  // For novel html content
  @override
  Future<String> getHtmlContent(String url) async {
    // TODO: implement
  }
  
  // Clean html up for reader
  @override
  Future<String> cleanHtmlContent(String html) async {
    // TODO: implement
  }

@override
Future<List<MVideo>> getVideoList(String url) async {
  try {
    final resp = await client.get(Uri.parse(url));
    
    final document = parseHtml(resp.body);
    
    final scripts = document.getElementsByTagName("script");
    if (scripts.isEmpty) {
      print("No <script> tags found.");
      return [];
    }
    
    String jsonData = "";
    for (var script in scripts) {
      if (script.text.contains("episodesData")) {
        final regex = RegExp(r'self\.__next_f\.push\(\[1,".*?",null,(.*?)\]\)', dotAll: true);
        final match = regex.firstMatch(script.text);
        if (match != null && match.groupCount >= 1) {
          String cleaned = match.group(1)!.replaceAll(r'\', '');
          jsonData = cleaned.substring(0, cleaned.length - 3);
          break;
        }
      }
    }
    
    if (jsonData.isEmpty) {
      print("Could not find video data in any script tag.");
      return [];
    }
    
    final Map<String, dynamic> parsedData = json.decode(jsonData);
    final List<dynamic> episodesData = parsedData['episodesData'];
    
    List<Map<String, dynamic>> extractedData = [];
    
    if (episodesData.isNotEmpty) {
      final index = int.parse(url.split('ep=').last);
      final episode = episodesData[index];
      
      for (var sub in episode['sub']) {

        for (var source in sub['sources']) {

          String quality = "AUTO" ;
          if (stringContains(sub['serverName'], 'Kiwi')) {
            quality = '${source['quality'].toString()}P';
          }
          final String serverName = "${sub['serverName']}- SUB - ${quality ?? "AUTO"}";
          final String m3u8Url = source['url'];
          
          List<Map<String, dynamic>> subtitles = [];
          for (var track in sub['tracks'] ?? []) {
           if(track['kind'] == "captions") {
            final String label = (track['label'] is String) ? track['label'].toString() : 'Unknown';
            subtitles.add({
              'url': track['file'],
              'default': track['default'] == true,
              "label": label,
            }); 
           }
          }
          
          if(source['isProxy'] == true || source['isProxy'] == 'true') {
            m3u8Url = 'https://proxy.vumeto.com/fetch?url=' + m3u8Url;
          }
          
          extractedData.add({
            'serverName': serverName,
            'm3u8Url':   m3u8Url,
            'subtitles': subtitles,
          });
        }
      }

      for (var dub in episode['dub']) {

        for (var source in dub['sources']) {
          String quality = 'AUTO';
          if (stringContains(dub['serverName'], 'Kiwi')) {
            quality = '${source['quality'].toString()}P';
          }
          final String serverName = "${dub['serverName']}- DUB - ${quality ?? "AUTO"}";
          final String m3u8Url = source['url'];
          
          List<Map<String, dynamic>> subtitles = [];
          if(source['isProxy'] == true || source['isProxy'] == 'true') {
            m3u8Url = 'https://proxy.vumeto.com/fetch?url=' + m3u8Url;
          }
          extractedData.add({
            'serverName': serverName,
            'm3u8Url': m3u8Url,
            'subtitles': subtitles,
          });
        }
      }
    }
List<MVideo> data = extractedData.map((videoData) {
  MVideo video = MVideo(); 

  video.url = videoData['m3u8Url'] ?? '';  
  video.quality = videoData['serverName'] ?? '';  
  video.originalUrl = videoData['m3u8Url'] ?? '';

  List<MTrack>? subtitles = (videoData['subtitles'] as List<dynamic>?)
      ?.map((subtitle) {
        MTrack track = MTrack();
        return track
          ..file = subtitle['url'] ?? ''
          ..label = subtitle['label'];
      })
      .toList();

  video.subtitles = subtitles;

  return video;
}).toList();

    return data; 
  } catch (e) {
    print("Error in getVideoList: $e");
    return [];
  }
}


bool stringContains(String text, String search) {
  return RegExp(search, caseSensitive: false).hasMatch(text);
}


  // For manga chapter pages
  @override
  Future<List<String>> getPageList(String url) async{
    // TODO: implement
  }

  @override
  List<dynamic> getFilterList() {
    // TODO: implement
  }

  @override
  List<dynamic> getSourcePreferences() {
    // TODO: implement
  }
}

Vumeto main(MSource source) {
  return Vumeto(source:source);
}
