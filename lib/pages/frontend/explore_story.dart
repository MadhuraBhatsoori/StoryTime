import 'package:flutter/material.dart';
import '../../components/my_button.dart';
import '../../components/my_textfield.dart';
import '../backend/story_exploration.dart';
import 'result_explore.dart'; 

class ExploreStory extends StatefulWidget {
  final String userEmail;

  const ExploreStory({Key? key, required this.userEmail}) : super(key: key);

  @override
  ExploreStoryState createState() => ExploreStoryState();
}

class ExploreStoryState extends State<ExploreStory> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController sliderController = TextEditingController();
  double _sliderValue = 10;

  @override
  void initState() {
    super.initState();
    sliderController.text = _sliderValue.toStringAsFixed(0);
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> exploreStory() async {
    String topic = topicController.text;


    int countWords(String text) {
  return text.trim().split(RegExp(r'\s+')).length;
}

 
     int wordCount = countWords(topic);

     if (wordCount < 100 || wordCount > 1000) {  
      showErrorDialog('Story is too short or too long.');
      return;
     }

    if (_sliderValue == 0) {
      showErrorDialog('Duration cannot be 0.');
      return;
    }

    late CreateStorySummarize backend;

    backend = CreateStorySummarize();

    try {
      final generatedStory = await backend.generateStory(
        topic: topic,
        sliderValue: _sliderValue,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryScreenExplore(
            story: generatedStory,
            topicName: topic,
            userEmail: widget.userEmail,
          ),
        ),
      );
    } catch (e) {
      String errorStory;
      if (e.toString().contains('safety reasons')) {
        errorStory =
            'The generated story was blocked due to safety reasons. Please try again with a different topic.';
      } else {
        errorStory = 'Error generating or translating story: $e';
      }

      if (!mounted) return; 

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryScreenExplore(
            story: errorStory,
            topicName: topic,
            userEmail: widget.userEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: SizedBox(
                      width: 500,
                      height: 160,
                      child: MyTextField(
                        controller: topicController,
                        hintText: 'Enter story here',
                        obscureText: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          Text(
                            'Duration of story: ${_sliderValue.toStringAsFixed(0)} mins',
                          ),
                          Slider(
                            value: _sliderValue,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: _sliderValue.round().toString(),
                            onChanged: (double value) {
                              setState(() {
                                _sliderValue = value;
                                sliderController.text = value.toStringAsFixed(0);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: MyButton(
                      onTap: () {
                        exploreStory();
                      },
                      label: "Explore Story",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
