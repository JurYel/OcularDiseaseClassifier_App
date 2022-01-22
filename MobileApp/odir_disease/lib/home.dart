import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odir_disease/prediction_history.dart';
import 'package:share_files_and_screenshot_widgets/share_files_and_screenshot_widgets.dart';
import 'dart:io';
import 'dart:async';
import 'package:tflite/tflite.dart';
import 'dart:developer';

import 'package:image/image.dart' as img;

import 'package:dotted_border/dotted_border.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_fonts/google_fonts.dart';

import 'save.dart';

import 'package:share_plus/share_plus.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'package:image_cropper/image_cropper.dart';


class Saved {
  late File image;
  late String name;

  late String pred;
  late String conf;

  Saved(File image, String name, String pred, String conf) {
    this.image = image;
    this.name = name;
    this.pred = pred;
    this.conf = conf;
  }
}

List<Saved> _saved_preds = [];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PickedFile? _image;
  var _imageArray;
  bool _loading = false;
  bool _share = false;
  bool _save = false;
  List? _outputs;
  GlobalKey globalKey = GlobalKey();

  var _learnMore;

  final ImagePicker _picker = ImagePicker();

  String? _predictedLabel;
  var _predictedConfidence;

  //Instance of screenshotcontroller for screenshotting widget for sharing

  final String assetName = 'assets/eye.svg';
  final Widget svgIcon = SvgPicture.asset(
    'assets/eye.svg',
    color: Colors.grey,
  );

  SavePrediction save = SavePrediction(
    saveImage: null,
  );

  void initState() {
    super.initState();
    _loading = true;

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

//Load the Tflite model
  loadModel() async {
    debugPrint('Loading Model...');
    await Tflite.loadModel(
      model: "assets/odir_model_0.91.tflite",
      labels: "assets/labels.txt",
    );
    debugPrint('Model Loaded!');
  }

  predictPostRequest(imagePath) async {
    Response response;

    try {
      String filename = _image!.path.split("/").last;
      print(filename);
      FormData formData = FormData.fromMap({
        "file": 
        await MultipartFile.fromFile(_image!.path, filename: filename, contentType: MediaType('image', 'png')),
        "type" : "image/png"
      });
      response = await Dio().post('http://10.0.2.2:8000/predict', data: formData, options: Options(headers: {
        "accept":"application/json", "Content-Type":"multipart/form-data"
      }));

      
      print(response);
      print(response.data["label"]);

        setState(() {
        _outputs = [1,2,3];
        _loading = false;
        _predictedLabel = response.data["label"];
        _predictedConfidence = response.data["confidence"];
      });


    } catch (e) {
      print(e);

     // return e as List;
    }


   // return response.data() as List;
  }


  //Image picker
  Future pickImage() async {
    var image = await _picker.getImage(source: ImageSource.gallery);
    if (image == null) return null;
    save.saveImage = image;
    setState(() {
      _loading = true;
      _image = image;
    });
    debugPrint('Classifying...');
    var cropped = cropFile(image);
    classifyImage(cropped);
  }


  classifyImage(image) async {
    await predictPostRequest(image.path);

    print('OUTPUT: ');
    print(_predictedLabel);
    checkPrediction();
    print(_learnMore);
  }

  cropFile(image) async {
  File? croppedFile = await ImageCropper.cropImage(
      sourcePath: image.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      androidUiSettings: AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      iosUiSettings: IOSUiSettings(
        minimumAspectRatio: 1.0,
      )
    );

    return croppedFile;
  }
  
  

  Future<void> showSaveDialog(
      BuildContext context, String predText, String confText) async {
    final detailsController = TextEditingController();

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Form(
              child: SizedBox(
                height: 270.0,
                child: Column(
                  children: [
                    Text(
                      'Save Prediction',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, letterSpacing: 0.8),
                    ),
                    SizedBox(height: 20.0),
                    SizedBox(
                        height: 80.0,
                        width: 80.0,
                        child: Image.file(File(_image!.path))),
                    SizedBox(height: 20.0),
                    Text(
                      '${predText}',
                      style: GoogleFonts.poppins(fontSize: 17),
                    ),
                    SizedBox(height: 3.0),
                    Text(
                      '${confText}%',
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: detailsController,
                      decoration: InputDecoration(hintText: 'Enter details...'),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp("[a-zA-Z0-9- _]{0,30}")),
                      ], 
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('Save'),
                onPressed: () {
                  print('PRESSING SAVE');

                  var detailsText;

                  if (detailsController.text == '') {
                    detailsText = 'Saved Prediction';
                  } else {
                    detailsText = detailsController.text;
                  }

                  Saved newSaved = Saved(
                      File(_image!.path), detailsText, predText, confText);

                  print('BRUH BRUH: ${newSaved.name} ${newSaved.pred}');

                  _saved_preds.add(newSaved);

                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  //Screenshot widget
  void shareScreenshot() async {
    ShareFilesAndScreenshotWidgets().shareScreenshot(
        globalKey, 800, "Eye Case Prediction", "Prediction.png", "image/png",
        text:
            'This case is a ${_predictedLabel!} with a confidence of ${(_predictedConfidence!).round()}');
  }

  saveScreenshotToGallery() async {
    Image? saveImage =
        await ShareFilesAndScreenshotWidgets().takeScreenshot(globalKey, 800);
  }

  checkPrediction() {
    switch (_predictedLabel) {
      case 'Cataract':
        _learnMore =
            'https://www.mayoclinic.org/diseases-conditions/cataracts/symptoms-causes/syc-20353790';
        break;
      case 'Glaucoma':
        _learnMore =
            'https://www.mayoclinic.org/diseases-conditions/glaucoma/symptoms-causes/syc-20372839';
        break;
      case 'Myopia':
        _learnMore =
            'https://www.mayoclinic.org/diseases-conditions/nearsightedness/symptoms-causes/syc-20375556';
        break;

      case 'Normal':
        _learnMore = null;
        break;

      default:
    }
  }

  /* Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    print('BRUUUUUUUUUUUUUUUUUUH');
    print(convertedBytes.buffer.asUint8List());
    return convertedBytes.buffer.asUint8List();
  }

  @override
  void dispose() {
    super.dispose();
  } */

  //SCAFFOLD MAIN MENU
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        //shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text('OCULAR DISEASE CLASSIFICATION',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600, letterSpacing: 1.1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      
      ),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                color:Colors.cyan[800]
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: RepaintBoundary(
                key: globalKey,
                child: Column(

                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20,),
                      Container(
                        margin: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                        padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 20.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.grey,
                                style: BorderStyle.solid,
                                width: 2.0)),
                        child: _image == null
                            ? Container(
                                padding: const EdgeInsets.all(20.0),
                                child: LimitedBox(
                                  child: svgIcon,
                                  maxWidth: 150.0,
                                  maxHeight: 150.0,
                                ),
                              )
                            : SizedBox(
                                height: 300.0,
                                width: 300.0,
                                child: Image.file(File(_image!.path))),
                      ),
                      SizedBox(height: 2),
                      _outputs != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 20.0,
                                ),
                                Text(
                                  'Prediction: ${_predictedLabel}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  'Confidence: ${(_predictedConfidence).toStringAsFixed(3)}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                ),
                              ],
                            )
                          : _image != null
                              ? Container(
                                  padding: EdgeInsets.all(40.0),
                                  child: const CircularProgressIndicator(
                                    color: Colors.cyan,
                                  ),
                                )
                              : Container(),
                      _image == null
                          ? Container()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.cyan[800],
                                padding:
                                    EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 2.0),
                              ),
                              onPressed: () {
                                showSaveDialog(
                                    context,
                                    _predictedLabel.toString(),
                                    (_predictedConfidence)
                                        .toStringAsFixed(3));
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
                            ),
                      SizedBox(height: 30.0),
                      _outputs != null
                          ? InkWell(
                              child: _predictedLabel != 'normal' 
                                  ? Text(
                                      'Learn more about ${_predictedLabel}',
                                      style: TextStyle(color: Colors.blue[400]),
                                    )
                                  : Container(),
                              onTap: () => launch(_learnMore))
                          : Container(),
                       Container(
                              margin:
                                  EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
                              height: 50.0,
                              child: RaisedButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    side: BorderSide(
                                        color: Color.fromRGBO(0, 160, 227, 1))),
                                onPressed: openGallery,
                                padding: EdgeInsets.all(10.0),
                                color: Color.fromRGBO(20, 66, 90, 1),
                                textColor: Colors.white,
                                child: Text("UPLOAD IMAGE",
                                    style: GoogleFonts.lato(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.7)),
                              ),
                            )
                       ,

                    ]),
              ),
            ),
      // floatingActionButton: SizedBox(
      //   height: 70.0,
      //   width: 70.0,
      //   child: FittedBox(
      //     child: FloatingActionButton(
      //       tooltip: 'Open Image',
      //       onPressed: openGallery,
      //       backgroundColor: ,
      //       child: Icon(Icons.image_outlined),
      //     ),
      //   ),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 5.0,
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Prediction History',
                icon: Icon(Icons.list_alt_outlined),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PredictionHistory(
                                savedPreds: _saved_preds,
                              )));
                },
              ),
              IconButton(
                tooltip: 'Share Prediction',
                icon: Icon(Icons.ios_share),
                onPressed: _outputs != null ? shareScreenshot : null,
              ),
            ],
          )),
    );
  }

  // //dialogBox method
  // Future<void> _optiondialogbox() {
  //   return showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           backgroundColor: Colors.pink,
  //           content: SingleChildScrollView(
  //             child: ListBody(
  //               children: <Widget>[
  //                 GestureDetector(
  //                   child: Text(
  //                     "Take a picture",
  //                     style: TextStyle(color: Colors.white, fontSize: 20.0),
  //                   ),
  //                   onTap: openCamera,
  //                 ),
  //                 Padding(padding: EdgeInsets.all(10.0)),
  //                 GestureDetector(
  //                   child: Text(
  //                     "Select from gallery",
  //                     style: TextStyle(color: Colors.white, fontSize: 20.0),
  //                   ),
  //                   onTap: openGallery,
  //                 )
  //               ],
  //             ),
  //           ),
  //         );
  //       });
  // }

  Future openCamera() async {
    var image = await _picker.getImage(source: ImageSource.camera);

    setState(() {
      _image = image;
    });
  }

  //camera method
  Future openGallery() async {
    var picture = await _picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = picture;
    });

    // print('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    // File imageArrayFile = File(picture!.path);
    // print('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB');
    // img.Image imageArrayConvert = await convertFileToImage(imageArrayFile);

    // var resized = img.copyResize(imageArrayConvert, width: 256);

    // print('CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC');

    // _imageArray = imageToByteListUint8(resized, 256);

    // print('DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');

    // var imageArrayImage = Image.memory(_imageArray);

    classifyImage(picture);

    checkPrediction();
  }
}

/* Future<img.Image> convertFileToImage(File picture) async {
  List<int> imageBase64 = picture.readAsBytesSync();
  String imageAsString = base64Encode(imageBase64);
  Uint8List uint8list = base64.decode(imageAsString);
  img.Image image = img.Image.fromBytes(256, 256, uint8list);
  return image;
}
 */