import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendE {
  late GenerativeModel model;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BackendE() {
    final apiKey = dotenv.env['GOOGLE_GENERATIVE_API_KEY']!;
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String?> checkIfSaved(String story, String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('story', isEqualTo: story)
          .where('userEmail', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to check if story is saved: $e');
    }
  }

  Future<String> saveStory({
    required String story,
    required String topicName,
    required String timestamp,
    required String userEmail,
  }) async {
    try {
      final docRef = await _firestore.collection('stories').add({
        'story': story,
        'topicName': topicName,
        'timestamp': timestamp,
        'userEmail': userEmail,
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save story: $e');
    }
  }

  Future<void> unsaveStory(String docId) async {
    try {
      await _firestore.collection('stories').doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to unsave story: $e');
    }
  }

  Future<List<String>> getAvailableModels() async {
    // Ideally, this would be fetched dynamically from a service or database
   return [ 'astronaut.glb', 'baby_lion.glb', 'bear.glb', 'boat.glb', 'camel.glb', 'cat.glb', 'cheetah.glb',  'cow.glb', 'deer.glb', 'dolphin.glb', 'dragon.glb',  'elephant.glb', 'fish.glb', 'frog.glb', 'fruit.glb', 'giraffe.glb', 'helicopter.glb', 'hello_kitty.glb', 'horse.glb', 'jerry.glb', 'leopard.glb', 'lion.glb', 'mickey-mouse.glb', 'minion.glb', 'monkey.glb', 'olaf.glb','owl.glb', 'panda.glb', 'penguin.glb', 'picachu.glb', 'pig.glb', 'rabbit.glb', 'robots.glb', 'rocket.glb', 'rose_flower.glb',  'spiderman.glb', 'spongebob.glb', 'tiger.glb', 'tom.glb', 'train.glb', 'turtle.glb', 'unicorn.glb', 'winnie_the_pooh.glb'];
  }
  
  Future<List<String>> getSuitableModels(String story, List<String> models) async {
    try {
      final prompt = '''
      Given the following story and list of 3D models, carefully determine which models are directly related to the topic, key elements, themes, characters, or objects in the story. Only select models that are clearly depicted in the story. Do not include any models that are irrelevant or unrelated to the story's content.

      Story: $story

      Available models: ${models.join(', ')}

      Return the names of the suitable models as a comma-separated list.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text;

      if (result == null || result.isEmpty) {
        throw Exception('No response from Gemini API');
      }

      final suitableModels = result.split(',').map((e) => e.trim()).toList();
      return suitableModels.where((model) => models.contains(model)).toList();

    } catch (e) {
      throw Exception('Failed to load suitable models: $e');
    }
  }
}