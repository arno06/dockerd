import 'package:dockerd/dockerd/widgets/Containers.dart';
import 'package:dockerd/dockerd/widgets/Images.dart';
import 'package:dockerd/dockerd/widgets/Settings.dart';
import 'package:dockerd/dockerd/widgets/WorkingDirectory.dart';
import 'package:dockerd/dockerd/widgets/sidebar.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  int selectedIndex = 0;

  void sideBarItemSelectedHandler(int index){
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget displayed;
    switch(selectedIndex){
      case 0:
        displayed = ContainersList();
        break;
      case 1:
        displayed = ImagesList();
        break;
      case 2:
        displayed = WorkingDirectory();
        break;
      case 3:
        displayed = Settings();
        break;
      default:
        displayed = Text("there");
        break;
    }
    return Scaffold(
      body: Row(
        children: [
          SideBar(onSelected: this.sideBarItemSelectedHandler,),
          Expanded(
            child: displayed
          )
        ],
      ),
    );
  }
}
