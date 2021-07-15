import 'dart:io';

import 'package:dockerd/dockerd/utils/CommandHelper.dart';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
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
  late TextEditingController _domainTEC;
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
    _domainTEC = new TextEditingController();

    if(session.workingDirectory.isNotEmpty){
      if(session.imageRepository.isNotEmpty || session.imageTag.isNotEmpty){
        _repositoryTEC.text = session.imageRepository;
        _nameTEC.text = session.containerName;
        _tagTEC.text = session.imageTag;
        _domainTEC.text = session.containerSubdomain;
      }else{
        _extractInfoFromGit(session.workingDirectory);
      }
    }
  }

  @override
  void dispose() {
    _repositoryTEC.dispose();
    _nameTEC.dispose();
    _tagTEC.dispose();
    _domainTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:BoxDecoration(color:Colors.white10),
      width: double.infinity,
      padding:EdgeInsets.all(10.0),
      child: Column(
        children: [
          Opacity(
              opacity: _recycling?1:0,
              child:LinearProgressIndicator()
          ),
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
          projectInput('Sous-domaine', _domainTEC),
          Container(height: 10.0,),
          ElevatedButton(
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
          Spacer(),
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
            ],
          )
        ],
      ),
    );
  }


  void recyclingHandler(){
    session.imageRepository = _repositoryTEC.text;
    session.imageTag = _tagTEC.text;
    session.containerName = _nameTEC.text;
    session.containerSubdomain = _domainTEC.text;
    var image = _repositoryTEC.text+':'+_tagTEC.text;
    var container = _nameTEC.text;
    var domain = _domainTEC.text;
    setState(() {
      _recycling = true;
      killColor = Colors.blueAccent;
    });
    runDockerCommand(['kill', container]).then((value){
      var hasError = value.exitCode != 0;
      setState((){
        if(hasError){
          _recycling = false;
        }else{
          rmColor = Colors.blueAccent;
        }
        killColor = hasError?Colors.red:Colors.green;
      });
      if(hasError){
        return;
      }
      runDockerCommand(['rm', container, '--force']).then((value){
        var hasError = value.exitCode != 0;
        setState((){
          if(hasError){
            _recycling = false;
          }else{
            rmiColor = Colors.blueAccent;
          }
          rmColor = hasError?Colors.red:Colors.green;
        });
        if(hasError){
          return;
        }
        runDockerCommand(['rmi', image, '--force']).then((value){
          var hasError = value.exitCode != 0;
          setState((){
            if(hasError){
              _recycling = false;
            }else{
              buildColor = Colors.blueAccent;
            }
            rmiColor = hasError?Colors.red:Colors.green;
          });
          if(hasError){
            return;
          }
          runDockerCommand(['build', '-t', image, session.workingDirectory]).then((value){
            var hasError = value.exitCode != 0;
            setState((){
              if(hasError){
                _recycling = false;
              }else{
                runColor = Colors.blueAccent;
              }
              buildColor = hasError?Colors.red:Colors.green;
            });
            if(hasError){
              return;
            }
            runDockerCommand(['run', '-d', '--name', container, '-e', 'VIRTUAL_HOST='+domain+'.ama-doc.vidal.fr', image]).then((value){
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
          Expanded(
            child: TextField(
                controller: pController
            ),
          ),
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
        _domainTEC.text = branch+'.'+project;

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
