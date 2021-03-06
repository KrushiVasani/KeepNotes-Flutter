import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_awesome_icons/line_awesome_icons.dart';

import '../data/SqliteHandler.dart';
import '../data/notes.dart';
import '../data/utility.dart';
import '../ui/staggered_page.dart';
import 'note_page.dart';
import 'picnote_page.dart';

enum viewType { List, Staggered }

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var notesViewType;

  @override
  void initState() {
    notesViewType = viewType.Staggered;
    super.initState();
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 720, height: 1440, allowFontScaling: true);
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        brightness: Brightness.light,
        actions: _appBarActions(),
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        // centerTitle: true,
        title: Text(
          "Keep Notes",
          style: GoogleFonts.montserrat(color: Colors.black),
        ),
      ),
      floatingActionButton: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.black),
              borderRadius: BorderRadius.circular(100)),
          child: Hero(
            tag: 'FAB',
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: FlatButton(
                        padding: EdgeInsets.fromLTRB(5, 14, 0, 14),
                        key: Key('NewNote'),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(100),
                                bottomRight: Radius.circular(100))),
                        color: Colors.indigo[700],
                        // elevation: 0,
                        onPressed: () => _newNoteTapped(context),
                        child: Transform.rotate(
                          angle: 90 * pi / 180,
                          child: Icon(
                            LineAwesomeIcons.edit,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: FlatButton(
                        padding: EdgeInsets.fromLTRB(0, 14, 5, 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(100),
                                bottomRight: Radius.circular(100))),
                        color: Colors.orange,
                        // elevation: 0,
                        onPressed: () => _newPhotoNoteTapped(context),
                        child: Transform.rotate(
                          angle: 270 * pi / 180,
                          child: Icon(
                            LineAwesomeIcons.file_image_o,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
      body: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: NavigationRail(
                  groupAlignment: 0.0,
                  unselectedIconTheme: IconThemeData(color: Colors.black87),
                  selectedIconTheme: IconThemeData(color: Colors.black),
                  labelType: NavigationRailLabelType.selected,
                  backgroundColor: Colors.amber,
                  onDestinationSelected: (int index) {
                    if (index != 4) {
                      setState(() {
                        CentralStation.updateNeeded = true;
                        _selectedIndex = index;
                      });
                    }
                  },
                  trailing: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: IconButton(
                            icon: Icon(
                              LineAwesomeIcons.trash_o,
                              size: 30,
                              color: Colors.black87,
                            ),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text("Confirm ?"),
                                      content: Text(
                                          "All notes will be deleted permanently and the app will quit."),
                                      actions: <Widget>[
                                        FlatButton(
                                            onPressed: () async {
                                              final dir = Directory(
                                                  'storage/emulated/0/Tizeno');
                                              dir.deleteSync(recursive: true);
                                              await NotesDBHandler().deleteDB();
                                              await NotesDBHandler().initDB();
                                              CentralStation.updateNeeded =
                                                  true;
                                              SystemChannels.platform
                                                  .invokeMethod(
                                                      'SystemNavigator.pop');
                                            },
                                            child: Text("Yes")),
                                        FlatButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("No"))
                                      ],
                                    );
                                  });

                              setState(() {});
                            }),
                      ),
                    ],
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(
                        LineAwesomeIcons.sticky_note_o,
                        size: 30,
                      ),
                      selectedIcon: FaIcon(
                        FontAwesomeIcons.solidStickyNote,
                        color: Colors.black,
                      ),
                      label: Text(
                        'All',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        LineAwesomeIcons.star_o,
                        size: 30,
                      ),
                      selectedIcon: FaIcon(
                        FontAwesomeIcons.solidStar,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Starred',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        LineAwesomeIcons.archive,
                        size: 30,
                      ),
                      selectedIcon: FaIcon(
                        FontAwesomeIcons.archive,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Archived',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black),
                      ),
                    ),
                    NavigationRailDestination(
                      icon: Icon(
                        LineAwesomeIcons.photo,
                        size: 28,
                      ),
                      selectedIcon: FaIcon(
                        FontAwesomeIcons.solidImage,
                        color: Colors.black,
                      ),
                      label: Text(
                        'Images',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.black),
                      ),
                    ),
                  ],
                  selectedIndex: _selectedIndex),
            ),
            Expanded(
              flex: 9,
              child: Stack(
                children: <Widget>[
                  Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.black, width: 2),
                          top: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      height: 1440.h,
                      // width: 604.5.w,
                      child: Center(
                        child: Text(''),
                      )),
                  Container(
                    padding: EdgeInsets.only(top: 8),
                    child: SafeArea(
                      child: _body(),
                      right: true,
                      left: true,
                      top: true,
                      bottom: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    print(notesViewType);
    return Container(
        child: StaggeredGridPage(
      notesViewType: notesViewType,
      selectedIndex: _selectedIndex,
    ));
  }

  void _newNoteTapped(BuildContext ctx) {
    var emptyNote = new Note(
        -1, "", "", DateTime.now(), DateTime.now(), Colors.white, 0, 0, 0);
    Navigator.push(
        ctx, CupertinoPageRoute(builder: (ctx) => NotePage(emptyNote)));
  }

  void _newPhotoNoteTapped(BuildContext ctx) {
    var emptyNote = new Note(
        -1, "", "", DateTime.now(), DateTime.now(), Colors.white, 0, 0, 1);
    Navigator.push(
        ctx, CupertinoPageRoute(builder: (ctx) => PhotoPage(emptyNote)));
  }

  void _toggleViewType() {
    setState(() {
      CentralStation.updateNeeded = true;
      if (notesViewType == viewType.List) {
        notesViewType = viewType.Staggered;
      } else {
        notesViewType = viewType.List;
      }
    });
  }

  List<Widget> _appBarActions() {
    return [
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: IconButton(
            color: Colors.black,
            icon: notesViewType == viewType.List
                ? FaIcon(
                    LineAwesomeIcons.copy,
                    size: 30,
                    color: Colors.black87,
                  )
                : FaIcon(
                    LineAwesomeIcons.list,
                    size: 30,
                    color: Colors.black87,
                  ),
            onPressed: () => _toggleViewType(),
          )),
    ];
  }
}
