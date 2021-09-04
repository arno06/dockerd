import 'package:dockerd/dockerd/utils/ConfigStorage.dart';
import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  SideBar({Key? key, this.onSelected}) : super(key: key);

  void Function(int)? onSelected;

  @override
  _SideBarState createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {

  int selectedIndex = 0;

  bool opened = true;

  @override
  void initState() {
    super.initState();
    opened = ConfigStorage().sideBarOpened;
  }

  void itemSelectedHandler(index){
    setState(() {
      selectedIndex = index;
      this.widget.onSelected!(selectedIndex);
    });
  }

  @override
  Widget build(BuildContext context) {

    Widget header;
    if(this.opened){

      header = Container(
        padding:EdgeInsets.only(top:10.0,bottom:10.0),
        child: TextButton(
            onPressed: (){
              setState(() {
                opened = !opened;
                ConfigStorage().sideBarOpened = opened;
              });
            },
            child:Row(
              children: [
                Expanded(child: Text("Dockerd", style: TextStyle(fontSize:11.0, color:Colors.black54), overflow: TextOverflow.ellipsis),),
                Icon(Icons.first_page, size:12.0, color: Colors.black54,)
              ],
            )
        ),
      );
    }else{
      header = Container(
        padding:EdgeInsets.only(top:10.0,bottom:10.0),
        child: TextButton(onPressed: (){
          setState(() {
            opened = !opened;
            ConfigStorage().sideBarOpened = opened;
          });
        }, child: Icon(Icons.last_page, size:12.0, color: Colors.black54,)),
      );
    }

    return AnimatedContainer(
      decoration: BoxDecoration(border: Border(right: BorderSide(color:Colors.black12))),
      duration: Duration(milliseconds: 150),
      width: opened?200:60,
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: [
          header,
          SideBarItem.Item(Icons.view_compact, 'Conteneurs', 0, (selectedIndex==0), this.itemSelectedHandler, this.opened),
          SideBarItem.Item(Icons.storage, 'Images', 1, (selectedIndex==1), this.itemSelectedHandler, this.opened),
          SideBarItem.Item(Icons.folder,'Dossiers de travail', 2, (selectedIndex==2), this.itemSelectedHandler, this.opened),
          Spacer(),
          SideBarItem.Item(Icons.settings_sharp,'Paramètres', 3, (selectedIndex==3), this.itemSelectedHandler, this.opened),
        ],
      ),
    );
  }
}


class SideBarItem extends StatelessWidget
{
  static final String TYPE_HEAD = "head";
  static final String TYPE_ITEM = "item";

  final IconData? icon;
  final String label;
  final bool selected;
  final String type;
  final int index;
  final bool expanded;

  void Function(dynamic) onPressed;

  SideBarItem({this.icon, required this.label, required this.selected, required this.onPressed, required this.index, required this.expanded, this.type = 'head'});

  @override
  Widget build(BuildContext context) {

    List<Widget> children = [];
    BoxDecoration decoration = BoxDecoration();

    TextStyle style = TextStyle(fontSize: 12.0, color:Colors.black87, fontWeight: FontWeight.normal);


    if(this.selected){
      style = TextStyle(fontSize: 12.0, color:Colors.white, fontWeight: FontWeight.normal);
      decoration = BoxDecoration(color:Colors.blue, borderRadius: BorderRadius.all(Radius.circular(5.0)));
    }

    if(this.icon != null){
      children.add(Icon(this.icon, size:18.0, color: this.selected?Colors.white:Colors.black87,));
    }

    if(this.expanded){
      children.add(Container(width:7));
      children.add(Expanded(child: Text(this.label, style: style, overflow: TextOverflow.ellipsis,),));
    }

    return TextButton(onPressed: (){
      this.onPressed(this.index);
    }, child: AnimatedContainer(
      duration:Duration(milliseconds: 100),
      decoration:decoration,
      padding: EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    ));
  }

  static SideBarItem Item(IconData icon, String label, int index, bool selected, void Function(dynamic) onPressed, bool expanded){
    return SideBarItem(icon: icon, label: label, selected: selected, onPressed: onPressed, index:index, type:TYPE_ITEM, expanded:expanded);
  }
}