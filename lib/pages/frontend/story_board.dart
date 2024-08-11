import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoryBoard extends StatefulWidget {
  const StoryBoard({super.key});

  @override
  StoryBoardState createState() => StoryBoardState();
}

class StoryBoardState extends State<StoryBoard> {
  String? selectedTopicId;
  String? userEmail;

  @override
  void initState() {
    super.initState();
     
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
    } else {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],  
      appBar: AppBar(
        title: const Text('Story Board'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.grey,   
        iconTheme: const IconThemeData(color: Colors.grey),  
        actionsIconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('userEmail', isEqualTo: userEmail)   
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching stories.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No stories found.'));
          }


          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final topicName = doc['topicName'] ?? 'No topic';
              final story = doc['story'] ?? 'No story content';
              final topicId = doc.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(topicName),
                      onTap: () {
                        setState(() {
                          selectedTopicId = selectedTopicId == topicId ? null : topicId;
                        });
                      },
                    ),
                    if (selectedTopicId == topicId)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(story),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
