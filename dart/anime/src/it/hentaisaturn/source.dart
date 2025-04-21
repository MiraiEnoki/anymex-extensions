import '../../../../../model/source.dart';

Source get hentaisaturn => _hentaisaturn;
const _hentaisaturnVersion = "0.0.1";
const _hentaisaturnCodeUrl =
    "https://raw.githubusercontent.com/xShader1374/mangayomi-extensions/$branchName/dart/anime/src/it/hentaisaturn/hentaisaturn.dart";
Source _hentaisaturn = Source(
  name: "HentaiSaturn",
  baseUrl: "https://www.hentaisaturn.tv",
  lang: "it",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/xShader1374/mangayomi-extensions/$branchName/dart/anime/src/it/hentaisaturn/HentaiSaturnLogo.png",
  sourceCodeUrl: _hentaisaturnCodeUrl,
  version: _hentaisaturnVersion,
  itemType: ItemType.anime,
);
