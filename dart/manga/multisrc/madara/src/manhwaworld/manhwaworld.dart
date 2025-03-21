import '../../../../../../model/source.dart';

Source get manhwaworldSource => _manhwaworldSource;

Source _manhwaworldSource = Source(
  name: "AQUA Scans",
  baseUrl: "https://aquascans.com",
  lang: "en",

  typeSource: "madara",
  iconUrl:
      "https://raw.githubusercontent.com/MiraiEnoki/anymex-extensions/$branchName/dart/manga/multisrc/madara/src/manhwaworld/icon.png",
  dateFormat: "MMMM dd, yyyy",
  dateFormatLocale: "en_us",
);
