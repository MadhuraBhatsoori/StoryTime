import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import './visualize.dart';
import '../backend/result_explore_backend.dart';

class StoryScreenExplore extends StatefulWidget {
  final String story;
  final String topicName;
  final String userEmail;

  const StoryScreenExplore({
    Key? key,
    required this.story,
    required this.topicName,
    required this.userEmail,
  }) : super(key: key);

  @override
  StoryScreenExploreState createState() => StoryScreenExploreState();
}

class StoryScreenExploreState extends State<StoryScreenExplore> {
  late FlutterTts flutterTts;
  late BackendE backendE;  
  bool isPlaying = false;
  int currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    backendE = BackendE(); 
    initializeTts();
  }

  //initialize text to speech 
  void initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
  }

  void speak() async {
    try {
      String storyToSpeak = widget.story.substring(currentCharIndex);

      if (isPlaying) {
        await flutterTts.stop();
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      } else {
        await flutterTts.speak(storyToSpeak);
        if (mounted) {
          setState(() {
            isPlaying = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showDialog('Error during speech synthesis: $e');
      }
    }
  }

  void textToSpeech() {
    speak();
  }
 //share story 
  void shareStory() {
    Share.share(widget.story, subject: 'Check out this story!');
  }

  //get suitable models from Gemini 

  void visualizeStory() async {
    try {
      List<String> availableModels = await backendE.getAvailableModels();
      List<String> suitableModels = await backendE.getSuitableModels(widget.story, availableModels);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Visualize(
              title: 'Story Visualize',
              story: widget.story,
              availableModels: suitableModels,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showDialog('Failed to visualize story: $e');
      }
    }
  }

  void _showDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Explore Story', style: TextStyle(color: Colors.grey)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.story,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconContainer(
                      icon: Icons.share,
                      color: Colors.black,
                      onPressed: shareStory,
                    ),
                    _buildIconContainer(
                      icon: isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      onPressed: textToSpeech,
                    ),
                    _buildIconContainer(
                      icon: Icons.view_in_ar,
                      color: Colors.black,
                      onPressed: visualizeStory,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
    );
  }
}
