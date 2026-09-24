/// The library's segment `type`; [unknown] for values the app has not met.
enum SegmentType {
  frontMatter('front_matter'),
  backMatter('back_matter'),
  title('title'),
  verse('verse'),
  paragraph('paragraph'),
  topSegment('top_segment'),
  unknown('');

  const SegmentType(this.apiName);

  final String apiName;

  static SegmentType fromApi(String? name) {
    for (final type in values) {
      if (type != unknown && type.apiName == name) return type;
    }
    return unknown;
  }
}
