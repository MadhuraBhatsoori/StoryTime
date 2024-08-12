Future<bool> moderateForChildren(String topic) async {
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
//check if topic is in list of unsuitable topics for children
  bool isSuitableForChildren(String topic,  List<String> unsuitableTopics) {
    String lowerTopic = topic.toLowerCase();
 

    for (var unsuitable in unsuitableTopics) {
      String lowerUnsuitable = unsuitable.toLowerCase();
      if (lowerTopic.contains(lowerUnsuitable) ) {
        return false;
      }
    }
    return true;
  }


  return isSuitableForChildren(topic,  unsuitableTopics);
}
