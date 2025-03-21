import '../../../../../../model/source.dart';

Source get mangaschanSource => _mangaschanSource;
Source _mangaschanSource = Source(
  name: "Mangás Chan",
  baseUrl: "https://mangaschan.net",
  lang: "pt-br",
  isNsfw: false,
  typeSource: "mangareader",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/manga/multisrc/mangareader/src/mangaschan/icon.png",
  dateFormat: "MMMMM dd, yyyy",
  dateFormatLocale: "pt-br",
);
