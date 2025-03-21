import '../../../../../../model/source.dart';

Source get mangastarzSource => _mangastarzSource;
Source _mangastarzSource = Source(
  name: "Manga Starz",
  baseUrl: "https://manga-starz.com",
  lang: "ar",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/main/dart/manga/multisrc/madara/src/mangastarz/icon.png",
  dateFormat: "d MMMM، yyyy",
  dateFormatLocale: "ar",
);
