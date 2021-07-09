import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:window_size/window_size.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

String DOCKER_COMMAND = '/usr/local/bin/docker';
List<String> DEFAULT_DOCKER_PARAMETERS = ['--tlsverify', '-H=docker-digital.vidal.net:2376'];

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if(Platform.isWindows || Platform.isMacOS || Platform.isLinux){
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
      home: DockerDigitHome(),
    );
  }
}

class DockerDigitHome extends StatefulWidget {

  DockerDigitHome({Key? key}) : super(key: key);

  @override
  _DockerDigitHomeState createState() => _DockerDigitHomeState();
}

class _DockerDigitHomeState extends State<DockerDigitHome> {


  List<DockerContainer> containers = [];
  List<ImageContainer> images = [];

  int _selectedIndex = 0;
  String searchText = "";
  late TextEditingController _textEditingController;
  bool _opened = false;
  DockerContainer? _selectedContainer;

  bool _containerLoaded = false;
  bool _imageLoaded = false;
  bool _recycling = false;

  String? lastRecycle;

  String _logData = "";

  String? _selectedFolderProject;

  late TextEditingController _repositoryTEC;
  late TextEditingController _tagTEC;
  late TextEditingController _nameTEC;
  late TextEditingController _domainTEC;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _repositoryTEC = TextEditingController();
    _tagTEC = TextEditingController();
    _nameTEC = TextEditingController();
    _domainTEC = TextEditingController();
    refreshContainer();
    refreshImages();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _repositoryTEC.dispose();
    _tagTEC.dispose();
    _nameTEC.dispose();
    _domainTEC.dispose();
    super.dispose();
  }

  void _log(List<String> parameters, {String? command}){
    if(command == null){
      command = DOCKER_COMMAND;
    }
    setState(() {
      var log = DateTime.now().toString()+"\t"+(command!)+" "+parameters.join(" ");
      _logData += log+"\n";
    });
  }

  void refreshImages(){
    setState(() {
      _imageLoaded = false;
    });
    var cols = ['REPOSITORY', 'TAG', 'IMAGE ID', 'CREATED', 'SIZE'];
    runDockerCommand(['images']).then((ProcessResult results){
      images.clear();
      String result = results.stdout;
      List<String> lines = result.split(RegExp('\n'));
      var lengths = getCommandLineHeadLengths(lines[0], cols);
      for(var i = 1, max = lines.length-1; i<max; i++){
        var line = lines[i];
        var props = parseLine(line, lengths);
        images.add(ImageContainer(
            id:props[2],
            repository:props[0],
            created:props[3],
            size:props[4],
            tag:props[1]
        ));
      }
      setState((){
        _imageLoaded = true;
      });
    });
  }

  List<int> getCommandLineHeadLengths(String head, List<String> cols){
    List<int> lengths = [];
    var currIndex = 0;
    for(var i = 0, max = cols.length-1; i<max; i++){
      currIndex = head.indexOf(cols[i]);
      lengths.add(head.indexOf(cols[i+1]) - currIndex);
    }
    return lengths;
  }

  List<String> parseLine(String line, List<int> lengths){
    List<String> props = [];
    var currIndex = 0;
    for(var j = 0, maxj = lengths.length; j<maxj; j++){
      int end = (currIndex + lengths[j]).toInt();
      props.add(line.substring(currIndex, end).trim());
      currIndex = end;
    }
    props.add(line.substring(currIndex));
    return props;
  }

  void refreshContainer(){
    setState(() {
      _containerLoaded = false;
    });
    var cols = ['CONTAINER ID', 'IMAGE', 'COMMAND', 'CREATED', 'STATUS', 'PORTS', 'NAMES'];
    runDockerCommand(['ps', '-a']).then((ProcessResult results){
      containers.clear();
      String result = results.stdout;
      List<String> lines = result.split(RegExp('\n'));
      if(lines.length==1 || (lines.length==2 && lines.elementAt(1) == "")){
        setState((){
          _containerLoaded = true;
        });
        return;
      }
      var lengths = getCommandLineHeadLengths(lines[0], cols);
      for(var i = 1, max = lines.length-1; i<max; i++){
        var line = lines[i];
        var props = parseLine(line, lengths);
        containers.add(DockerContainer(
          id:props[0],
          image:props[1],
          created:props[3],
          status:props[4],
          name:props[6]
        ));
      }
      setState((){
        _containerLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var tabs = [containerView(),imageView(),projectView(context),configurationView()];
    return Scaffold(
      body: Container(
          decoration:BoxDecoration(color:Colors.black12),
          child:Stack(
            children:[
              Center(
                  child: tabs[_selectedIndex]
              ),
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
                          opacity: _selectedContainer?.inspection==null?1:0,
                          child: LinearProgressIndicator(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Text(_selectedContainer!=null?_selectedContainer!.name:''),
                                Text(_selectedContainer!=null?_selectedContainer!.image:'', style:TextStyle(fontSize:12.0, color:Colors.grey))
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
                            launch(_selectedContainer!.url!);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.link),
                              Container(width:10),
                              Text(_selectedContainer?.url == null?"":_selectedContainer!.url!),
                            ],
                        ),)
                      ]
                  ),
                ),
              ),
            ]
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.computer),
            label: 'Containers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Images',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Projet en cours',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: (int index){
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );

  }

  Widget configurationView(){
    return Center(
      child: Text("Configuration"),
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
                        controller: _textEditingController,
                      ),
                    ),
                    TextButton(onPressed: (){

                      Process.run('bash', ['-c', _textEditingController.text], runInShell: true).then((ProcessResult results){
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

  void _getDirectoryPath(BuildContext context) async {
    const confirmButtonText = 'Sélectionner';
    final directoryPath = await FileSelectorPlatform.instance.getDirectoryPath(
      confirmButtonText: confirmButtonText,
    );

    var hasGit = await Directory((directoryPath??'')+'/.git/').existsSync();
    if(hasGit){
      var command = 'git';
      var params = ['-C', directoryPath??'', 'branch', '--show-current'];

      Process.run(command, params).then((ProcessResult results){
        var project = directoryPath!.split('/').last;
        var branch = results.stdout.replaceAll('\n', '').replaceAll('dev/', '').replaceAll('fix/', '');
        _repositoryTEC.text = project;
        _tagTEC.text = branch;
        _nameTEC.text = project+'_'+branch;
        _domainTEC.text = branch+'.'+project;

        setState(() {
          _selectedFolderProject = directoryPath;
        });
      });
    }else{
      setState(() {
        _selectedFolderProject = directoryPath;
      });
    }
  }

  Widget projectView(BuildContext context){

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
                    child: Text(_selectedFolderProject??'Choisir un dossier'),
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
                  Text('Recycler')
                ],
              ),
            )
          )
        ],
      ),
    );
  }

  void recyclingHandler(){
    var image = _repositoryTEC.text+':'+_tagTEC.text;
    var container = _nameTEC.text;
    var domain = _domainTEC.text;
    setState(() {
      _recycling = true;
    });
    runDockerCommand(['kill', container]).then((value){
      runDockerCommand(['rm', container, '--force']).then((value){
        runDockerCommand(['rmi', image, '--force']).then((value){
          runDockerCommand(['build', '-t', image, _selectedFolderProject??'']).then((value){
            runDockerCommand(['run', '-d', '--name', container, '-e', 'VIRTUAL_HOST='+domain+'.ama-doc.vidal.fr', image]).then((value){
              setState(() {
                _recycling = false;
                lastRecycle = DateTime.now().toString();
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

  Widget imageView(){
    var selected = false;
    List<DataRow> dataRows = [];
    for(var i = 0, max = images.length; i<max; i++){
      var ctn = images[i];
      if(searchText.length>0 && !ctn.repository.contains(searchText) && !ctn.tag.contains(searchText)){
        continue;
      }

      selected = images[i].selected||selected;
      dataRows.add(
          DataRow(
              onSelectChanged: (bool? value) {
                setState(() {
                  images[i].selected = value!;
                });
              },
              color:MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected))
                      return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                    if (i.isEven) {
                      return Colors.grey.withOpacity(0.1);
                    }
                    return null;
                  }),
              selected:ctn.selected,
              cells: [
                DataCell(Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Text(ctn.repository),
                    Text(ctn.tag, style:TextStyle(fontSize:12.0, color:Colors.grey))
                  ]
                )),
                DataCell(Text(ctn.created)),
                DataCell(Text(ctn.size)),
              ]
          )
      );
    }
    return Column(
      children: [
        Container(
          padding:EdgeInsets.only(left:10.0, right:10.0, top:5.0, bottom:5.0),
          child: Row(
              children:[
                Container(
                  width:250,
                  child:Row(
                    children: [
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Supprimer',
                        child:ElevatedButton(onPressed: !selected?null:(){runCommandImage('rmi');}, child: Icon(Icons.delete), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFBB1F1F)))),
                      )
                    ],
                  ),
                ),
                Container(
                  width:400,
                  child: TextField(
                      controller: _textEditingController,
                      onChanged:(String value){
                        setState(() {
                          this.searchText = value;
                        });
                      },
                      decoration:InputDecoration(
                          hintText: 'Filtrer',
                          prefixIcon: Icon(Icons.search)
                      )
                  ),
                ),
              ]
          ),
        ),
        Opacity(
            opacity: _imageLoaded?0:1,
            child:LinearProgressIndicator()
        ),
        Flexible(
            child:Container(
                decoration:BoxDecoration(color:Colors.white),
                height:double.infinity,
                width:double.infinity,
                child:SingleChildScrollView(
                    child: DataTable(
                        columns: [
                          DataColumn(label: Text('Repository')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: IconButton(onPressed: refreshImages, icon: Icon(Icons.refresh))),
                        ],
                        rows:dataRows
                    )
                )
            )
        ),
      ],
    );
  }

  Widget containerView(){
    var selected = false;
    List<DataRow> dataRows = [];
    for(var i = 0, max = containers.length; i<max; i++){
      var ctn = containers[i];
      if(searchText.length>0 && !ctn.name.contains(searchText) && !ctn.image.contains(searchText)){
        continue;
      }

      selected = containers[i].selected||selected;
      dataRows.add(
          DataRow(
              onSelectChanged: (bool? value) {
                setState(() {
                  containers[i].selected = value!;
                });
              },
              color:MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected))
                      return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                    if (i.isEven) {
                      return Colors.grey.withOpacity(0.1);
                    }
                    return null;
                  }),
              selected:ctn.selected,
              cells: [
                DataCell(Container(
                  decoration:BoxDecoration(color:ctn.status.contains('Exited (0)')?Colors.red:Colors.green),
                  width: 5,
                )),
                DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ctn.name, ),
                        Text(ctn.image, style:TextStyle(fontSize: 12.0, color:Colors.grey))
                      ],
                    )
                ),
                DataCell(Text(ctn.created)),
                DataCell(Row(
                  children: [
                    IconButton(onPressed: (){
                      setState(() {
                        _selectedContainer = ctn;
                        inspectSelectedContainer();
                        _opened = true;
                      });
                    }, icon: Icon(Icons.preview)),
                    IconButton(onPressed: (){}, icon: Icon(Icons.archive)),
                  ],
                )),
              ]
          )
      );
    }
    return Column(
      children: [
        Container(
          padding:EdgeInsets.only(left:10.0, right:10.0, top:5.0, bottom:5.0),
          child: Row(
              children:[
                Container(
                  width:250,
                  child: Row(
                    children: [
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Relancer',
                        child:ElevatedButton(onPressed: !selected?null:(){runCommandContainer('restart');}, child: Icon(Icons.refresh), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.green))),
                      ),
                      SizedBox(width: 5.0,),
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Arrêter',
                        child:ElevatedButton(onPressed: !selected?null:(){runCommandContainer('stop');}, child: Icon(Icons.stop), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFBB1F1F)))),
                      ),
                      SizedBox(width: 5.0,),
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Supprimer',
                        child:ElevatedButton(onPressed: !selected?null:(){runCommandContainer('rm');}, child: Icon(Icons.delete), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFBB1F1F)))),
                      )
                    ],
                  ),
                ),
                Container(
                  width:400,
                  child: TextField(
                      controller: _textEditingController,
                      onChanged:(String value){
                        setState(() {
                          this.searchText = value;
                        });
                      },
                      decoration:InputDecoration(
                          hintText: 'Filtrer',
                          prefixIcon: Icon(Icons.search)
                      )
                  ),
                ),
                Spacer(),
              ]
          ),
        ),
        Opacity(
          opacity: _containerLoaded?0:1,
          child:LinearProgressIndicator()
        ),
        Flexible(
            child:Container(
                decoration:BoxDecoration(color:Colors.white),
                height:double.infinity,
                width:double.infinity,
                child:SingleChildScrollView(
                    child: DataTable(
                        columns: [
                          DataColumn(label: Container(width:0, child: Text(''),)),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Created')),
                          DataColumn(label: IconButton(onPressed: refreshContainer, icon: Icon(Icons.refresh))),
                        ],
                        rows:dataRows
                    )
                )
            )
        ),
      ],
    );
  }

  Future<ProcessResult> runDockerCommand(List<String> parameters){
    List<String> params = new List<String>.from(DEFAULT_DOCKER_PARAMETERS);
    params.addAll(parameters);
    _log(params);
    return Process.run(DOCKER_COMMAND, params, runInShell: true).then((ProcessResult results){
      if(results.exitCode != 0){
        _log([], command:'Error : '+results.stderr);
      }
      return results;
    });
  }

  void inspectSelectedContainer(){
    if(_selectedContainer!.inspection != null){
      return;
    }
    List<String> params = ["inspect", _selectedContainer!.id];
    runDockerCommand(params).then((ProcessResult results){
      List<String> lines = results.stdout.split('\n');
      List<dynamic> inspections = jsonDecode(lines.join('\n'));
      _selectedContainer?.inspection = inspections.elementAt(0);
      List<dynamic> envs = _selectedContainer?.inspection?['Config']?['Env'];
      envs.forEach((element) {
        if(element.indexOf('VIRTUAL_HOST=') > -1){
          _selectedContainer?.url = element.replaceFirst('VIRTUAL_HOST=', 'http://');
        }
        if(element.indexOf('LETSENCRYPT_HOST=') > -1){
          _selectedContainer?.url = element.replaceFirst('LETSENCRYPT_HOST=', 'https://');
        }
      });
      setState(() {});
    });
  }

  void runCommandImage(String cmd){
    List<String> params = [cmd];
    images.forEach((element) {
      if(element.selected){
        params.add(element.id);
      }
    });
    runDockerCommand(params).then((ProcessResult results){
      refreshImages();
    });
  }

  void runCommandContainer(String cmd){
    List<String> params = [cmd];
    containers.forEach((element) {
      if(element.selected){
        params.add(element.id);
      }
    });
    runDockerCommand(params).then((ProcessResult results){
      refreshContainer();
    });
  }

  DataCell tCell(String text){
    return DataCell(Text(text));
  }

  Widget tHead(String text){
    return Container(
      padding:EdgeInsets.all(10.0),
      child: Text(text),
    );
  }
}

class DockerContainer{
  String image;
  String id;
  String created;
  String status;
  String name;
  bool selected = false;
  Map<dynamic, dynamic>? inspection;
  String? url;

  DockerContainer({required this.id, required this.name, required this.image, required this.created, required this.status});
}

class ImageContainer{
  String id;
  String repository;
  String tag;
  String created;
  String size;
  bool selected = false;

  ImageContainer({required this.id, required this.repository, required this.tag, required this.created, required this.size});
}