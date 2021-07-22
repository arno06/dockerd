import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:flutter/material.dart';
class Console extends StatefulWidget {
  const Console({Key? key}) : super(key: key);

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  @override
  Widget build(BuildContext context) {
    if(!ConfigStorage().consoleDisplayed){
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 1.0),

      ),
      padding: EdgeInsets.all(10.0),
      height: 160,
      width:double.infinity,
      child: SingleChildScrollView(
          child: Text(
            ConfigStorage().logData,
            style: TextStyle(color: Colors.white, fontSize: 12.0),
          )
      ),
    );
  }
}
