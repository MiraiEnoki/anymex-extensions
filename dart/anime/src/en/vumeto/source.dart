import '../../../../../model/source.dart';

Source get vumetoSource => _vumetoSource;
const _vumetoVersion = "0.0.5";
const _vumetoSourceCodeUrl =
    "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/$branchName/dart/anime/src/en/vumeto/vumeto.dart";
Source _vumetoSource = Source(
  name: "vumeto",
  baseUrl: "https://vumeto.com",
  lang: "en",
  typeSource: "single",
  iconUrl:
      "https://vumeto.com/pwa/icons/icon_x512.png",
  sourceCodeUrl: _vumetoSourceCodeUrl,
  version: _vumetoVersion,
  itemType: ItemType.anime,
);
