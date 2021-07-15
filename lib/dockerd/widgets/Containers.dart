import 'dart:io';

import 'package:dockerd/dockerd/utils/CommandHelper.dart';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:flutter/material.dart';

class ContainersList extends StatefulWidget {
  const ContainersList({Key? key}) : super(key: key);

  @override
  _ContainersListState createState() => _ContainersListState();
}

class _ContainersListState extends State<ContainersList> {

  late TextEditingController _searchController;
  bool _containerLoaded = true;
  ConfigStorage session = ConfigStorage();

  @override
  void initState() {
    super.initState();
    _searchController = new TextEditingController(text: session.containersFilter);
    if(session.containers.isEmpty){
      refreshContainer();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var selected = false;
    List<DataRow> dataRows = [];
    for(var i = 0, max = session.containers.length; i<max; i++){
      var ctn = session.containers[i];
      if(_searchController.text.length>0 && !ctn.name.contains(_searchController.text)){
        continue;
      }

      selected = ctn.selected||selected;
      dataRows.add(
          DataRow(
              onSelectChanged: (bool? value) {
                setState(() {
                  ctn.selected = value!;
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
                        Text(ctn.name, style:TextStyle(fontSize:12.0)),
                        Text(ctn.image, style:TextStyle(fontSize: 11.0, color:Colors.grey))
                      ],
                    )
                ),
                DataCell(Text(ctn.created, style:TextStyle(fontSize:11.0), overflow: TextOverflow.ellipsis,)),
                DataCell(Row(
                  children: [
                    TextButton(onPressed: (){
                      setState(() {
                        /*_selectedContainer = ctn;
                        inspectSelectedContainer();
                        _opened = true;*/
                      });
                    }, child: Icon(Icons.preview, size:16.0, color:Colors.black87)),
                    TextButton(onPressed: (){}, child: Icon(Icons.archive, size:16.0, color:Colors.black87)),
                  ],
                )),
              ]
          )
      );
    }
    return Column(
      children: [
        Opacity(
            opacity: _containerLoaded?0:1,
            child:LinearProgressIndicator()
        ),
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
                        child:TextButton(onPressed: !selected?null:(){runCommandContainer('restart');}, child: Icon(Icons.refresh, size: 15.0, color: selected?Colors.green:Colors.white38,), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFeaeaea)))),
                      ),
                      SizedBox(width: 5.0,),
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Arrêter',
                        child:TextButton(onPressed: !selected?null:(){runCommandContainer('stop');}, child: Icon(Icons.stop, size: 15.0, color: selected?Color(0xFFBB1F1F):Colors.white38,), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFeaeaea)))),
                      ),
                      SizedBox(width: 5.0,),
                      Tooltip(
                        waitDuration: Duration(seconds:1),
                        message:'Supprimer',
                        child:TextButton(onPressed: !selected?null:(){runCommandContainer('rm');}, child: Icon(Icons.delete, size: 15.0, color: selected?Color(0xFFBB1F1F):Colors.white38,), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFeaeaea)))),
                      )
                    ],
                  ),
                ),
                Container(
                  width:400,
                  child: TextField(
                      controller: _searchController,
                      onChanged:(String value){
                        setState(() {
                          session.containersFilter = _searchController.text;
                        });
                      },
                      decoration:InputDecoration(
                          hintText: 'Filtrer',
                          prefixIcon: Icon(Icons.search, size: 15.0,)
                      )
                  ),
                ),
                Spacer(),
              ]
          ),
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
                          DataColumn(label: Text('Name', style: TextStyle(fontSize:12.0, fontWeight: FontWeight.normal),)),
                          DataColumn(label: Text('Created', style: TextStyle(fontSize:12.0, fontWeight: FontWeight.normal),)),
                          DataColumn(label: TextButton(onPressed: refreshContainer, child: Icon(Icons.refresh, size:16.0, color:Colors.black87))),
                        ],
                        rows:dataRows
                    ),
                ),
            ),
        ),
      ],
    );
  }

  void runCommandContainer(String command){
    List<String> params = [command];
    session.containers.forEach((element) {
      if(element.selected){
        params.add(element.id);
      }
    });
    runDockerCommand(params).then((ProcessResult results){
      refreshContainer();
    });
  }

  void refreshContainer(){
    setState(() {
      _containerLoaded = false;
    });
    var cols = ['CONTAINER ID', 'IMAGE', 'COMMAND', 'CREATED', 'STATUS', 'PORTS', 'NAMES'];
    runDockerCommand(['ps', '-a']).then((ProcessResult results){
      session.containers.clear();
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
        session.containers.add(DockerContainer(
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