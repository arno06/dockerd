import 'dart:io';

import 'package:dockerd/dockerd/utils/CommandHelper.dart';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:dockerd/dockerd/widgets/Console.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WorkingDirectory extends StatefulWidget {
  const WorkingDirectory({Key? key}) : super(key: key);

  @override
  _WorkingDirectoryState createState() => _WorkingDirectoryState();
}

class _WorkingDirectoryState extends State<WorkingDirectory> {
  bool _recycling = false;
  late TextEditingController _repositoryTEC;
  late TextEditingController _nameTEC;
  late TextEditingController _tagTEC;
  List<List<TextEditingController>> _envsTEC = [];
  ConfigStorage session = ConfigStorage();
  Color killColor = Colors.black26;
  Color rmColor = Colors.black26;
  Color rmiColor = Colors.black26;
  Color buildColor = Colors.black26;
  Color runColor = Colors.black26;

  @override
  void initState() {
    super.initState();
    _repositoryTEC = new TextEditingController();
    _nameTEC = new TextEditingController();
    _tagTEC = new TextEditingController();

    if(session.workingDirectory.isNotEmpty){
      if(session.imageRepository.isNotEmpty || session.imageTag.isNotEmpty){
        _repositoryTEC.text = session.imageRepository;
        _nameTEC.text = session.containerName;
        _tagTEC.text = session.imageTag;
      }else{
        _extractInfoFromGit(session.workingDirectory);
      }
    }
    var envs = session.dockerEnvironmentsVars;
    session.containerEnvs.forEach((key, value) {
      envs[key] = value;
    });
    envs.forEach((key, value) {
      _envsTEC.add([
        TextEditingController(text:key),
        TextEditingController(text:value)
      ]);
    });
  }

