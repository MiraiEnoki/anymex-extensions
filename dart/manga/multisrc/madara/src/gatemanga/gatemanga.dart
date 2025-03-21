import '../../../../../../model/source.dart';

Source get gatemangaSource => _gatemangaSource;
Source _gatemangaSource = Source(
  name: "Gatemanga",
  baseUrl: "https://gatemanga.com",
  lang: "ar",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/main/dart/manga/multisrc/madara/src/gatemanga/icon.png",
  dateFormat: "d MMMM، yyyy",
  dateFormatLocale: "ar",
);
