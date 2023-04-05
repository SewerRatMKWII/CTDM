//import 'dart:io';

// ignore_for_file: must_be_immutable

import 'package:ctdm/gui_elements/types.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class CupTableRow extends StatefulWidget {
  late Track track;
  late String packPath;
  late int cupIndex = -1;
  late int rowIndex = -1;
  late bool canDeleteTracks = false;

  late MaterialAccentColor color = Colors.purpleAccent;
  CupTableRow(this.track, this.cupIndex, this.rowIndex, this.packPath,
      this.canDeleteTracks,
      {super.key});

  @override
  State<CupTableRow> createState() => _CupTableRowState();
}

class _CupTableRowState extends State<CupTableRow> {
  late TextEditingController trackNameTextField;
  late TextEditingController trackslotTextField;
  String? musicFolder = "select music";
  @override
  void initState() {
    setColor();
    super.initState();
    trackNameTextField = TextEditingController();
    trackNameTextField.text = widget.track.name;
    trackslotTextField = TextEditingController();
    trackslotTextField.text = widget.track.slotId.toString();
  }

  void setColor() {
    switch (widget.track.type) {
      case TrackType.base:
        widget.color = Colors.amberAccent;
        break;
      case TrackType.menu:
        widget.color = Colors.limeAccent;
        break;
      case TrackType.hidden:
        widget.color = Colors.amberAccent;
        break;
    }
  }

  @override
  void dispose() {
    trackNameTextField.dispose();
    trackslotTextField.dispose();
    super.dispose();
  }

  List returnValues() {
    //widget.track.slotId=
    return [widget.track, musicFolder];
  }

  @override
  Widget build(BuildContext context) {
    trackNameTextField.text = widget.track.name;
    //trackslotTextField.text = widget.track.slotId.toString();
    setColor();
    FilePickerResult? result;
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black), color: widget.color),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: TextField(
                          controller: trackNameTextField,
                          onChanged: (value) => {
                            widget.track.name = value,
                            RowChangedValue(widget.track, widget.cupIndex,
                                    widget.rowIndex)
                                .dispatch(context)
                          },
                          //widget.track.name,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Visibility(
                          visible: widget.canDeleteTracks == true,
                          child: IconButton(
                              onPressed: () => {
                                    //print("sono row: ${widget.rowIndex}"),
                                    //setState(() => {canDelete = !canDelete}),
                                    //print("row at:${widget.rowIndex}"),
                                    RowDeletePressed(
                                            widget.cupIndex, widget.rowIndex)
                                        .dispatch(context)
                                  },
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.redAccent)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Center(
                child: TextField(
                  controller: trackslotTextField,
                  onChanged: (value) => {
                    if (int.tryParse(value) == null)
                      {}
                    else
                      {
                        widget.track.slotId = int.tryParse(value)!,
                        widget.track.musicId = int.tryParse(value)!,
                        RowChangedValue(
                                widget.track, widget.cupIndex, widget.rowIndex)
                            .dispatch(context)
                      }
                  },
                  style: const TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.allow(RegExp(r'[1-4]'))
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: InkWell(
                    onTap: () async => {
                      result = await FilePicker.platform.pickFiles(
                          allowedExtensions: ['szs'],
                          type: FileType.custom,
                          initialDirectory: path.join(
                              widget.packPath, '..', '..', 'MyTracks')),
                      if (result != null)
                        {
                          if (result?.files.single.path != null)
                            {
                              widget.track.path = path.basenameWithoutExtension(
                                  result?.files.single.path as String),
                              RowChangedValue(widget.track, widget.cupIndex,
                                      widget.rowIndex)
                                  .dispatch(context)
                            }
                        },
                      setState(() {}),
                    },
                    child: Text(
                      widget.track.path,
                      textAlign: TextAlign.start,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    width: 300.0,
                    child: TextButton(
                      onPressed: () async => {
                        musicFolder = await FilePicker.platform
                            .getDirectoryPath(
                                initialDirectory:
                                    path.dirname(path.dirname(widget.packPath)),
                                dialogTitle: 'select music folder'),
                        if (musicFolder == null)
                          {
                            musicFolder = "select music",
                          }
                        else
                          {
                            //controllo se stringa è numero slot o folder
                            if (RegExp(r'^[1-4][1-4]$').hasMatch(musicFolder!))
                              {
                                musicFolder = "select music",
                                widget.track.slotId = int.parse(musicFolder!)
                              }
                            else
                              {
                                widget.track.musicFolder =
                                    path.basename(musicFolder!)
                              }
                          },
                        RowChangedValue(
                                widget.track, widget.cupIndex, widget.rowIndex)
                            .dispatch(context),
                        setState(() => {})
                      },
                      child: Text(
                        path.basename(musicFolder!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
