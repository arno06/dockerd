import 'package:flutter/material.dart';
class TabsRow extends StatefulWidget {
  const TabsRow({Key? key, required this.onSelected, required this.tabs, required this.onAdd, required this.onDeleted, required this.selectedIndex}) : super(key: key);

  final void Function(int) onDeleted;
  final void Function(int) onSelected;
  final void Function() onAdd;
  final int selectedIndex;

  final List<String> tabs;

  @override
  _TabsRowState createState() => _TabsRowState();
}

class _TabsRowState extends State<TabsRow> {

  void itemSelectedHandler(index){
    setState(() {
      this.widget.onSelected(index);
    });
  }

  void itemDeletedHandler(index){
    setState(() {
      this.widget.onDeleted(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [];
    var i = 0;
    this.widget.tabs.forEach((element) {
      tabs.add(TabItem(label: element, activated: this.widget.selectedIndex==i, index:i, onSelected: itemSelectedHandler, onDeleted: itemDeletedHandler));
      i++;
    });

    tabs.add(
      InkWell(
        onTap: (){
          this.widget.onAdd();
        },
        child: Container(
          padding:EdgeInsets.all(5.0),
          child: Icon(
            Icons.add,
            size:16.0,
            color:Color.fromARGB(255, 45, 45, 45)
          ),
        ),
      )
    );

    return Container(
      height:30,
      decoration:BoxDecoration(
        color:Color.fromARGB(255, 220, 220, 220)
      ),
      child:ListView(
        scrollDirection: Axis.horizontal,
        children: tabs,
      )
    );
  }
}

class TabItem extends StatelessWidget {

  final String label;

  final bool activated;

  final void Function(int) onSelected;

  final void Function(int) onDeleted;

  final int index;

  const TabItem({Key? key, required this.label, required this.activated, required this.index, required this.onSelected, required this.onDeleted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var decoration;
    var style;
    if(this.activated){
      decoration = BoxDecoration(
        color:Color.fromARGB(255, 251, 251, 251),
        border:Border(
          top:BorderSide(color:Theme.of(context).accentColor, width: 2.0, style:BorderStyle.solid)
        )
      );
      style = TextStyle(
        fontSize: 10.0,
        color:Colors.black,
      );
    }else{
      decoration = BoxDecoration(color:Color.fromARGB(255, 220, 220, 220));
      style = TextStyle(
          fontSize: 10.0,
          color:Colors.black38
      );
    }
    return AnimatedContainer(
      width:120,
      height:double.infinity,
      duration: Duration(milliseconds: 300),
      decoration:decoration,
      child: Row(
        children: [
          TextButton(
            onPressed: (){
              this.onSelected(this.index);
            },
            child: Container(
              padding:EdgeInsets.only(left:5.0, right:0),
              width:100,
              child: Text(
                this.label,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            )
          ),
          Container(width:3),
          InkWell(
            onTap: (){
              this.onDeleted(this.index);
            },
            child: Icon(Icons.close, size: 10,),
          )
        ],
      )
    );
  }
}

