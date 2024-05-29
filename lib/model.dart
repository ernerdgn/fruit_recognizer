import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cam_app_v02/main.dart';
import 'package:tflite/tflite.dart';

class Model extends StatefulWidget {
  const Model({Key? key}) : super(key: key);

  @override
  State<Model> createState() => _ModelState();
}

class _ModelState extends State<Model> {

  late File _image;
  bool selImage = false;
  List result = [];
  String output = '';
  String fruit_info_output = '';
  CameraController? cameraController;
  CameraImage? cameraImage;
  List<CameraDescription>? cameras;

  var fruit_info_dict = const <String, String>{
    "apple" : "ELMA",
    "lemon" : "LİMON",
    "banana" : "MUZ",
    "carrot" : "HAVUÇ",
    //can be added more
  };

  @override
  void initState()
  {
    super.initState();
    loadModel().then((value){
      setState(() {

      });
    });
    _getCameras();
    //loadCamera();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Tflite.close();
  }

  @override
  Widget build(BuildContext) {
    return SafeArea(child: Scaffold(
      appBar: AppBar(
        title: Text("Fruit Recognizer"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              width: MediaQuery.of(context).size.width,
              child: (cameraController!.value.isInitialized)?AspectRatio(aspectRatio: cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!)):Container(),
              ),
          ),
          Text(output, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
          Text(fruit_info_output, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
          // Expanded(child: (selImage)?Image.file(_image):Container()),
          // const SizedBox(
          //   height: 30,
          // ),
          // //(result.isEmpty)?Container():Text(result.toString()), //show all predict result
          // (result.isEmpty)?Container():Text(result[0]['label'], style: TextStyle(
          //   fontWeight: FontWeight.bold, fontSize: 20
          // ),),
          // InkWell(
          //   onTap: (){
          //     chooseImage();
          //   },
          //   child: Container(
          //     margin: EdgeInsets.only(top: 20),
          //     padding: const EdgeInsets.all(10),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(10),
          //       color: Colors.orangeAccent,
          //     ),
          //     child: Text("Select Image From Gallery", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
          //   )
          // )
        ],
      )
    ));
  }

  Future<void> chooseImage()
  async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image!.path != null)
      {
        setState(() {
          selImage = true;
          _image = File(image.path);
        });
      }
    predictImage(_image);
  }

  loadModel() async
  {
    await Tflite.loadModel(model: 'assets/model.tflite', labels: 'assets/labels.txt');
  }

  predictImage(File image) async
  {
    var output = await Tflite.runModelOnImage(path: image.path, numResults: 5, threshold: 0.5, imageMean: 127.5, imageStd: 127.5);
    setState(() {
      result = output!;
    });

    print("result is : $result");
  }

  loadCamera() {
    // TODO: check "camera" error
    //_getCameras();
    cameraController = CameraController((cameras![0]), ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if(!mounted)
        {
          return;
        }
      else
        {
          setState(() {
            cameraController!.startImageStream((image) {
              cameraImage = image;
              runModel();
            });
          });
        }
    });
  }

  Future<void> _getCameras() async {
    final cameras = await availableCameras();
    setState(() {
      this.cameras = cameras;
    });

    loadCamera();
  }

  runModel() async {
    if(cameraImage!=null)
      {
        var predictions = await Tflite.runModelOnFrame(bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 5,
          threshold: 0.6,
          asynch: true
        );
        for (var element in predictions!)
          {
            setState(() {
              output = element["label"];  // + "\n" + fruit_info[element["label"]];
              fruit_info_output = fruit_info_dict[element["label"]]!;
            });
          }
      }
  }
}