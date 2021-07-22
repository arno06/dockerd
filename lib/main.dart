import 'dart:convert';

import 'package:dockerd/dockerd/utils/CommandHelper.dart';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:dockerd/dockerd/widgets/Containers.dart';
import 'package:dockerd/dockerd/widgets/Home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(Platform.isWindows || Platform.isMacOS || Platform.isLinux){
    final s = ConfigStorage();
    await s.init();
    setWindowTitle('Dockerd');
    final width = 900.0;
    final height = 700.0;
    setWindowMinSize(Size(width, height));
    setWindowMaxSize(Size(width, height));
    getWindowInfo().then((window) {
      if (window.screen != null) {
        final screenFrame = window.screen!.visibleFrame;
        final left = ((screenFrame.width - width) / 2).roundToDouble();
        final top = ((screenFrame.height - height) / 2).roundToDouble();
        final frame = Rect.fromLTWH(left, top, width, height);
        setWindowFrame(frame);
      }
    });
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Docker Digital Tool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}