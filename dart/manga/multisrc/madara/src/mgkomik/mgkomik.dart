import '../../../../../../model/source.dart';

Source get mgkomikSource => _mgkomikSource;
Source _mgkomikSource = Source(
  name: "MG Komik",
  baseUrl: "https://mgkomik.id",
  lang: "id",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/main/dart/manga/multisrc/madara/src/mgkomik/icon.png",
  dateFormat: "dd MMM yy",
  dateFormatLocale: "en_us",
);
