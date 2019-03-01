import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseUser user;
  TextEditingController workoutNameController = TextEditingController();

  @override
  void initState() {
    signIn();
    super.initState();
  }

  void signIn() async {
    user = await FirebaseAuth.instance.currentUser();
    if (user == null) {
      user = await FirebaseAuth.instance.signInAnonymously();
      setState(() {});
    }
    print("user ${user.uid}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Muscle Counter"),
      ),
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
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snap) {
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
                            return Text("${workout["name"]} ${workout["createdAt"]}");
                          },
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                              controller: workoutNameController,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              final String workoutName =
                                  workoutNameController.text;
                              Firestore.instance.collection("workouts").add({
                                "name": workoutName,
                                "uid": user.uid,
                                "createdAt": FieldValue.serverTimestamp(),
                              });
                            },
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
