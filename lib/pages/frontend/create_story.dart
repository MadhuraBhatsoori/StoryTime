import 'package:flutter/material.dart';
import '../../components/my_button.dart';
import '../../components/my_textfield.dart';
import '../backend/safety.dart';
import '../backend/story_generation.dart';
import 'results.dart';

class CreateStory extends StatefulWidget {
  final String userEmail;

  const CreateStory({Key? key, required this.userEmail}) : super(key: key);

  @override
  CreateStoryState createState() => CreateStoryState();
}

class CreateStoryState extends State<CreateStory> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController themeController = TextEditingController();
  final TextEditingController sliderController = TextEditingController();

  // Custom value
  double _sliderValue = 10;
  String selectedAudience = '5 years old';

  // Age options
  final List<String> audienceOptions = [
    '4 years old', '5 years old', '6 years old', '7 years old', '8 years old', '9 years old', '10 years old'
  ];

  late CreateStoryBackend backend;

  @override
  void initState() {
    super.initState();
    backend = CreateStoryBackend();
    sliderController.text = _sliderValue.toStringAsFixed(0);
  }

  void showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  Future<void> createAndNavigateToStory() async {
    String topic = topicController.text;
    String audience = selectedAudience;
    String extra = themeController.text;

    if (_sliderValue == 0) {
      showErrorDialog('Duration cannot be 0 to generate a story.');
      return;
    }

    if (topic.length <= 2 || topic.length > 100) {
      showErrorDialog('Story topic is either too short or too long.');
      return;
    }

    if (extra.length > 20) {
      showErrorDialog('Theme is too long.');
      return;
    }

    bool isSuitable = await moderateForChildren(topic, extra);
    if (!isSuitable) {
      showErrorDialog('Topic or theme not suitable for children.');
      return;
    }

    try {
      final generatedStory = await backend.generateStory(
        topic: topic,
        audience: audience,
        extra: extra,
        sliderValue: _sliderValue,
      );

      if (!mounted) return;  

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryScreen(
            story: generatedStory,
            topicName: topic,
            audience: audience,
            userEmail: widget.userEmail,
          ),
        ),
      );
    } catch (e) {
      String errorStory;
      if (e.toString().contains('safety reasons')) {
        errorStory = 'The generated story was blocked due to safety reasons. Try with a different topic.';
      } else {
        errorStory = 'Error generating or translating story: $e';
      }

      if (mounted) {  
        showErrorDialog(errorStory);
      }
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: 300.0,
                      child: TextField(
                        controller: topicController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your topic',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: 300.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),  
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: selectedAudience,
                          isExpanded: true,
                          items: audienceOptions.map((String age) {
                            return DropdownMenuItem<String>(
                              value: age,
                              child: Text(age),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedAudience = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: SizedBox(
                      width: 300.0,
                      child: MyTextField(
                        controller: themeController,
                        hintText: 'Integrate themes of',
                        obscureText: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: 300.0,
                      child: Column(
                        children: [
                          Text('Duration of story: ${_sliderValue.toStringAsFixed(0)} mins'),
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
                      onTap: createAndNavigateToStory,
                      label: "Create Story",
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
