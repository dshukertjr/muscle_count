import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macho Tracker',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseUser user;
  TextEditingController workoutNameController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController countController = TextEditingController();
  bool submitting;
  final dateStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    signIn();
    super.initState();
  }

  @override
    void dispose() {
      workoutNameController.dispose();
      weightController.dispose();
      countController.dispose();
      super.dispose();
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
                List<Widget> workoutList = [];
                Map prevWorkout;
                snap.data.documents.forEach((snap) {
                  final workout = snap.data;
                  if (prevWorkout != null) {
                    if (prevWorkout["createdAt"] != null) {
                      if (prevWorkout["createdAt"].day !=
                          workout["createdAt"].day) {
                        workoutList.add(Divider());
                        workoutList.add(Text(DateFormat.yMd().format(
                          workout["createdAt"] ?? DateTime.now(),
                        ),style: dateStyle,),
                        );
                      }
                    }
                  } else {
                    workoutList.add(Text(DateFormat.yMd().format(
                      workout["createdAt"] ?? DateTime.now(),
                    ),style: dateStyle),);
                  }
                  final Widget workoutTile = ListTile(
                    title: Text(
                        "${workout["name"]}"),
                    trailing: Text(workout["weight"] == "" ? "" : "${workout["weight"]}kg ×${workout["count"]}"),
                  );
                  workoutList.add(workoutTile);
                  prevWorkout = workout;
                });
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(children: workoutList),
                    ),
                    Container(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                      child: Row(
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
                                hintText: "kg",
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: countController,
                              keyboardType: TextInputType.numberWithOptions(),
                              decoration: InputDecoration.collapsed(
                                hintText: "Sets",
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () async {
                              if (submitting == true) return;
                              final String workoutName =
                                  workoutNameController.text;
                              if (!workoutName.isNotEmpty) return;
                              submitting = true;
                              await Firestore.instance
                                  .collection("workouts")
                                  .add({
                                "name": workoutName,
                                "count": countController.text,
                                "weight": weightController.text,
                                "uid": user.uid,
                                "createdAt": FieldValue.serverTimestamp(),
                              });
                              submitting = false;
                              countController.clear();
                              weightController.clear();
                              workoutNameController.clear();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
