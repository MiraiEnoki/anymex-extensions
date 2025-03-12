import '../../../../../model/source.dart';

Source get vumetoSource => _vumetoSource;
const _vumetoVersion = "0.0.1";
const _vumetoSourceCodeUrl =
    "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/anime/src/en/vumeto/vumeto.dart";
Source _vumetoSource = Source(
  name: "Vumeto",
  baseUrl: "https://vumeto.com",
  lang: "en",
  typeSource: "single",
  iconUrl:
      "https://vumeto.com/pwa/icons/icon_x512.png",
  sourceCodeUrl: _vumetoSourceCodeUrl,
  version: _vumetoVersion,
  itemType: ItemType.anime,
);
