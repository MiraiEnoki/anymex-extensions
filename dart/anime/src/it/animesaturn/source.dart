import '../../../../../model/source.dart';

Source get animesaturn => _animesaturn;
const _animesaturnVersion = "0.0.5";
const _animesaturnCodeUrl =
    "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/anime/src/it/animesaturn/animesaturn.dart";
Source _animesaturn = Source(
  name: "AnimeSaturn",
  baseUrl: "https://www.animesaturn.cx",
  lang: "it",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/anime/src/it/animesaturn/icon.png",
  sourceCodeUrl: _animesaturnCodeUrl,
  version: _animesaturnVersion,
  itemType: ItemType.anime,
);
