import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share/share.dart';
import 'package:flutter/services.dart';

import '../data/SqliteHandler.dart';
import '../data/notes.dart';
import '../data/utility.dart';
import '../ui/options_sheet.dart';

class NotePage extends StatefulWidget {
  final Note noteInEditing;

  NotePage(this.noteInEditing);

  @override
  _NotePageState createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  var noteColor;
  bool _isNewNote = false;
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _titleFrominitial;
  String _contentFromInitial;
  DateTime _lastEditedForUndo;

  var _editableNote;

  Timer _persistenceTimer;

  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _editableNote = widget.noteInEditing;
    _titleController.text = _editableNote.title;
    _contentController.text = _editableNote.content;
    noteColor = _editableNote.noteColor;
    _lastEditedForUndo = widget.noteInEditing.dateLastEdited;

    _titleFrominitial = widget.noteInEditing.title;
    _contentFromInitial = widget.noteInEditing.content;
    if (widget.noteInEditing.id == -1) {
      _isNewNote = true;
    }
    _persistenceTimer = new Timer.periodic(Duration(seconds: 5), (timer) {
      // call insert query here
      print("5 seconds passed");
      print("editable note id: ${_editableNote.id}");
      _persistData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editableNote.id == -1 && _editableNote.title.isEmpty) {
      // FocusScope.of(context).requestFocus(_titleFocus);
    }

    return WillPopScope(
      child: Scaffold(
        backgroundColor: noteColor,
        // resizeToAvoidBottomInset: false,
        key: _globalKey,
        appBar: AppBar(
          brightness: Brightness.light,
          leading: BackButton(
            color: Colors.black,
          ),
          actions: _archiveAction(context),
          elevation: 1,
          backgroundColor: noteColor == Colors.white ? Colors.amber : noteColor,
          title: _pageTitle(),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.black),
              borderRadius: BorderRadius.circular(100)),
          child: FloatingActionButton(
            key: Key('Done'),
            heroTag: 'FAB',
            elevation: 0,
            onPressed: () {
              // CentralStation.updateNeeded = true;
              _readyToPop();
              Navigator.pop(context);
            },
            child: Icon(Icons.check),
          ),
        ),
        body: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: _body(context)),
      ),
      onWillPop: _readyToPop,
    );
  }

  Widget _body(BuildContext ctx) {
    ScreenUtil.init(context, width: 720, height: 1440, allowFontScaling: true);
    return Scrollbar(
      child: SingleChildScrollView(
        child: SizedBox(
          height: 1290.h,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(5),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                      hintText: "Heading",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 0)),
                  onChanged: (str) {
                    updateNoteObject();
                  },
                  maxLines: null,
                  controller: _titleController,
                  focusNode: _titleFocus,
                  style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w600),
                  cursorColor: Colors.blue,
                ),
              ),
              Divider(
                color: Colors.black45,
              ),
              Expanded(
                  child: Container(
                padding: EdgeInsets.only(left: 0, right: 0, top: 12),
                child: TextField(
                  key: Key('BodyText'),
                  autofocus: false,
                  decoration: InputDecoration(
                      hintText: "Body",
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 0)),
                  onChanged: (str) {
                    updateNoteObject();
                  },
                  maxLines: 99999,
                  // line limit extendable later
                  controller: _contentController,
                  focusNode: _contentFocus,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  // backgroundCursorColor: Colors.red,
                  cursorColor: Colors.blue,
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageTitle() {
    return Text(
      _editableNote.id == -1 ? "New Note" : "Edit Note",
      style: GoogleFonts.montserrat(),
    );
  }

  List<Widget> _archiveAction(BuildContext context) {
    List<Widget> actions = [];
    if (widget.noteInEditing.id != -1) {
      actions.add(IconButton(
        icon: Icon(Icons.undo),
        color: Colors.black45,
        onPressed: () => _undo(),
      ));
    }
    actions += [
      IconButton(
        icon: (_editableNote.isArchived == 0)
            ? Icon(Icons.archive)
            : Icon(Icons.archive),
        color: Colors.black45,
        onPressed: () => _archivePopup(context),
      ),
      IconButton(
        icon: (_editableNote.isStarred == 0)
            ? Icon(Icons.star_border)
            : Icon(Icons.star),
        color: Colors.black45,
        onPressed: () => (_editableNote.isStarred == 0)
            ? _starThisNote(context)
            : _unStarThisNote(context),
      ),
      IconButton(
        icon: Icon(Icons.more_vert),
        color: Colors.black45,
        onPressed: () => bottomSheet(context),
      ),
    ];
    return actions;
  }

  void bottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext ctx) {
          return MoreOptionsSheet(
            color: noteColor,
            callBackColorTapped: _changeColor,
            callBackOptionTapped: bottomSheetOptionTappedHandler,
            dateLastEdited: _editableNote.dateLastEdited,
          );
        });
  }

  void _persistData() {
    updateNoteObject();

    if (_editableNote.content.isNotEmpty) {
      var noteDB = NotesDBHandler();

      if (_editableNote.id == -1) {
        Future<int> autoIncrementedId = noteDB.insertNote(_editableNote, true);
        autoIncrementedId.then((value) {
          _editableNote.id = value;
        });
      } else {
        noteDB.insertNote(
            _editableNote, false); // for updating the existing note
      }
    }
  }

  void updateNoteObject() {
    _editableNote.content = _contentController.text;
    _editableNote.title = _titleController.text;
    _editableNote.noteColor = noteColor;
    print("new content: ${_editableNote.content}");
    print(widget.noteInEditing);
    print(_editableNote);

    print("same title? ${_editableNote.title == _titleFrominitial}");
    print("same content? ${_editableNote.content == _contentFromInitial}");

    if (!(_editableNote.title == _titleFrominitial &&
            _editableNote.content == _contentFromInitial) ||
        (_isNewNote)) {
      // No changes to the note
      // Change last edit time only if the content of the note is mutated in compare to the note which the page was called with.
      _editableNote.dateLastEdited = DateTime.now();
      print("Updating dateLastEdited");
      setState(() {
        CentralStation.updateNeeded = true;
      });
    }
  }

  void bottomSheetOptionTappedHandler(moreOptions tappedOption) {
    print("option tapped: $tappedOption");
    switch (tappedOption) {
      case moreOptions.delete:
        {
          if (_editableNote.id != -1) {
            _deleteNote(_globalKey.currentContext);
          } else {
            _exitWithoutSaving(context);
          }
          break;
        }

      case moreOptions.share:
        {
          if (_editableNote.content.isNotEmpty) {
            Share.share("${_editableNote.title}\n${_editableNote.content}");
          }
          break;
        }
      case moreOptions.copy:
        {
          _copy();
          break;
        }
    }
  }

  void _deleteNote(BuildContext context) {
    if (_editableNote.id != -1) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm ?"),
              content: Text("This note will be deleted permanently"),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      _persistenceTimer.cancel();
                      var noteDB = NotesDBHandler();
                      Navigator.of(context).pop();
                      noteDB.deleteNote(_editableNote);
                      CentralStation.updateNeeded = true;
                      Navigator.of(context).pop();
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
    }
  }

  void _changeColor(Color newColorSelected) {
    print("note color changed");
    setState(() {
      noteColor = newColorSelected;
      _editableNote.noteColor = newColorSelected;
    });
    _persistColorChange();
    CentralStation.updateNeeded = true;
  }

  void _persistColorChange() {
    if (_editableNote.id != -1) {
      var noteDB = NotesDBHandler();
      _editableNote.noteColor = noteColor;
      noteDB.insertNote(_editableNote, false);
    }
  }

  Future<bool> _readyToPop() async {
    _persistenceTimer.cancel();

    _persistData();
    return true;
  }

  void _archivePopup(BuildContext context) {
    if (_editableNote.isArchived == 0) {
      if (_editableNote.id != -1) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Confirm ?"),
                content: Text("This note will be archived"),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => _archiveThisNote(context),
                      child: Text("Yes")),
                  FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("No"))
                ],
              );
            });
      } else {
        _exitWithoutSaving(context);
      }
    } else {
      if (_editableNote.id != -1) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Confirm ?"),
                content: Text("This note will be unarchived"),
                actions: <Widget>[
                  FlatButton(
                      onPressed: () => _unArchiveThisNote(context),
                      child: Text("Yes")),
                  FlatButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("No"))
                ],
              );
            });
      } else {
        _exitWithoutSaving(context);
      }
    }
  }

  void _exitWithoutSaving(BuildContext context) {
    _persistenceTimer.cancel();
    CentralStation.updateNeeded = false;
    Navigator.of(context).pop();
  }

  void _archiveThisNote(BuildContext context) {
    Navigator.of(context).pop();

    _editableNote.isArchived = 1;
    _editableNote.isStarred = 0;
    var noteDB = NotesDBHandler();
    noteDB.archiveNote(_editableNote);
    CentralStation.updateNeeded = true;
    _globalKey.currentState.showSnackBar(new SnackBar(
      content: Text("Archived"),
      duration: Duration(milliseconds: 500),
    ));
  }

  void _starThisNote(BuildContext context) {
    setState(() {
      _editableNote.isStarred = 1;
      _editableNote.isArchived = 0;
    });
    var noteDB = NotesDBHandler();
    noteDB.starNote(_editableNote);
    // update will be required to remove the archived note from the staggered view
    CentralStation.updateNeeded = true;
    _globalKey.currentState.showSnackBar(new SnackBar(
        content: Text("Starred"), duration: Duration(milliseconds: 500)));
  }

  void _unArchiveThisNote(BuildContext context) {
    Navigator.of(context).pop();
    _editableNote.isArchived = 0;
    var noteDB = NotesDBHandler();
    noteDB.archiveNote(_editableNote);
    CentralStation.updateNeeded = true;
    _globalKey.currentState.showSnackBar(new SnackBar(
        content: Text("Unarchived"), duration: Duration(milliseconds: 500)));
  }

  void _unStarThisNote(BuildContext context) {
    setState(() {
      _editableNote.isStarred = 0;
    });
    var noteDB = NotesDBHandler();
    noteDB.starNote(_editableNote);
    CentralStation.updateNeeded = true;
    _globalKey.currentState.showSnackBar(new SnackBar(
        content: Text("Unstarred"), duration: Duration(milliseconds: 500)));
  }

  void _copy() {
    var noteDB = NotesDBHandler();
    Note copy = Note(-1, _editableNote.title, _editableNote.content,
        DateTime.now(), DateTime.now(), _editableNote.noteColor, 0, 0, 0);

    var status = noteDB.copyNote(copy);
    status.then((query_success) {
      if (query_success) {
        CentralStation.updateNeeded = true;
        Navigator.of(_globalKey.currentContext).pop();
      }
    });
  }

  void _undo() {
    _titleController.text = _titleFrominitial; // widget.noteInEditing.title;
    _contentController.text =
        _contentFromInitial; // widget.noteInEditing.content;
    _editableNote.dateLastEdited =
        _lastEditedForUndo; // widget.noteInEditing.dateLastEdited;
  }
}
