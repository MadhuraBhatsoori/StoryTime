import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Backend {
  late GenerativeModel model;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  //Use gemini API
  Backend() {
    final apiKey = dotenv.env['GOOGLE_GENERATIVE_API_KEY']!;
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }
// save story based on user email
   Future<String?> checkIfTopicSaved(String topicName, String userEmail) async {
  try {
    final querySnapshot = await _firestore
        .collection('stories')
        .where('topicName', isEqualTo: topicName)
        .where('userEmail', isEqualTo: userEmail)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    } else {
      return null;
    }
  } catch (e) {
    throw Exception('Failed to check if topic is saved: $e');
  }
}


  Future<String> saveStory({
    required String story,
    required String topicName,
    required String audience,
    required String timestamp,
    required String userEmail,
  }) async {
    try {
      final docRef = await _firestore.collection('stories').add({
        'story': story,
        'topicName': topicName,
        'audience': audience,
        'timestamp': timestamp,
        'userEmail': userEmail,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save story: $e');
    }
  }
//unsave story
  Future<void> unsaveStory(String docId) async {
    try {
      await _firestore.collection('stories').doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to unsave story: $e');
    }
  }
//list of 3d models available
  Future<List<String>> getAvailableModels() async {
    // Return the list of available models
      return [ 'astronaut.glb', 'baby_lion.glb', 'bear.glb', 'boat.glb', 'camel.glb', 'cat.glb', 'cheetah.glb',  'cow.glb', 'deer.glb', 'dolphin.glb', 'dragon.glb',  'elephant.glb', 'fish.glb', 'frog.glb', 'fruit.glb', 'giraffe.glb', 'helicopter.glb', 'hello_kitty.glb', 'horse.glb', 'jerry.glb', 'leopard.glb', 'lion.glb', 'mickey-mouse.glb', 'minion.glb', 'monkey.glb', 'olaf.glb','owl.glb', 'panda.glb', 'penguin.glb', 'picachu.glb', 'pig.glb', 'rabbit.glb', 'robots.glb', 'rocket.glb', 'rose_flower.glb',  'spiderman.glb', 'spongebob.glb', 'tiger.glb', 'tom.glb', 'train.glb', 'turtle.glb', 'unicorn.glb', 'winnie_the_pooh.glb'];
  }
  // based on list guide gemini to get suitable models
  Future<List<String>> getSuitableModels(String story, List<String> models) async {
    
    if (models.isEmpty) {
      return [];  
    }

    try {
      final prompt = '''
      Given the following story and list of 3D models,  determine which models are directly related to the topic, key elements, themes, characters, or objects in the story. Only select models that are clearly depicted in the story. Do not include any models that are irrelevant or unrelated to the story's content.

      Story: $story

      Available models: ${models.join(', ')}

      Return the names of the suitable models as a comma-separated list.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text;
      
      if (result == null) {
        throw Exception('No response from Gemini API');
      }

      final suitableModels = result.split(',').map((e) => e.trim()).toList();
      
      final filteredModels = suitableModels.where((model) => models.contains(model)).toList();
      
      return filteredModels;

    } catch (e) {
      throw Exception('Failed to load suitable models: $e');
    }
  }
}
