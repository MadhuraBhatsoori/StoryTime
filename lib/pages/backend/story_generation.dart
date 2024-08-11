import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateStoryBackend {
  late GenerativeModel model;

  CreateStoryBackend() {
    final apiKey = dotenv.env['GOOGLE_GENERATIVE_API_KEY']!;
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  int calculateTotalWords(double duration) {
    return (duration * 140).toInt();
  }

  Map<String, int> calculateWordDistribution(double duration) {
    final totalWords = calculateTotalWords(duration);
    final introWords = (totalWords * 0.1).toInt();
    final mainContentWords = (totalWords * 0.8).toInt();
    final conclusionWords = (totalWords * 0.1).toInt();

    return {
      'introWords': introWords,
      'mainContentWords': mainContentWords,
      'conclusionWords': conclusionWords,
    };
  }

  int convertAgeStringToInt(String ageString) {
    final match = RegExp(r'(\d+)').firstMatch(ageString);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  String getVocabularyGuidelines(int age) {
    if (age <= 4) {
      return 'Use very simple words and short sentences suitable for a 4-year-old. Avoid complex vocabulary and abstract concepts.';
    } else if (age <= 6) {
      return 'Use simple words and sentences but introduce slightly more varied vocabulary. Avoid complex structures and abstract ideas.';
    } else if (age <= 8) {
      return 'Use a wider range of vocabulary and more complex sentence structures appropriate for 8-year-olds. Begin introducing some abstract concepts.';
    } else {
      return 'Use varied vocabulary and more complex sentence structures suitable for 10-year-olds. Include some abstract concepts and more detailed descriptions.';
    }
  }

  Future<String> generateStory({
    required String topic,
    required String audience,
    required String extra,
    required double sliderValue, // duration in minutes
  }) async {
    final age = convertAgeStringToInt(audience);
    final wordDistribution = calculateWordDistribution(sliderValue);
    final vocabularyGuidelines = getVocabularyGuidelines(age);

    const generalPrompt = '''
      Tone:
      Keep the story fun, engaging, and age-appropriate. Use a gentle, friendly tone. Include clear descriptions of characters and settings. Ensure the story has a positive message.

      Formatting:
      Avoid using asterisks (*), quotes, or any special characters. Don't add comments or staging instructions. Do not address whom the story is for and do not mention "end" at the last.

      Objective:
      Create a seamless, enjoyable reading experience that captures the imagination of young readers, encouraging them to explore the story world and connect with the characters.

      Safety Guidelines:
      The story must avoid any elements of unsuitable topics such as horror, violence, crime, drugs, criminal behavior, mature romantic content, dark magic, intense psychological themes, gothic fiction, strong language, explicit content, politics, or religion. Ensure that none of these elements are present in the story.
    ''';

    final introPrompt = '''
      You are writing a children's story about $topic.
      Start with a fun and engaging introduction:
      Hello! Welcome to a magical story about $topic. Hope you enjoy this story and have lots of fun!
      Write an introduction for the story in about ${wordDistribution['introWords']} words. Make sure to be engaging and vivid.
      $generalPrompt
      $vocabularyGuidelines
    ''';

    final bodyPrompt = '''
      You are writing a children's story about $topic. Write a detailed story with elements of $extra. Ensure the story is engaging and age-appropriate for a child of age $age. Write the main content in approximately ${wordDistribution['mainContentWords']} words. Include vivid descriptions and maintain interest throughout.
      $generalPrompt
      $vocabularyGuidelines
    ''';

    final conclusionPrompt = '''
      You are writing a story about $topic for a child of age $age.
      Write a detailed and positive conclusion for the story, aiming for approximately ${wordDistribution['conclusionWords']} words. Make sure the conclusion ties up the story nicely and leaves the reader with a positive feeling.
      $generalPrompt
      $vocabularyGuidelines
    ''';

    try {
      final introResponse = await model.generateContent([Content.text(introPrompt)]);
      final bodyResponse = await model.generateContent([Content.text(bodyPrompt)]);
      final conclusionResponse = await model.generateContent([Content.text(conclusionPrompt)]);

      // Ensure responses contain the expected fields
      if (introResponse.text == null || bodyResponse.text == null || conclusionResponse.text == null) {
        throw Exception('One or more API responses are null or malformed');
      }

      // Concatenate the parts to form the full story
      String generatedStory = '${introResponse.text}\n\n${bodyResponse.text}\n\n${conclusionResponse.text}';
      

      return generatedStory;
    } catch (e) {
     
      throw Exception('Error generating story: $e');
    }
  }
}
