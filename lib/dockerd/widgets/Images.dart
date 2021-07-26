import 'dart:io';

import 'package:dockerd/dockerd/utils/CommandHelper.dart';
import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:dockerd/dockerd/widgets/Console.dart';
import 'package:flutter/material.dart';

class ImagesList extends StatefulWidget {
  ImagesList({Key? key}) : super(key: key);

  @override
  _ImagesListState createState() => _ImagesListState();
}

class _ImagesListState extends State<ImagesList> {

  bool _imageLoaded = true;
  late TextEditingController _searchController;
  ConfigStorage session = ConfigStorage();

  @override
  void initState() {
    _searchController = new TextEditingController(text:session.imagesFilter);
    super.initState();
    if(session.images.isEmpty){
      refreshImages();
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
    for(var i = 0, max = session.images.length; i<max; i++){
      var img = session.images[i];
      if(_searchController.text.length>0 && !img.repository.contains(_searchController.text) && !img.tag.contains(_searchController.text)){
        continue;
      }

      selected = img.selected||selected;
      dataRows.add(
          DataRow(
              onSelectChanged: (bool? value) {
                setState(() {
                  img.selected = value!;
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
              selected:img.selected,
              cells: [
                DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Text(img.repository, style:TextStyle(fontSize:12.0)),
                      Text(img.tag, style:TextStyle(fontSize:11.0, color:Colors.grey))
                    ]
                )),
                DataCell(Text(img.created, style:TextStyle(fontSize:11.0))),
                DataCell(Text(img.size, style:TextStyle(fontSize:11.0))),
              ]
          )
      );
    }
    return Column(
      children: [
        Opacity(
            opacity: _imageLoaded?0:1,
            child:LinearProgressIndicator()
        ),
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
                        child:TextButton(onPressed: !selected?null:(){runCommandImage('rmi');}, child: Icon(Icons.delete, size:15.0, color: selected?Color(0xFFBB1F1F):Colors.white38,), style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFeaeaea)))),
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
                          session.imagesFilter = _searchController.text;
                        });
                      },
                      decoration:InputDecoration(
                          hintText: 'Filtrer',
                          prefixIcon: Icon(Icons.search, size: 15.0,)
                      )
                  ),
                ),
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
                          DataColumn(label: Text('Repository', style: TextStyle(fontSize:12.0, fontWeight: FontWeight.normal),)),
                          DataColumn(label: Text('Created', style: TextStyle(fontSize:12.0, fontWeight: FontWeight.normal),)),
                          DataColumn(label: TextButton(onPressed: refreshImages, child: Icon(Icons.refresh, size:16.0, color:Colors.black87))),
                        ],
                        rows:dataRows
                    )
                )
            )
        ),
        Console()
      ],
    );
  }

  void runCommandImage(String command){

    setState(() {
      _imageLoaded = false;
    });
    List<String> params = [command];
    session.images.forEach((element) {
      if(element.selected){
        params.add(element.id);
      }
    });
    runDockerCommand(params).then((ProcessResult results){
      refreshImages();
    });
  }

  void refreshImages(){

    setState(() {
      _imageLoaded = false;
    });
    var cols = ['REPOSITORY', 'TAG', 'IMAGE ID', 'CREATED', 'SIZE'];
    runDockerCommand(['images']).then((ProcessResult results){
      session.images.clear();
      String result = results.stdout;
      List<String> lines = result.split(RegExp('\n'));
      var lengths = getCommandLineHeadLengths(lines[0], cols);
      for(var i = 1, max = lines.length-1; i<max; i++){
        var line = lines[i];
        var props = parseLine(line, lengths);
        session.images.add(ImageContainer(
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