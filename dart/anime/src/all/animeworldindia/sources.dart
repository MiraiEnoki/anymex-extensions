import '../../../../../model/source.dart';

const _watchanimeworldVersion = "0.0.50";
const _watchanimeworldSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/all/animeworldindia/animeworldindia.dart";

String _iconUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/all/animeworldindia/icon.png";

List<String> _languages = [
  "all",
  "en",
  "bn",
  "hi",
  "ja",
  "ml",
  "mr",
  "ta",
  "te",
];

List<Source> get animeworldindiaSourcesList => _animeworldindiaSourcesList;
List<Source> _animeworldindiaSourcesList =
    _languages
        .map(
          (e) => Source(
            name: 'Watchanimeworld',
            baseUrl: "https://watchanimeworld.in",
            lang: e,
            typeSource: "multiple",
            iconUrl: _iconUrl,
            version: _watchanimeworldVersion,
            itemType: ItemType.anime,
            sourceCodeUrl: _watchanimeworldSourceCodeUrl,
          ),
        )
        .toList();
