import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' hide Image;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoUpload extends StatefulWidget {
  const PhotoUpload({Key? key}) : super(key: key);

  @override
  State<PhotoUpload> createState() => _PhotoUploadState();
}

class _PhotoUploadState extends State<PhotoUpload> {
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();
  Future<void>? running;
  File? file;

  Future<void> task() async {
    print("Task started");
    var img = await getImage();
    print("Image selected");
    if (img != null) {
      var result = await uploadPhoto(img);
      setState(() {
        file = result;
        running = null;
      });
      return;
    }
    print("No image selected");
    setState(() {
      running = null;
    });
  }

  Future<File?> getImage() async {
    XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      var croppedImage = await _cropper.cropImage(sourcePath: pickedImage.path);
      if (croppedImage != null) {
        return File(croppedImage.path);
      }
    }
    return null;
  }

  Future<File?> uploadPhoto(File image) async {
    final appDocDir = (await getTemporaryDirectory()).absolute.path;
    var fileName = "${const Uuid().v4()}.jpg";
    print("Processing photo");
    var imgBytes = await image.readAsBytes();
    print("readAsBytes completed");
    var original = decodeImage(imgBytes);
    print("decodeImage completed");
    if (original != null) {
      var finalVersion = original;
      if (original.width > 1500 || original.height > 1500) {
        if (original.width > original.height) {
          finalVersion = copyResize(original, width: 1500);
        } else {
          finalVersion = copyResize(original, height: 1500);
        }
        print("resize completed");
      }
      var finalFile = File("$appDocDir/$fileName");
      var jpg = encodeJpg(finalVersion, quality: 75);
      print("encodeJpg completed");
      var result = await finalFile.writeAsBytes(jpg);
      print("write completed");
      return result;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: running,
        builder: (context, snapshot) {
          List<Widget> children;
          if (snapshot.connectionState == ConnectionState.waiting) {
            children = <Widget>[const CircularProgressIndicator(
              strokeWidth: 20,
            )];
          } else {
            children = [
              file != null ? Image.file(file!) : const Text("No photo"),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      running = task();
                    });
                  },
                  child: const Text("Upload")),
            ];
          }

          return Column(
            children: children,
          );
        });
  }
}
