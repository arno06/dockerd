import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {

  late TextEditingController _dockerCommandTEC;
  late List<String> _parameters;
  late Map<String, String> _environmentsVars;
  late List<TextEditingController> _tec = [];
  late List<List<TextEditingController>> _envTec = [];
  ConfigStorage config = ConfigStorage();

  @override
  void initState() {
    super.initState();
    _dockerCommandTEC = TextEditingController(text: config.dockerCommand);
    _parameters = config.dockerDefaultParameters;
    _environmentsVars = config.dockerEnvironmentsVars;
  }

  @override
  void dispose() {
    _dockerCommandTEC.dispose();
    _tec.forEach((element) {
      element.dispose();
    });
    for (var value in _envTec) {
      value.forEach((element) {
        element.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    _tec.clear();
    for(var i = 0; i<_parameters.length; i++){
      var p = _parameters[i];
      var c = TextEditingController(text: p);
      _tec.add(c);
      items.add(
        Container(
          padding:EdgeInsets.only(bottom:5.0),
          child: Row(
            children: [
              input(c),
              TextButton(onPressed: (){
                setState(() {
                  _parameters.removeAt(i);
                  _tec.removeAt(i);
                });
              }, child: Icon(Icons.delete, size:11.0, color: Colors.black87)),
            ],
          ),
        )
      );
    }

    _envTec.clear();
    List<Widget> envVars = [];
    _environmentsVars.forEach((key, value) {
      List<TextEditingController> tcs = [];
      var ntec = TextEditingController(text: key);
      tcs.add(ntec);
      var vtec = TextEditingController(text: value);
      tcs.add(vtec);
      _envTec.add(tcs);
      envVars.add(
          Container(
            padding:EdgeInsets.only(bottom:5.0),
            child: Row(
              children: [
                input(ntec),
                Container(width:5),
                Text('='),
                Container(width:5),
                input(vtec),
                TextButton(onPressed: (){
                  setState(() {
                    _environmentsVars.remove(key);
                  });
                }, child: Icon(Icons.delete, size:11.0, color: Colors.black87)),
              ],
            ),
          )
      );
    });

    return Container(
      decoration:BoxDecoration(color: Color(0xFFeaeaea)),
      padding:EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Text("Général", style:TextStyle(fontSize:12.0)),
              Container(width:10),
              Expanded(child: Container(
                height:0,
                decoration: BoxDecoration(border: Border(top:BorderSide(color:Color(0xffaaaaaa)))),
              ))
            ],
          ),
          Container(
              padding:EdgeInsets.all(10.0),
              child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: config.consoleDisplayed,
                          onChanged: (bool? val){
                            setState(() {
                              config.consoleDisplayed = val??false;
                            });
                        }),
                        label('Afficher la console', 200, precedeInput: false),
                      ],
                    ),
                  ]
              )
          ),
          Container(height:20),
          Row(
            children: [
              Text("Docker", style:TextStyle(fontSize:12.0)),
              Container(width:10),
              Expanded(child: Container(
                height:0,
                decoration: BoxDecoration(border: Border(top:BorderSide(color:Color(0xffaaaaaa)))),
              ))
            ],
          ),
          Container(
            padding:EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: [
                    label('Emplacement du client', 200),
                    input(_dockerCommandTEC)
                  ],
                ),
                Container(height:10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Paramètres supplémentaires', 200),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5.0),
                            height:140,
                            decoration: BoxDecoration(
                                border: Border.all(color:Color(0xffaaaaaa))
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: items,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: (){
                                setState(() {
                                  _parameters.add('');
                                });
                              }, child: Icon(Icons.add, size:11.0, color: Colors.black87,)),
                            ],
                          )
                        ],
                      )
                    )
                  ],
                ),

                Container(height:10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Variables d\'environnements', 200),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5.0),
                            height:140,
                            decoration: BoxDecoration(
                                border: Border.all(color:Color(0xffaaaaaa))
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: envVars,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: (){
                                setState(() {
                                  _environmentsVars[''] = '';
                                });
                              }, child: Icon(Icons.add, size:11.0, color: Colors.black87,)),
                            ],
                          )
                        ],
                      )
                    )
                  ],
                ),
              ],
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blue)),
                onPressed: (){
                  var config = ConfigStorage();
                  config.dockerCommand = _dockerCommandTEC.text;
                  List<String> p = [];
                  _tec.forEach((TextEditingController element) {
                    p.add(element.text);
                  });
                  config.dockerDefaultParameters = p;

                  Map<String, String> e = {};
                  _envTec.forEach((element) {
                    e[element[0].text] = element[1].text;
                  });
                  config.dockerEnvironmentsVars = e;
                },
                child: Container(
                  padding:EdgeInsets.all(10.0),
                  child: Text("Enregistrer", style: TextStyle(color:Colors.white, fontWeight: FontWeight.normal, fontSize: 11.0),),
                ))
            ],
          )
        ],
      ),
    );
  }

  Widget input(TextEditingController controller){
    return Expanded(
      child: TextField(
        controller:controller,
        style: TextStyle(fontSize:13.0, height: 2.0),
        decoration: InputDecoration(
            isDense:true,
            border: OutlineInputBorder(borderSide:BorderSide.none),
            fillColor: Colors.white,
            focusColor: Colors.white,
            filled: true,
            contentPadding: EdgeInsets.all(5.0)
        ),
      )
    );
  }

  Widget label(String label, int width, {bool precedeInput = true}){
    return Container(
      width:width.toDouble(),
      child: Text(label+(precedeInput?' :':''), style:TextStyle(fontSize:13.0)),
    );
  }
}
