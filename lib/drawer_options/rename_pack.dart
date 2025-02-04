import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

void saveAndRenamePack(
    String packPath, String chosenName, String chosenId, String isoVersion) {
  //1: se non esiste xml-> copia Pack.xml
  //2 crivo contenuto xml
  //3: rinomina xml
  //4: rinomino folder

  Directory dir = Directory(packPath);
  List<FileSystemEntity> entities = dir.listSync().toList();
  Iterable<File> xmlList = entities
      .whereType<File>()
      .where((element) => element.path.endsWith('.xml'));

  if (xmlList.isEmpty) {
    createXmlFile(path.join(packPath, 'Pack.xml'));
  }
  //2
  dir = Directory(packPath);
  entities = dir.listSync().toList();
  xmlList = entities
      .whereType<File>()
      .where((element) => element.path.endsWith('.xml'));
  File xmlFile = xmlList.first;
  replaceParamsInXml(xmlFile, chosenName, chosenId, isoVersion);
  //3
  xmlFile.renameSync(path.join(packPath, "$chosenName.xml"));
  //4
  dir.renameSync(path.join(path.dirname(packPath), chosenName));
}

void createXmlFile(String xmlPath) {
  String assetPath = path.join(path.dirname(Platform.resolvedExecutable),
      "data", "flutter_assets", "assets");

  File(path.join(assetPath, 'Pack.xml')).copySync(xmlPath);
  // Directory assetFolder = Directory(assetPath);
  // List<File> xmlFileList = assetFolder.listSync().whereType<File>().toList();
  // xmlFileList.retainWhere((element) => element.path.endsWith('xml'));

  // xmlFileList.first.copySync(xmlPath);
  //final File xmlFile = File("assets/Pack.xml");
  //xmlFile.copySync(xmlPath);
}

void replaceParamsInXml(
    File xmlFile, String chosenName, String chosenId, String isoVersion) {
  String contents = xmlFile.readAsStringSync();
  // final versionRegex = RegExp(r'-[A-Z]+.bin');

  // contents = contents.replaceAll(versionRegex, '-$isoVersion.bin');
  String oldName = contents.split(RegExp(r'<section name='))[1];
  oldName =
      oldName.replaceRange(oldName.indexOf('>'), null, '').replaceAll('"', '');
  String oldId = contents.split(RegExp(r'patch id='))[1];

  oldId = oldId.replaceRange(oldId.indexOf(r'/'), null, '').replaceAll('"', '');
  //contents = contents.replaceAll(versionRegex, '-$isoVersion.bin');
  contents = contents.replaceAll(oldName, chosenName);
  contents = contents.replaceAll(oldId, chosenId);
  xmlFile.writeAsStringSync(contents, mode: FileMode.write);
}

class RenamePack extends StatefulWidget {
  final String packPath;
  const RenamePack(this.packPath, {super.key});

  @override
  State<RenamePack> createState() => _RenamePackState();
}

bool checkValidTextfield(String name, String id) {
  final validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');

  if (name == '' || name == 'MyPackName' || !validCharacters.hasMatch(name)) {
    return false;
  }
  if (id == '' || id == 'mypack_uniquename' || !validCharacters.hasMatch(id)) {
    return false;
  }
  return true;
}

class _RenamePackState extends State<RenamePack> {
  late bool enableSaveBtn = false;
  late String packNameChosen = '';
  late String packIdChosen = '';
  late TextEditingController _chosenNameController;
  late TextEditingController _chosenIdController;
  late SharedPreferences prefs;
  late String isoVersion = 'PAL';

  void getIsoVersion() async {
    prefs = await SharedPreferences.getInstance();
    isoVersion = prefs.getString('isoVersion')!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.packPath.contains('tmp_pack_')) {
      packNameChosen = 'MyPackName';
      packIdChosen = 'mypack_uniquename';
    } else {
      packNameChosen = path.basename(widget.packPath);
      final String xmlPath = path.join(widget.packPath, '$packNameChosen.xml');
      File xmlFile = File(xmlPath);
      if (xmlFile.existsSync()) {
      } else {
        createXmlFile(xmlPath);
      }
      String contents = xmlFile.readAsStringSync();
      packIdChosen = contents.split(RegExp(r'patch id='))[1];

      packIdChosen = packIdChosen
          .replaceRange(packIdChosen.indexOf(r'/'), null, '')
          .replaceAll('"', '');
    }
    _chosenNameController = TextEditingController.fromValue(
      TextEditingValue(
        text: packNameChosen, //path.basename(widget.packPath),
      ),
    );
    _chosenNameController = TextEditingController.fromValue(
      TextEditingValue(
        text: packNameChosen, //path.basename(widget.packPath),
      ),
    );
    _chosenIdController = TextEditingController.fromValue(
      TextEditingValue(
        text: packIdChosen, //path.basename(widget.packPath),
      ),
    );

    getIsoVersion();
  }

  @override
  void dispose() {
    _chosenNameController.dispose();
    _chosenIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Pack name",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber,
          iconTheme: IconThemeData(color: Colors.red.shade700),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.5,
              height: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "please choose your pack name and id",
                    style: TextStyle(
                        fontSize: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.fontSize),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "pack name:",
                            style: TextStyle(color: Colors.white54),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2 - 15,
                            child: TextField(
                                onChanged: (newvalue) => {
                                      packNameChosen = newvalue,
                                      setState(() => {
                                            enableSaveBtn = checkValidTextfield(
                                                packNameChosen, packIdChosen),
                                          }),
                                    },
                                style: const TextStyle(color: Colors.redAccent),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                autofocus: false,
                                keyboardType: TextInputType.multiline,
                                maxLines: 1,
                                controller: _chosenNameController),
                          ),
                          const Tooltip(
                            message: "basically the name of the folder",
                            child: IconButton(
                                icon: Icon(Icons.info), onPressed: null),
                          )
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "patch id:",
                          style: TextStyle(color: Colors.white54),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: TextField(
                              //onEditingComplete: () => print("editin complete"),
                              // onSubmitted: (value) => print('submitted'),
                              onChanged: (newvalue) => {
                                    packIdChosen = newvalue,
                                    setState(() => {
                                          enableSaveBtn = checkValidTextfield(
                                              packNameChosen, packIdChosen)
                                        }),
                                  },
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              autofocus: false,
                              keyboardType: TextInputType.multiline,
                              maxLines: 1,
                              controller: _chosenIdController),
                        ),
                        const Tooltip(
                          message:
                              "the ID riivolution will use to identify your pack",
                          child: IconButton(
                              icon: Icon(Icons.info), onPressed: null),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: ElevatedButton(
                        style: ButtonStyle(
                            fixedSize:
                                MaterialStateProperty.all(const Size(150, 50))),
                        onPressed: enableSaveBtn
                            ? () => {
                                  saveAndRenamePack(widget.packPath,
                                      packNameChosen, packIdChosen, isoVersion),
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MyApp(),
                                    ),
                                  )
                                }
                            : null,
                        child: const Text("SAVE")),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
