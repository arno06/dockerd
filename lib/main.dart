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

class DockerDigitHome extends StatefulWidget {

  DockerDigitHome({Key? key}) : super(key: key);

  @override
  _DockerDigitHomeState createState() => _DockerDigitHomeState();
}

class _DockerDigitHomeState extends State<DockerDigitHome> {

  bool _opened = false;

  String _logData = "";

  void _log(List<String> parameters, {String? command}){
    if(command == null){
      command = ConfigStorage().dockerCommand;
    }
    setState(() {
      var log = DateTime.now().toString()+"\t"+(command!)+" "+parameters.join(" ");
      _logData += log+"\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    var tabs = [];
    return Scaffold(
      body: Container(
          decoration:BoxDecoration(color:Colors.black12),
          child:Stack(
            children:[
              AnimatedPositioned(
                duration:Duration(milliseconds: 350),
                left:!_opened?MediaQuery.of(context).size.width+10:MediaQuery.of(context).size.width-400,
                child: Container(
                  width:400,
                  height:MediaQuery.of(context).size.height,
                  decoration:BoxDecoration(
                    color:Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color:Colors.black.withAlpha(55),
                          spreadRadius: 5.0,
                          blurRadius: 5.0,
                          offset: Offset(0, 0)
                      )
                    ],
                  ),
                  padding:EdgeInsets.all(10.0),
                  child: Column(
                      children:[
                        Opacity(
                          opacity: 0,
                          child: LinearProgressIndicator(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Text('container name'),
                                Text('image name', style:TextStyle(fontSize:12.0, color:Colors.grey))
                              ]
                            ),
                            IconButton(onPressed: (){
                              setState((){
                                _opened = !_opened;
                              });
                            }, icon: Icon(Icons.close))
                          ],
                        ),
                        Container(height:10),
                        TextButton(
                          onPressed:(){
                            launch('container url');
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.link),
                              Container(width:10),
                              Text('container url'),
                            ],
                        ),)
                      ]
                  ),
                ),
              ),
            ]
          )
      ),
    );

  }

  Widget cliWidget(){
    return Positioned(
        bottom: 0,
        left:0,
        child: Container(
          height:240,
          child: Column(
            children: [
              Container(
                  padding:EdgeInsets.all(10.0),
                  decoration:BoxDecoration(
                      color: Colors.black87
                  ),
                  height:200,
                  width:900,
                  child: SingleChildScrollView(
                      child: Text(
                        _logData,
                        style: TextStyle(color: Colors.white),
                      )
                  )
              ),
              Container(
                width:900,
                height:40,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                      ),
                    ),
                    TextButton(onPressed: (){

                      Process.run('bash', ['-c', TextEditingController().text], runInShell: true).then((ProcessResult results){
                        if(results.exitCode != 0){
                          _log([], command:'Error : '+results.stderr);
                        }else{
                          _log([], command:' '+results.stdout);
                        }
                        return results;
                      });
                    }, child: Text("run")),
                  ],
                ),
              )
            ],
          ),
        )
    );
  }

  void inspectSelectedContainer(){
    var _selectedContainer = DockerContainer(id: '', name: '', image: '', created: '', status: '');
    if(_selectedContainer.inspection != null){
      return;
    }
    List<String> params = ["inspect", _selectedContainer.id];
    runDockerCommand(params).then((ProcessResult results){
      List<String> lines = results.stdout.split('\n');
      List<dynamic> inspections = jsonDecode(lines.join('\n'));
      _selectedContainer.inspection = inspections.elementAt(0);
      List<dynamic> envs = _selectedContainer.inspection?['Config']?['Env'];
      envs.forEach((element) {
        if(element.indexOf('VIRTUAL_HOST=') > -1){
          _selectedContainer.url = element.replaceFirst('VIRTUAL_HOST=', 'http://');
        }
        if(element.indexOf('LETSENCRYPT_HOST=') > -1){
          _selectedContainer.url = element.replaceFirst('LETSENCRYPT_HOST=', 'https://');
        }
      });
      setState(() {});
    });
  }

}