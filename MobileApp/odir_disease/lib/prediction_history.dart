import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';

import 'package:share_files_and_screenshot_widgets/share_files_and_screenshot_widgets.dart';

import 'package:image/image.dart' as img;

import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart';




class PredictionHistory extends StatefulWidget {
  const PredictionHistory({Key? key, this.savedPreds}) : super(key: key);

  final List<Saved>? savedPreds;

  @override
  _PredictionHistoryState createState() => _PredictionHistoryState();
}

class _PredictionHistoryState extends State<PredictionHistory> {

  getDirectory() async {
    Directory tempDir = await getTemporaryDirectory();

    return tempDir;
  }  
  

  Widget _buildList(List<Saved>? preds) {
    return ListView.builder(
        itemCount: preds!.length,
        itemBuilder: (context, index) {
          if (preds.length == null) {}

          if (index.isOdd) return Divider();

          return _buildRow(Image.file(preds[index].image), preds[index].name,
              preds[index].pred, preds[index].conf);
        });
  }

  Widget _buildRow(Image image, String name, String pred, String conf) {
    var temp = getDirectory();

    

    return ListTile(
      leading: image,
      title: Text('${name}'),
      subtitle: Text('${pred}, ${conf}%'),
      // trailing: IconButton(
      //   onPressed: () async {
      //    Share.shareFiles([], subject: 'Eye Case Prediction', text: 'This is an eye case prediction of ${pred}, with a confidence of ${conf}' );
      //   },
      //   icon: Icon(Icons.ios_share),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan[800],
        title: Text(
          'Saved Predictions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _buildList(widget.savedPreds),
    );
  }
}
