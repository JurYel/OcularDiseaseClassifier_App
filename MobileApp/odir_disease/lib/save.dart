

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

class SavePrediction extends StatefulWidget {
  PickedFile? saveImage; 
  SavePrediction({Key? key, this.saveImage}) : super(key: key);


  @override
  _SavePredictionState createState() => _SavePredictionState();
}

class _SavePredictionState extends State<SavePrediction> {

  Future<void> showSaveDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Form(
              child: Column(
                children: [
                  Text('Save Prediction', style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, letterSpacing: 0.8
                  ),),
                  
                  SizedBox(height: 50.0, width: 50.0,child: Image.file(File(widget.saveImage!.path))),

                  TextFormField(decoration: InputDecoration(hintText: 'Enter Some Text'),)
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.pink,
                              padding:
                                  EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 2.0),
                            ),
                            onPressed: () {
                              showSaveDialog(context);
                            },
                            child: SizedBox(
                                width: 60.0,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(Icons.save_alt),
                                      Text('Save')
                            ])),
                          );
  }
}
