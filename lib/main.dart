import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muscle Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseUser user;
  TextEditingController workoutNameController = TextEditingController();
  int workoutCount;
  bool submitting;

  @override
  void initState() {
    signIn();
    super.initState();
  }

  void signIn() async {
    user = await FirebaseAuth.instance.currentUser();
    if (user == null) {
      user = await FirebaseAuth.instance.signInAnonymously();
    }
    setState(() {});
    print("user ${user.uid}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: user == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : StreamBuilder(
                stream: Firestore.instance
                    .collection("workouts")
                    .where("uid", isEqualTo: user.uid)
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder:
                    (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView.builder(
                          itemCount: snap.data.documents.length,
                          itemBuilder: (BuildContext context, int index) {
                            final workout = snap.data.documents[index].data;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(workout["name"]),
                                Text(
                                  workout["createdAt"] == null?"":DateFormat.yMd().format(
                                    workout["createdAt"],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: workoutNameController,
                              decoration: InputDecoration(
                                prefix: submitting != true
                                    ? Container()
                                    : CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          DropdownButton<int>(
                            value: workoutCount,
                            onChanged: (int val) {
                              setState(() {
                                workoutCount = val;
                              });
                            },
                            items: List.generate(12, (i) => i + 1)
                                .map<DropdownMenuItem<int>>((int count) {
                              return DropdownMenuItem<int>(
                                value: count,
                                child: Text("$count"),
                              );
                            }).toList(),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: workoutNameController.text.isNotEmpty
                                ? () async {
                                    final String workoutName =
                                        workoutNameController.text;
                                    submitting = true;
                                    setState(() {});
                                    await Firestore.instance
                                        .collection("workouts")
                                        .add({
                                      "name": workoutName,
                                      "uid": user.uid,
                                      "createdAt": FieldValue.serverTimestamp(),
                                    });
                                    submitting = false;
                                    workoutCount = null;
                                    workoutNameController.clear();
                                    setState(() {});
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
