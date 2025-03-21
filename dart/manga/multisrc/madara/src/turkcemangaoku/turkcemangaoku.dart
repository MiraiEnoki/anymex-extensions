import '../../../../../../model/source.dart';

Source get turkcemangaokuSource => _turkcemangaokuSource;
Source _turkcemangaokuSource = Source(
  name: "Türkçe Manga Oku",
  baseUrl: "https://turkcemangaoku.com",
  lang: "tr",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/main/dart/manga/multisrc/madara/src/turkcemangaoku/icon.png",
  dateFormat: "d MMMM yyyy",
  dateFormatLocale: "tr",
);
