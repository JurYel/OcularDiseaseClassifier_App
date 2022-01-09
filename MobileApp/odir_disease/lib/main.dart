import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'prediction_history.dart';
import 'home.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OD Classifier',
      debugShowCheckedModeBanner: false,
      home: HomePage() ,
      theme: ThemeData.dark(),
      routes: <String, WidgetBuilder> {
        '/history' : (BuildContext context) =>  PredictionHistory(),
      }
    );
  }
}