  @override
  void dispose() {
    _repositoryTEC.dispose();
    _nameTEC.dispose();
    _tagTEC.dispose();
    _envsTEC.forEach((element) {
      element[0].dispose();
      element[1].dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    int i = 0;
    List<Widget> envVars = [];
    for(var i = 0, max = _envsTEC.length; i<max; i++){
      var element = _envsTEC[i];
      envVars.add(
          Container(
            padding:EdgeInsets.only(bottom:5.0),
            child: Row(
              children: [
                WDInput(controller: element[0], width:200.0),
                Text("="),
                WDInput(controller: element[1]),
                TextButton(onPressed: (){
                  setState(() {
                    _envsTEC.removeAt(i);
                  });
                }, child: Icon(Icons.remove, size:11.0, color: Colors.black87,)),
              ],
            ),
          )
      );
    }

    return Column(
      children: [
        Opacity(
            opacity: _recycling?1:0,
            child:LinearProgressIndicator()
        ),
        Expanded(
          child: Container(
            decoration:BoxDecoration(color:Colors.white10),
            width: double.infinity,
            padding:EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('Kill', style: TextStyle(fontSize: 12.0, color:killColor),),
                          Text('Container', style: TextStyle(fontSize: 11.0, color:killColor),)
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_right, color:Colors.black26),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Remove', style: TextStyle(fontSize: 12.0, color:rmColor),),
                          Text('Container', style: TextStyle(fontSize: 11.0, color:rmColor),)
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_right, color:Colors.black26),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Remove', style: TextStyle(fontSize: 12.0, color:rmiColor),),
                          Text('Image', style: TextStyle(fontSize: 11.0, color:rmiColor),)
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_right, color:Colors.black26),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Build', style: TextStyle(fontSize: 12.0, color:buildColor),),
                          Text('Image', style: TextStyle(fontSize: 11.0, color:buildColor),)
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_right, color:Colors.black26),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Run', style: TextStyle(fontSize: 12.0, color:runColor),),
                          Text('Container', style: TextStyle(fontSize: 11.0, color:runColor),)
                        ],
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                          onPressed: _recycling?null:(){
                            recyclingHandler();
                          },
                          child: Container(
                            width:150,
                            padding:EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.autorenew),
                                Text('Recycler'),
                              ],
                            ),
                          )
                      ),
                    ),
                  ],
                ),
                Container(
                  height:10.0
                ),
                Expanded(child: ListView(
                  children: [
                    projectTitle('Dossier de travail'),
                    Container(
                      width: double.infinity,
                      decoration:BoxDecoration(color:Colors.white),
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                                padding:EdgeInsets.all(5.0),
                                decoration:BoxDecoration(
                                    color:Colors.white,
                                    border: Border(
                                        bottom:BorderSide()
                                    )
                                ),
                                width: double.infinity,
                                child: Text(session.workingDirectory.isEmpty?'Choisir un dossier':session.workingDirectory),
                              )
                          ),
                          IconButton(onPressed: ()=>_getDirectoryPath(context), icon: Icon(Icons.folder_open, color:Colors.amber)),
                        ],
                      ),
                    ),
                    Container(height: 10.0,),
                    projectTitle('Image'),
                    projectInput('Repository', _repositoryTEC),
                    projectInput('Tag', _tagTEC),
                    Container(height: 10.0,),
                    projectTitle('Conteneur'),
                    projectInput('Nom', _nameTEC),
                    Container(
                      decoration:BoxDecoration(color:Colors.white),
                      padding:EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Variable d\'environnements :', style:TextStyle(color:Colors.black38, fontSize:12.0)),
                              Spacer(),
                              TextButton(onPressed: (){
                                setState(() {
                                  _envsTEC.add([
                                    TextEditingController(),
                                    TextEditingController()
                                  ]);
                                });
                              }, child: Icon(Icons.add, size:11.0, color: Colors.black87,)),
                            ],
                          ),
                          Container(height:10),
                          ...envVars
                        ],
                      ),
                    )
                  ],
                ),
                )
              ],
            ),
          ),
        ),
        Console()
      ],
    );
  }


  void recyclingHandler(){
    Map<String, String> containerEnv = {};
    _envsTEC.forEach((element) {
      containerEnv[element[0].text] = element[1].text;
    });
    if(containerEnv.containsKey('VIRTUAL_HOST') && containerEnv['VIRTUAL_HOST']!.contains('{value}')){
      session.log(data:'Valeur incorrecte pour la variable d\'environnement "VIRTUAL_HOST"');
      return;
    }
    session.containerEnvs = containerEnv;
    session.imageRepository = _repositoryTEC.text;
    session.imageTag = _tagTEC.text;
    session.containerName = _nameTEC.text;
    var image = _repositoryTEC.text+':'+_tagTEC.text;
    var container = _nameTEC.text;
    setState(() {
      _recycling = true;
      killColor = Colors.blueAccent;
    });
    runDockerCommand(['kill', container]).then((value){
      var hasError = value.exitCode != 0;
      setState((){
        killColor = hasError?Colors.red:Colors.green;
        rmColor = Colors.blueAccent;
      });
      runDockerCommand(['rm', container, '--force']).then((value){
        var hasError = value.exitCode != 0;
        setState((){
          rmColor = hasError?Colors.red:Colors.green;
          rmiColor = Colors.blueAccent;
        });
        runDockerCommand(['rmi', image, '--force']).then((value){
          var hasError = value.exitCode != 0;
          setState((){
            rmiColor = hasError?Colors.red:Colors.green;
            buildColor = Colors.blueAccent;
          });
          runDockerCommand(['build', '-t', image, session.workingDirectory]).then((value){
            var hasError = value.exitCode != 0;
            setState((){
              buildColor = hasError?Colors.red:Colors.green;
              runColor = Colors.blueAccent;
            });
            var p = ['run', '-d', '--name', container];
            session.containerEnvs.forEach((key, value) {
              p.add('-e');
              p.add(key+'='+value);
            });
            p.add(image);
            runDockerCommand(p).then((value){
              var hasError = value.exitCode != 0;
              setState(() {
                runColor = hasError?Colors.red:Colors.green;
                _recycling = false;
              });
            });
          });
        });
      });
    });
  }

  Widget projectInput(pLabel, pController){
    return Container(
      width: double.infinity,
      decoration:BoxDecoration(color:Colors.white),
      padding: EdgeInsets.only(left:20.0, right:20.0, top:5.0, bottom:5.0),
      child: Row(
        children: [
          Container(
            width:110,
            child:
            Text(
              pLabel,
              style: TextStyle(color:Colors.grey, fontSize: 12.0),
            ),
          ),
          WDInput(controller: pController)
        ],
      ),
    );
  }

  Widget projectTitle(pLabel){
    return Container(
      width: double.infinity,
      decoration:BoxDecoration(color:Colors.lightBlue),
      padding: EdgeInsets.all(10.0),
      child: Text(pLabel,
        style: TextStyle(
            color: Colors.white
        ),
      ),
    );
  }

  void _getDirectoryPath(BuildContext context) async {
    const confirmButtonText = 'Sélectionner';
    final directoryPath = await FileSelectorPlatform.instance.getDirectoryPath(
      confirmButtonText: confirmButtonText,
    );
    _extractInfoFromGit(directoryPath??'');
  }

  void _extractInfoFromGit(String directoryPath) async{
    var hasGit = await Directory((directoryPath)+'/.git/').existsSync();
    if(hasGit){
      var command = 'git';
      var params = ['-C', directoryPath, 'branch', '--show-current'];

      Process.run(command, params).then((ProcessResult results){
        var project = directoryPath.split('/').last;
        var branch = results.stdout.replaceAll('\n', '').replaceAll('dev/', '').replaceAll('fix/', '');
        _repositoryTEC.text = project;
        _tagTEC.text = branch;
        _nameTEC.text = project+'_'+branch;
        var subdomain = branch+'.'+project;
        _envsTEC.forEach((element) {
          if(element[0].text.contains('_HOST')){
            element[1].text = element[1].text.replaceAll('{value}', subdomain);
          }
        });

        setState(() {
          session.workingDirectory = directoryPath;
        });
      });
    }else{
      setState(() {
        session.workingDirectory = directoryPath;
      });
    }
  }
}

class WDInput extends StatelessWidget {
  TextEditingController controller;
  double? width;

  WDInput({Key? key, required TextEditingController this.controller, this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var tf = TextField(
      controller:controller,
      style: TextStyle(fontSize:13.0, height: 2.0),
      decoration: InputDecoration(
          isDense:true,
          border:UnderlineInputBorder(
              borderSide: BorderSide()
          ),
          fillColor: Colors.white,
          focusColor: Colors.white,
          hoverColor: Colors.white,
          filled: true,
          contentPadding: EdgeInsets.all(5.0)
      ),
    );
    return (width==null)?Expanded(
        child: tf
    ):Container(
      width:width,
      child:tf
    );
  }
}
