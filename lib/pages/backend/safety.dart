Future<bool> moderateForChildren(String topic, String extra) async {
  List<String> unsuitableTopics = [
    'Horror',
    'Violence',
    'Crime',
    'Drugs',
    'Criminal Behavior',
    'Mature Romantic Content',
    'Dark Magic',
    'Intense Psychological Themes',
    'Gothic Fiction',
    'Strong Language',
    'Explicit Content',
    'politics',
    'religion'
  ];
//check if topic or theme is in list of unsuitable topics for children
  bool isSuitableForChildren(String topic, String extra, List<String> unsuitableTopics) {
    String lowerTopic = topic.toLowerCase();
    String lowerExtra = extra.toLowerCase();

    for (var unsuitable in unsuitableTopics) {
      String lowerUnsuitable = unsuitable.toLowerCase();
      if (lowerTopic.contains(lowerUnsuitable) || lowerExtra.contains(lowerUnsuitable)) {
        return false;
      }
    }
    return true;
  }

  // Call the method and return the result
  return isSuitableForChildren(topic, extra, unsuitableTopics);
}
