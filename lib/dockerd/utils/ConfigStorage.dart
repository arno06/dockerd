import 'dart:convert';
import 'dart:io';
import 'package:dockerd/dockerd/widgets/Containers.dart';
import 'package:dockerd/dockerd/widgets/Images.dart';
import 'package:path_provider/path_provider.dart';

class ConfigStorage
{
  static final String SESSION_FILE = 'dockerd.cfg';

  static final ConfigStorage _singleton = ConfigStorage._internal();

  factory ConfigStorage(){
    return _singleton;
  }

  ConfigStorage._internal(){}

  List<DockerContainer> containers = [];
  List<ImageContainer> images = [];

  String containersFilter = "";
  String imagesFilter = "";


  late Map<String, dynamic> session;

  init() async{
    session = await sessionVals;
    if(session['dockerDefaultParameters']!=null){
      session['dockerDefaultParameters'] = (session['dockerDefaultParameters'] as List).cast<String>().toList();
    }
  }

  String get workingDirectory => session['workingDirectory']??'';
  set workingDirectory(String val){
    storeVal('workingDirectory', val);
  }

  String get imageRepository => session['imageRepository']??'';
  set imageRepository(String val){
    storeVal('imageRepository', val);
  }

  String get imageTag => session['imageTag']??'';
  set imageTag(String val){
    storeVal('imageTag', val);
  }

  String get containerName => session['containerName']??'';
  set containerName(String val){
    storeVal('containerName', val);
  }

  String get containerSubdomain => session['containerSubdomain']??'';
  set containerSubdomain(String val){
    storeVal('containerSubdomain', val);
  }

  bool get sideBarOpened => session['sideBarOpened']??false;
  set sideBarOpened(bool val){
    storeVal('sideBarOpened', val);
  }

  String get dockerCommand => session['dockerCommand']??'/usr/local/bin/docker';
  set dockerCommand(String val){
    storeVal('dockerCommand', val);
  }

  List<String> get dockerDefaultParameters => session['dockerDefaultParameters']??['--tlsverify', '-H=docker-digital.vidal.net:2376'];
  set dockerDefaultParameters(List<String> val){
    storeVal('dockerDefaultParameters', val);
  }

  void storeVal(key, val) async{
    session[key] = val;
    final file = await _sessionFile;
    file.writeAsString(jsonEncode(session));
  }

  Future<Map<String, dynamic>> get sessionVals async{
    final file = await _sessionFile;
    if(!file.existsSync()){
      file.createSync();
      file.writeAsStringSync('{}');
    }
    return jsonDecode(file.readAsStringSync());
  }

  Future<File> get _sessionFile async{
    final path = await _localPath;
    return File('$path/$SESSION_FILE');
  }

  Future<String> get _localPath async{
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}