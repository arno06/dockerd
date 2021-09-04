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
  String logData = "";

  late Map<String, dynamic> session;

  init() async{
    session = await sessionVals;
    if(session['dockerDefaultParameters']!=null){
      session['dockerDefaultParameters'] = (session['dockerDefaultParameters'] as List).cast<String>().toList();
    }
    if(session['dockerEnvironmentsVars']!= null){
      session['dockerEnvironmentsVars'] = (session['dockerEnvironmentsVars'] as Map).cast<String, String>();
    }
    if(session['workingDirs'] != null){
      session['workingDirs'] = (session['workingDirs'] as List).cast<Map>().toList();
    }
  }

  void log({String? data, String? cmd, List<String>? parameters}){
    String log = DateTime.now().toString()+"\t";
    if(data != null){
      log += data;
    }else{
      log += (cmd??'')+' '+(parameters!.join(' '));
    }
    logData = log+'\n'+logData;
  }

  bool get sideBarOpened => session['sideBarOpened']??false;
  set sideBarOpened(bool val){
    storeVal('sideBarOpened', val);
  }

  String get dockerCommand => session['dockerCommand']??'/usr/local/bin/docker';
  set dockerCommand(String val){
    storeVal('dockerCommand', val);
  }

  int get workingDirIndex => session['workingDirIndex']??0;
  set workingDirIndex(int val){
    storeVal('workingDirIndex', val);
  }

  List<String> get dockerDefaultParameters => session['dockerDefaultParameters']??[];
  set dockerDefaultParameters(List<String> val){
    storeVal('dockerDefaultParameters', val);
  }

  Map<String, String> get dockerEnvironmentsVars => session['dockerEnvironmentsVars']??{};
  set dockerEnvironmentsVars(Map<String, String> val){
    storeVal('dockerEnvironmentsVars', val);
  }

  bool get consoleDisplayed => session['consoleDisplayed']??false;
  set consoleDisplayed(bool val){
    storeVal('consoleDisplayed', val);
  }

  List<Map> get workingDirs => session['workingDirs']??[];
  set workingDirs(List<Map> val){
    storeVal('workingDirs', val);
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