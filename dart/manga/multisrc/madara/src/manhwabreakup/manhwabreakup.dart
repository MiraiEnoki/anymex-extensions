import '../../../../../../model/source.dart';

Source get manhwabreakupSource => _manhwabreakupSource;
Source _manhwabreakupSource = Source(
  name: "ManhwaBreakup",
  baseUrl: "https://www.manhwabreakup.com",
  lang: "th",
  isNsfw: false,
  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/main/dart/manga/multisrc/madara/src/manhwabreakup/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "th",
);
