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
  TextEditingController weightController = TextEditingController();
  int workoutCount;
  bool submitting;
  bool _isComposing = false;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
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
                return SafeArea(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView.builder(
                          itemCount: snap.data.documents.length,
                          itemBuilder: (BuildContext context, int index) {
                            final workout = snap.data.documents[index].data;
                            return ListTile(
                              title: Text(workout["name"]),
                              subtitle: Text(" ${workout["count"] ?? ""} "),
                              trailing: Text(
                                workout["createdAt"] == null
                                    ? ""
                                    : DateFormat.yMd().format(
                                        workout["createdAt"],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: workoutNameController,
                              decoration: InputDecoration.collapsed(
                                hintText: "Workout",
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType: TextInputType.numberWithOptions(),
                              decoration: InputDecoration.collapsed(
                                hintText: "Weight",
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
                            icon: Icon(Icons.send),
                            onPressed: _isComposing
                                ? () async {
                                    if (submitting == true) return;
                                    final String workoutName =
                                        workoutNameController.text;
                                    if (!workoutName.isNotEmpty) return;
                                    final double weight =
                                        double.parse(weightController.text);
                                    submitting = true;
                                    setState(() {});
                                    await Firestore.instance
                                        .collection("workouts")
                                        .add({
                                      "name": workoutName,
                                      "count": workoutCount,
                                      "weight": weight,
                                      "uid": user.uid,
                                      "createdAt": FieldValue.serverTimestamp(),
                                    });
                                    submitting = false;
                                    workoutCount = null;
                                    weightController.clear();
                                    workoutNameController.clear();
                                    setState(() {});
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
