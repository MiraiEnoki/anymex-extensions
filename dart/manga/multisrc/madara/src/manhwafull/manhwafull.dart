import '../../../../../../model/source.dart';

Source get manhwafullSource => _manhwafullSource;

Source _manhwafullSource = Source(
  name: "Manhwafull",
  baseUrl: "https://manhwafull.com",
  lang: "en",

  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/manga/multisrc/madara/src/manhwafull/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);
