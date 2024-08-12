import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class Visualize extends StatefulWidget {
  final String title;
  final String story;
  final List<String> availableModels;

  const Visualize({
    super.key,
    required this.title,
    required this.story,
    required this.availableModels,
  });

  @override
  State<Visualize> createState() => _VisualizeState();
}

class _VisualizeState extends State<Visualize> {
  Map<String, Flutter3DController> controllers = {};
  Map<String, List<String>> modelAnimations = {};
  Map<String, String?> modelChosenAnimations = {};
  List<String> suitableModels = [];
  Map<String, Offset> modelPositions = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSuitableModels();
  }

  @override
  void didUpdateWidget(Visualize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableModels != oldWidget.availableModels) {
      fetchSuitableModels();
    }
  }
//get suitable models from gemini
  Future<void> fetchSuitableModels() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<String> models = await getSuitableModels(widget.story, widget.availableModels);

      if (models.isEmpty) {
        _showErrorDialog('No suitable models found for the story.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      setState(() {
        suitableModels = models;
        controllers = {};
        modelPositions = {};
        modelAnimations = {};
        modelChosenAnimations = {};

        for (var model in models) {
          controllers[model] = Flutter3DController();
          modelPositions[model] = Offset(50.0 * (models.indexOf(model) + 1), 50.0);
          modelAnimations[model] = [];
          modelChosenAnimations[model] = null;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching models: $e');
    }
  }

  //load animations embedded in 3d models

  Future<void> loadAnimationsForModel(String model) async {
    final controller = controllers[model];
    if (controller == null) return;

    try {
      setState(() {
        modelAnimations[model] = [];
      });

      List<String> availableAnimations = await controller.getAvailableAnimations();
      setState(() {
        modelAnimations[model] = availableAnimations;
      });
    } catch (e) {
      _showErrorDialog('Error loading animations: $e');
    }
  }
//show animation
  Future<void> showAnimations(String model) async {
    await loadAnimationsForModel(model);
    final animations = modelAnimations[model] ?? [];
    final chosenAnimation = await showPickerDialog(animations, modelChosenAnimations[model]);

    if (chosenAnimation != null) {
      controllers[model]?.playAnimation(animationName: chosenAnimation);
      setState(() {
        modelChosenAnimations[model] = chosenAnimation;
      });
    }
  }
//stop animation
  void stopAnimation(String model) {
    final controller = controllers[model];
    if (controller != null) {
      controller.pauseAnimation();
    }
  }

  Future<List<String>> getSuitableModels(String story, List<String> models) async {
    await Future.delayed(const Duration(milliseconds: 500));  
    return models;  
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.grey)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (suitableModels.isEmpty)
            const Center(child: Text('No suitable models available', style: TextStyle(fontSize: 18, color: Colors.red)))
          else
            Stack(
              children: [
                _ModelDragTarget(
                  suitableModels: suitableModels,
                  modelPositions: modelPositions,
                  controllers: controllers,
                  onModelDrop: (model, offset) {
                    setState(() {
                      modelPositions[model] = offset;
                    });
                  },
                  onModelPanUpdate: (model, delta) {
                    setState(() {
                      modelPositions[model] = Offset(
                        modelPositions[model]!.dx + delta.dx,
                        modelPositions[model]!.dy + delta.dy,
                      );
                    });
                  },
                  onModelTap: stopAnimation,
                  onModelDoubleTap: showAnimations,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _ModelList(
                    suitableModels: suitableModels,
                    controllers: controllers,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<String?> showPickerDialog(List<String> inputList, [String? chosenItem]) async {
    return await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 250,
          child: ListView.separated(
            itemCount: inputList.length,
            padding: const EdgeInsets.only(top: 16),
            itemBuilder: (ctx, index) {
              return InkWell(
                onTap: () {
                  Navigator.pop(context, inputList[index]);
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${index + 1}'),
                      Text(inputList[index]),
                      Icon(chosenItem == inputList[index]
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (ctx, index) {
              return const Divider(
                color: Colors.grey,
                thickness: 0.6,
                indent: 10,
                endIndent: 10,
              );
            },
          ),
        );
      },
    );
  }
}

//control 3d model actions

class _ModelDragTarget extends StatelessWidget {
  final List<String> suitableModels;
  final Map<String, Offset> modelPositions;
  final Map<String, Flutter3DController> controllers;
  final Function(String, Offset) onModelDrop;
  final Function(String, Offset) onModelPanUpdate;
  final Function(String) onModelTap;
  final Function(String) onModelDoubleTap;

  const _ModelDragTarget({
    required this.suitableModels,
    required this.modelPositions,
    required this.controllers,
    required this.onModelDrop,
    required this.onModelPanUpdate,
    required this.onModelTap,
    required this.onModelDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        onModelDrop(details.data, details.offset);
      },
      builder: (context, candidateData, rejectedData) {
        return suitableModels.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: suitableModels.map((model) {
                  return Positioned(
                    left: modelPositions[model]!.dx,
                    top: modelPositions[model]!.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        onModelPanUpdate(model, details.delta);
                      },
                      onTap: () => onModelTap(model),
                      onDoubleTap: () => onModelDoubleTap(model),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.height / 2,
                        child: Flutter3DViewer(
                          controller: controllers[model]!,
                          src: 'assets/$model',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
      },
    );
  }
}

class _ModelList extends StatelessWidget {
  final List<String> suitableModels;
  final Map<String, Flutter3DController> controllers;

  const _ModelList({
    required this.suitableModels,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Container(
        color: Colors.grey[200],
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suitableModels.map((model) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Draggable<String>(
                    data: model,
                    feedback: Material(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Flutter3DViewer(
                          controller: controllers[model]!,
                          src: 'assets/$model',
                        ),
                      ),
                    ),
                    childWhenDragging: SizedBox(
                      width: 100,
                      height: 100,
                      child: Container(
                        color: Colors.grey,
                        child: const Center(child: Text('Dragging...')),
                      ),
                    ),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Flutter3DViewer(
                        controller: controllers[model]!,
                        src: 'assets/$model',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
