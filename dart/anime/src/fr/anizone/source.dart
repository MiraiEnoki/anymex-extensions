import '../../../../../model/source.dart';

Source get aniZoneSource => _aniZoneSource;
const _aniZoneVersion = "0.0.2";
const _aniZoneSourceCodeUrl =
    "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/anime/src/fr/anizone/anizone.dart";
Source _aniZoneSource = Source(
  name: "AniZone",
  baseUrl: "https://v1.animesz.xyz",
  lang: "fr",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/anime/src/fr/anizone/icon.png",
  sourceCodeUrl: _aniZoneSourceCodeUrl,
  version: _aniZoneVersion,
  itemType: ItemType.anime,
);
