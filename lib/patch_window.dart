import 'dart:io';
import 'dart:ui' as ui;
import 'package:ctdm/drawer_options/cup_icons.dart';
import 'package:ctdm/utils/gecko_utils.dart';
import 'package:ctdm/utils/log_utils.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:merge_images/merge_images.dart';
import 'package:path/path.dart' as path;

//import 'package:image/image.dart' as img;

bool isFastBrstm(String path) {
  if (path.endsWith("_f.brstm")) return true;
  if (path.endsWith("_F.brstm")) return true;
  return false;
}

class PatchWindow extends StatefulWidget {
  final String packPath;
  const PatchWindow(this.packPath, {super.key});

  @override
  State<PatchWindow> createState() => _PatchWindowState();
}

enum PatchingStatus { aborted, running, completed }

void completeXmlFile(String packPath) {
  String packName = path.basename(packPath);
  File xmlFile = File(path.join(packPath, "$packName.xml"));
  String contents = xmlFile.readAsStringSync();
  //1 common <folder external="/PACKNAME/Race/Common/xxx" disc="/Race/Common/xxx/" create=true/>
  Directory commonDir = Directory(path.join(packPath, 'Race', 'Common'));
  String commonBigString = "";
  List<Directory> commonDirList =
      commonDir.listSync().whereType<Directory>().toList();
  for (Directory common in commonDirList) {
    commonBigString +=
        '<folder external="/$packName/Race/Common/${path.basename(common.path)}" disc="/Race/Common/${path.basename(common.path)}/" create="true"/>\n\t\t';
  }
  //2 course dir
  Directory courseDir = Directory(path.join(packPath, 'Race', 'Course'));
  String courseBigString = "";
  List<File> courseDirList = courseDir.listSync().whereType<File>().toList();
  for (File course in courseDirList) {
    courseBigString +=
        '<file external="/$packName/Race/Course/${path.basename(course.path)}" disc="/Race/Course/${path.basename(course.path)}" create="true"/>\n\t\t';
  }
  // //3 music dir
  // Directory musicDir = Directory(path.join(packPath, 'Music'));
  // String musicBigString = "";
  // List<File> musicDirList = musicDir.listSync().whereType<File>().toList();
  // for (File music in musicDirList) {
  //   int hex = int.parse(path.basename(music.path).substring(0, 3), radix: 16);
  //   if (hex < 32) {
  //     musicBigString +=
  //         '<file external="/$packName/Music/${path.basename(music.path)}" disc="/sound/strm/${path.basename(music.path)}"/>\n\t\t';
  //   } else {
  //     musicBigString +=
  //         '<file external="/$packName/Music/${path.basename(music.path)}" disc="/sound/strm/${path.basename(music.path)}" create="true"/>\n\t\t';
  //   }
  // }
  contents = contents.replaceFirst(
      RegExp(r'<!--MY COMMONS-->.*<!--END MY TRACKS-->', dotAll: true),
      '<!--MY COMMONS-->\n\t\t$commonBigString$courseBigString<!--END MY TRACKS-->\t\t');
  //print(contents);
  //print(commonBigString);
  //print(courseBigString);
  xmlFile.writeAsStringSync(contents, mode: FileMode.write);
}

List getTracksDirWithCommons(String myTrackPath, List<String> configTrack) {
  Directory myTracks = Directory(myTrackPath);
  List<Directory> fsTracksFolder =
      myTracks.listSync(recursive: false).whereType<Directory>().toList();

  List<String> baseNameWithCommonList = [];
  List<String> commonDirpathList = [];
  for (Directory folder in fsTracksFolder) {
    List<File> tmpFileList = folder.listSync().whereType<File>().toList();

    for (String track in configTrack) {
      if (tmpFileList
          .map((e) => path.basenameWithoutExtension(e.path))
          .contains(track)) {
        baseNameWithCommonList.add(track);
        commonDirpathList.add(path.dirname(tmpFileList
            .firstWhere((element) =>
                path.basenameWithoutExtension(element.path).contains(track))
            .path));
      }
    }
  }
  return [baseNameWithCommonList, commonDirpathList];
}

List<String> checkTracklistInFolder(List<String> trackList, String trackPath) {
  Directory myTracks = Directory(trackPath);
  List<FileSystemEntity> fsTracks = myTracks.listSync(recursive: true);
  List<String> fsTracksPaths = [];
  List<String> missingFiles = [];
  for (FileSystemEntity track in fsTracks) {
    fsTracksPaths.add(path.basenameWithoutExtension(track.path));
  }
  for (var configTrack in trackList) {
    if (!fsTracksPaths.contains(configTrack)) {
      missingFiles.add(configTrack);
    }
  }
  return missingFiles;
}

void createFolders(String packPath) {
  if (!Directory(path.join(packPath, 'Race', 'Course')).existsSync()) {
    Directory(path.join(packPath, 'Race', 'Course')).createSync();
  }
  if (!Directory(path.join(packPath, 'Race', 'Common')).existsSync()) {
    Directory(path.join(packPath, 'Race', 'Common')).createSync();
  }
  if (!Directory(path.join(packPath, 'rel')).existsSync()) {
    Directory(path.join(packPath, 'rel')).createSync();
  }
  if (!Directory(path.join(packPath, 'Scene')).existsSync()) {
    Directory(path.join(packPath, 'Scene')).createSync();
  }
  if (!Directory(path.join(packPath, 'sys')).existsSync()) {
    Directory(path.join(packPath, 'sys')).createSync();
  }
  if (!Directory(path.join(packPath, 'MyCodes')).existsSync()) {
    copyGeckoAssetsToPack(packPath);
  }
  if (!Directory(path.join(packPath, 'codes')).existsSync()) {
    Directory(path.join(packPath, 'codes')).createSync();
    //updateGtcFiles(packPath);
  }
  for (var file in Directory(path.join(packPath, 'rel')).listSync()) {
    file.deleteSync(recursive: true);
  }
  for (var file in Directory(path.join(packPath, 'sys')).listSync()) {
    file.deleteSync(recursive: true);
  }
  Directory(path.join(packPath, 'sys', 'P')).createSync();
  Directory(path.join(packPath, 'sys', 'E')).createSync();
  Directory(path.join(packPath, 'sys', 'J')).createSync();
  Directory(path.join(packPath, 'sys', 'K')).createSync();
}

List<String> getTracksFilenamesFromConfig(String packPath) {
  List<String> dirtyTrackFilenames = [];
  List<String> trackFilenames = [];
  File configFile = File(path.join(packPath, 'config.txt'));
  String contents = configFile.readAsStringSync();
  contents = contents.split(RegExp('N N.*WII'))[1];

  dirtyTrackFilenames = contents.split('\n');
  for (var dirty in dirtyTrackFilenames) {
    if (';'.allMatches(dirty).length == 5 && !dirty.contains((r'0x02;'))) {
      trackFilenames.add(dirty.split(';')[3].replaceAll(r'"', '').trimLeft());
    }
  }
  return trackFilenames;
}

List<String> parseBMGList(String packPath) {
  File trackFile = File(path.join(packPath, 'tracks.bmg.txt'));
  String contents = trackFile.readAsStringSync();
  contents = contents
      .split(RegExp(r'7045.= '))[1]
      .replaceAll(RegExp(r'[0-9]+.= '), '');
  List<String> tracksDirty = contents.split('\n');
  List<String> cleanTracks = [];
  for (var track in tracksDirty) {
    cleanTracks.add(track.trim());
  }
  cleanTracks.removeWhere((element) => element.isEmpty);
  return cleanTracks;
}

Future<String> createBMGList(String packPath) async {
  //genera tracks.bmg.txt
  File trackFile = File(path.join(packPath, 'Scene', 'tracks.bmg.txt'));
  if (trackFile.existsSync()) {
    trackFile.deleteSync();
  }
  try {
    final process = await Process.start(
        'wctct',
        [
          'create',
          'bmg',
          '--le-code',
          '--long',
          path.join(packPath, 'config.txt'),
          '--dest',
          path.join(packPath, 'Scene', 'tracks.bmg.txt')
        ],
        runInShell: false);
    final _ = await process.exitCode;
    //return parseBMGList(packPath);
  } on Exception catch (_) {
    //return [];
  }
  // String contents = trackFile.readAsStringSync();
  // int begin = contents.lastIndexOf(RegExp(r'703e'));
  // int end = contents.lastIndexOf(RegExp(r'7041'));
  // contents = contents.replaceRange(begin, end,
  //     "703e\t= All tracks\n703f\t= Original tracks\n7040\t= Custom tracks\n703e\t= New Tracks\n");
  // //contents.split(RegExp(r'703e.= '))[1].repl
  // contents = contents.replaceFirstMapped(
  //     'beginner_course', (match) => 'Circuito Luigi bro');
  //trackFile.writeAsStringSync(contents, mode: FileMode.write);
  return path.join(packPath, 'Scene', 'tracks.bmg.txt');
  //2 leggi tracks.bmg.txt da 7044
  //3 controlla che i nomi siano nella cartella MyTracks
}

Future<void> editMenuSingle(String workspace, String packPath) async {
  //crea icone
  final File origSingle = File(path.join(
      workspace, 'ORIGINAL_DISC', 'files', 'Scene', 'UI', 'MenuSingle.szs'));

  origSingle.copySync(path.join(packPath, 'Scene', 'MenuSingle.szs'));

  await patchIcons(packPath);

  //return; //REMOVE THIS AFTER TEST
  //1 copia menusingle_E
  //2 crea track.bmg.txt
  //3 decoda menusingle_E.szs-> common.txt
  //4 szs->folder
  //5 edita common.txt
  //6 encoda common.txt -> common.bmg (piazzato in folder)
  //7 folder ->szs

  //1
  final File origMenuFile = File(path.join(
      path.dirname(Platform.resolvedExecutable),
      "data",
      "flutter_assets",
      "assets",
      "scene",
      "MenuSingle_E.szs"));
  // final File origMenuFile = File(path.join(
  //     workspace, 'ORIGINAL_DISC', 'files', 'Scene', 'UI', 'MenuSingle_E.szs'));
  origMenuFile.copySync(path.join(packPath, 'Scene', 'MenuSingle_E.szs'));
  //2
  String bmgFilePath = await createBMGList(packPath);
  final File trackBmgTxt = File(bmgFilePath);
  //3
  try {
    //  wbmgt decode MenuSingle_E.szs
    final process = await Process.start(
        'wbmgt',
        [
          'decode',
          path.join(packPath, 'Scene', 'MenuSingle_E.szs'),
          '--dest',
          path.join(packPath, 'Scene', 'MenuSingle_E.txt'),
        ],
        runInShell: false);

    final _ = await process.exitCode;
  } on Exception catch (_) {
    logString(LogType.ERROR, _.toString());
  }

  //4
  try {
    // wszst extract MenuSingle_E.szs
    final process = await Process.start(
        'wszst',
        [
          'extract',
          path.join(packPath, 'Scene', 'MenuSingle_E.szs'),
          '--dest',
          path.join(packPath, 'Scene', 'MenuSingle_E.d'),
        ],
        runInShell: false);
    final _ = await process.exitCode;
  } on Exception catch (_) {
    logString(LogType.ERROR, _.toString());
  }
  //5
  String contents = trackBmgTxt.readAsStringSync();
  contents = contents.replaceAll(RegExp(r'#BMG'), '');
  File editedMenuFile = File(path.join(packPath, 'Scene', 'MenuSingle_E.txt'));
  editedMenuFile.writeAsString(contents, mode: FileMode.append);
  //6
  try {
    //  wbmgt encode MenuSingle_E.txt
    final process = await Process.start(
        'wbmgt',
        [
          'encode',
          path.join(packPath, 'Scene', 'MenuSingle_E.txt'),
          '--overwrite',
          '--dest',
          path.join(
              packPath, 'Scene', 'MenuSingle_E.d', 'message', 'Common.bmg'),
        ],
        runInShell: false);
    final _ = await process.exitCode;
  } on Exception catch (_) {
    logString(LogType.ERROR, _.toString());
  }
  //7
  try {
    final process = await Process.start(
        'wszst',
        [
          'create',
          path.join(packPath, 'Scene', 'MenuSingle_E.d'),
          '--overwrite',
          '--dest',
          path.join(packPath, 'Scene', 'MenuSingle_E.szs'),
        ],
        runInShell: false);
    final _ = await process.exitCode;
  } on Exception catch (_) {
    logString(LogType.ERROR, _.toString());
  }
}

String getBmgFromFileName(File configFile, String filePath) {
  //print(path.basenameWithoutExtension(filePath));
  String contents = configFile.readAsStringSync();
  int begin = contents.indexOf(path.basenameWithoutExtension(filePath));
  contents = contents.replaceRange(0, begin, '');
  return contents.split(";")[1].replaceAll('"', '').trim();
  //print(contents.split(RegExp(path.basenameWithoutExtension(filePath)))[1]);
  //print(contents.allMatches(path.basenameWithoutExtension(filePath))_;
  //print(
  //    "####################\n${contents.split(path.basenameWithoutExtension(filePath)).removeAt(0)}\n\n");
  //developer.log('log me', name: 'my.app.category');
  //contents = contents.split(path.basenameWithoutExtension(filePath))[1];
  //     .split(';')[1]
  //     .replaceAll('"', '')
  //     .trim();

  //print("${path.basenameWithoutExtension(filePath)}: |$contents|");
}

// void singleTrackCopy(String workspace, String packPath, String szsPath) {
//   bool isDir = path.basename(path.dirname(szsPath)) != "myTracks";
//   if (isDir) {
//     //print("$szsPath is in subdir");
//     File configFile = File(path.join(packPath, 'config.txt'));
//     //guarda il suo id da tracks.bmg.txt
//     String id = getIdFromTracksBmgTxt(
//         path.join(packPath, 'Scene', 'tracks.bmg.txt'),
//         getBmgFromFileName(configFile, szsPath));
//     // getIdFromTracksBmgTxt(path.join(packPath, 'Scene', 'tracks.bmg.txt'),
//     //     path.basenameWithoutExtension(szsPath));

//     Directory(path.join(packPath, 'Race', 'Common', id))
//         .createSync(); //UNCOMMENT

//     Directory(path.dirname(szsPath))
//         .listSync()
//         .whereType<File>()
//         .forEach((file) {
//       if (file.path.endsWith('.bin')) {
//         file.copySync(path.join(
//             packPath, 'Race', 'Common', id, path.basename(file.path)));
//       }
//     });
//     //sposta tutti i file tranne il file szs in Race/Common/xxx/
//   } else {
//     //print("$szsPath is single file");
//   }
//   File(szsPath)
//       .copySync(path.join(packPath, 'Race', 'Course', path.basename(szsPath)));
// }

List<String> getIdFromTracksBmgTxt(List<String> bmgLines, String trackName) {
  List<String> ids = [];
  for (var line in bmgLines) {
    //print(line);
    if (line.contains(trackName)) {
      ids.add(line.trim().replaceRange(0, 1, '').replaceRange(3, null, ''));
    }
  }
  return ids;
}

void trackPathToCommon(
    String workspace, String packPath, List<String> configTrackList) {
  File configFile = File(path.join(packPath, 'config.txt'));
  //print(configTrackList);
  List tracksWithCommon = getTracksDirWithCommons(
      path.join(workspace, 'MyTracks'), configTrackList);
  //print(tracksWithCommon);
  List<String> lines =
      File(path.join(packPath, 'Scene', 'tracks.bmg.txt')).readAsLinesSync();

  int i = 0;
  for (var trackBasename in tracksWithCommon[0]) {
    List<String> ids = getIdFromTracksBmgTxt(
        lines, getBmgFromFileName(configFile, trackBasename));
    for (String id in ids) {
      createSingleCommon(packPath, id, tracksWithCommon[1][i]);
    }
    i++;
  }
}

void createSingleCommon(String packPath, String id, String srcFolderPath) {
  Directory(path.join(packPath, 'Race', 'Common', id)).createSync();

  Directory srcFolder = Directory(srcFolderPath);
  srcFolder.listSync().whereType<File>().forEach((file) {
    if (file.path.endsWith('.bin')) {
      file.copySync(
          path.join(packPath, 'Race', 'Common', id, path.basename(file.path)));
    }
  });
}

// void copyMyTracksToCourseFolder(
//     String workspace, String packPath, List<String> configTrackList) {
//   Directory myTracksDir = Directory(path.join(workspace, 'myTracks'));
//   //List<FileSystemEntity> myTracksList = myTracksDir.listSync(recursive: true).;
//   List<String> myTrackList = myTracksDir
//       .listSync(recursive: true)
//       .whereType<File>()
//       .map((e) => e.path)
//       .toList();
//   //controllo che il nome base senza est della trackList sia nella directory myTrackList
//   for (var configTrack in configTrackList) {
//     if (myTrackList
//         .map((e) => path.basenameWithoutExtension(e))
//         .toList()
//         .contains(configTrack)) {
//       singleTrackCopy(
//           workspace,
//           packPath,
//           myTrackList.firstWhere((element) =>
//               path.basenameWithoutExtension(element) == configTrack));
//     } else {
//       //print("non trovato"); //impossible?
//     }
//   }
// }

Future<void> patchIcons(String packPath) async {
  Directory iconDir = Directory(path.join(packPath, 'Icons'));
  int nCups = getNumberOfIconsFromConfig(packPath);
  if (iconDir.listSync().whereType<File>().length < nCups + 2) {
    logString(LogType.ERROR, "not enough icons to patch");
    return;
  }
  //wszst patch MenuSingle.szs --le-menu --cup-icons ./icons.tpl --links
  try {
    await createBigImage(iconDir, nCups).then((value) => {
          Process.runSync(
              'wszst',
              [
                'patch',
                '--le-menu',
                '--cup-icons',
                path.join(packPath, 'Icons', 'merged.png'),
                '--links',
                path.join(packPath, 'Scene', 'MenuSingle.szs'),
                '--overwrite',
                '--dest',
                path.join(packPath, 'Scene', 'MenuSingle.szs'),
              ],
              runInShell: false),
          File(path.join(packPath, 'Icons', 'merged.png')).deleteSync()
        });
  } on Exception catch (_) {
    logString(LogType.ERROR, _.toString());
  }
}

int compareAlphamagically(File a, File b) {
  if (int.tryParse(path.basenameWithoutExtension(a.path)) == null &&
      int.tryParse(path.basenameWithoutExtension(a.path)) == null) {
    return a.path.compareTo(b.path);
  }
  if (int.tryParse(path.basenameWithoutExtension(a.path)) == null &&
      int.tryParse(path.basenameWithoutExtension(b.path)) != null) {
    return -1;
  }
  if (int.tryParse(path.basenameWithoutExtension(a.path)) != null &&
      int.tryParse(path.basenameWithoutExtension(b.path)) == null) {
    return 1;
  }
  return int.parse(path.basenameWithoutExtension(a.path))
      .compareTo(int.parse(path.basenameWithoutExtension(b.path)));
}

Future<File> createBigImage(Directory iconDir, int nCups) async {
  List<ui.Image> imageList = [];
  List<File> iconFileList = iconDir.listSync().whereType<File>().toList();
  iconFileList.sort((a, b) => compareAlphamagically(a, b));
  for (File icon in iconFileList) {
    imageList.add(await ImagesMergeHelper.loadImageFromFile(icon));
  }

  ui.Image image = await ImagesMergeHelper.margeImages(imageList,
      fit: true, direction: Axis.vertical, backgroundColor: Colors.transparent);

  final data = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );

  final bytes = data!.buffer.asUint8List();

  File mergedFile = File(path.join(iconDir.path, 'merged.png'));
  mergedFile = await mergedFile.writeAsBytes(bytes, flush: true);

  return mergedFile;
}

class _PatchWindowState extends State<PatchWindow> {
  late List<String> missingTracks = [];
  PatchingStatus patchStatus = PatchingStatus.running;
  String progressText = 'creating folder';
  @override
  void initState() {
    patch(widget.packPath);
    super.initState();
  }

  void patch(String packPath) async {
    createFolders(packPath);
    setState(() {
      progressText = "creating gecko codes";
    });
    updateGtcFiles(packPath);
    patchStatus = PatchingStatus.running;
    //1 CHECK TRACKS FILES
    //wipeOldFiles(packPath);
    setState(() {
      progressText = "checking for missing tracks";
    });
    String workspace = path.dirname(path.dirname(packPath));
    List<String> trackList =
        getTracksFilenamesFromConfig(packPath).toSet().toList();
    setState(() {
      missingTracks =
          checkTracklistInFolder(trackList, path.join(workspace, 'MyTracks'));
    });

    if (missingTracks.isNotEmpty) {
      patchStatus = PatchingStatus.aborted;
      return;
    }

    //2 EDIT MENU_SINGLE
    setState(() {
      progressText = "patching the game menu";
    });
    await editMenuSingle(workspace, packPath);
    //1.5 create and polulate Race/Common
    trackPathToCommon(workspace, packPath, trackList);
    Directory(path.join(packPath, 'Scene', 'MenuSingle_E.d'))
        .deleteSync(recursive: true);

    File(path.join(packPath, 'Scene', 'MenuSingle_E.txt')).deleteSync();
    File(path.join(packPath, 'Scene', 'tracks.bmg.txt')).deleteSync();
    //4 FINALLY PATCHING
    //4a)copy lecode-VER.bin in rel
    //4b)wlect patch lecode-PAL.bin -od lecode-PAL.bin --le-define config.txt --track-dir .
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      progressText = "copying the lecode loader ";
    });

    // String isoVersion = prefs.getString('isoVersion')!;
    // String lecodePath = path.join(
    //     path.dirname(Platform.resolvedExecutable),
    //     "data",
    //     "flutter_assets",
    //     "assets",
    //     "lecode_build",
    //     "lecode-$isoVersion.bin");
    // File(lecodePath)
    //     .copySync(path.join(packPath, 'rel', "lecode-$isoVersion.bin"));

    setState(() {
      progressText = "copying tracks";
    });
    List<File> szsFileList = Directory(path.join(workspace, 'MyTracks'))
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
    szsFileList.retainWhere((element) => element.path.endsWith('.szs'));
    szsFileList.retainWhere((element) =>
        trackList.contains(path.basenameWithoutExtension(element.path)));
    // Directory(path.join(packPath, 'Race', 'Course', 'tmp')).createSync();
    // for (File szs in szsFileList) {
    //   szs.copySync(path.join(
    //       packPath, 'Race', 'Course', 'tmp', path.basename(szs.path)));
    // }
    setState(() {
      progressText = "patching lecode loader with tracks";
    });
    for (GameVersion gv in fileMap.keys) {
      //if (gv != GameVersion.PAL) continue; //DEBUG TEST
      Directory(path.join(packPath, 'Race', 'Course', 'tmp')).createSync();
      for (File szs in szsFileList) {
        szs.copySync(path.join(
            packPath, 'Race', 'Course', 'tmp', path.basename(szs.path)));
      }

      String isoVersion = gv.name;
      String lecodePath = path.join(
          path.dirname(Platform.resolvedExecutable),
          "data",
          "flutter_assets",
          "assets",
          "lecode_build",
          "lecode-$isoVersion.bin");
      File(lecodePath)
          .copySync(path.join(packPath, 'rel', "lecode-$isoVersion.bin"));
      try {
        //  wlect patch lecode-PAL.bin -od lecode-PAL.bin --le-define config.txt --track-dir .
        Process.runSync(
            'wlect',
            [
              'patch',
              path.join(packPath, 'rel', "lecode-$isoVersion.bin"),
              '--overwrite',
              '--dest',
              path.join(packPath, 'rel', "lecode-$isoVersion.bin"),
              '--le-define',
              path.join(packPath, 'config.txt'),
              '--track-dir',
              path.join(packPath, 'Race', 'Course'),
              '--copy-tracks',
              path.join(packPath, 'Race', 'Course', 'tmp'),
            ],
            runInShell: false);
        // final _ = await process.exitCode;
        //stdout.addStream(process.stdout);
        //stderr.addStream(process.stderr);
        //print(process.stdout);
        //print(process.stderr);
      } on Exception catch (_) {
        logString(LogType.ERROR, _.toString());
        //print(_);
      }
      //forse mettere
      Directory(path.join(packPath, 'Race', 'Course', 'tmp'))
          .deleteSync(recursive: true);
      try {
        // wlect patch lecode-PAL.bin --lpar lpar.txt
        Process.runSync(
            'wlect',
            [
              'patch',
              path.join(packPath, 'rel', "lecode-$isoVersion.bin"),
              '--overwrite',
              '--dest',
              path.join(packPath, 'rel', "lecode-$isoVersion.bin"),
              '--lpar',
              path.join(packPath, 'lpar.txt'),
            ],
            runInShell: false);
        //final _ = await process.exitCode;
        //print(process.stdout);
        //print(process.stderr);
        // stdout.addStream(process.stdout);
        // stderr.addStream(process.stderr);
      } on Exception catch (_) {
        logString(LogType.ERROR, _.toString());
        //print(_);
      }
    }
    //move main.dol and patch it
    // File(path.join(workspace, 'ORIGINAL_DISC', 'sys', 'main.dol'))
    //     .copySync(path.join(packPath, 'sys', 'main.dol'));
    setState(() {
      progressText = "patching main.dol";
    });
    for (GameVersion gv in fileMap.keys) {
      String letter = getLetterFromGameVersion(gv);
      File dolFile = File(path.join(path.dirname(Platform.resolvedExecutable),
          "data", "flutter_assets", "assets", "dols", "$letter.dol"));
      if (File(path.join(packPath, 'sys', letter, "main.dol")).existsSync()) {
        File(path.join(packPath, 'sys', letter, "main.dol")).deleteSync();
      }
      dolFile.copySync(path.join(packPath, 'sys', letter, "main.dol"));
      try {
        // wstrt patch --add-lecode main.dol
        final process = await Process.start(
            'wstrt',
            [
              'patch',
              '--add-lecode',
              path.join(packPath, 'sys', letter, "main.dol"),
              '--add-section',
              path.join(packPath, 'codes', fileMap[gv]),
              '--overwrite',
              '--dest',
              path.join(packPath, 'sys', letter, "main.dol"),
            ],
            runInShell: false);
        final _ = await process.exitCode;
        // stdout.addStream(process.stdout);
        // stderr.addStream(process.stderr);
      } on Exception catch (_) {
        //print(_);
        logString(LogType.ERROR, _.toString());
      }
    }

    //copy music
    setState(() {
      progressText = "copying music files";
    });
    copyMusic(packPath);
    setState(() {
      progressText = "editing xml file";
    });
    completeXmlFile(packPath);
    setState(() {
      patchStatus = PatchingStatus.completed;
    });
  }

  void copyMusic(packPath) {
    File musicTxt = File(path.join(packPath, "music.txt"));
    Directory musicDir = Directory(path.join(packPath, 'Music'));
    if (musicDir.existsSync()) {
      musicDir.deleteSync(recursive: true);
    }
    musicDir.createSync();
    if (!musicTxt.existsSync()) return;
    List<String> tracksWithMusicHex = [];
    Directory workspaceMyMusic =
        Directory(path.join(path.dirname(path.dirname(packPath)), 'myMusic'));
    for (String line in musicTxt.readAsLinesSync()) {
      tracksWithMusicHex.add(line.substring(0, 3));

      Directory mDir =
          Directory(path.join(workspaceMyMusic.path, line.substring(4)));
      File fastFile = mDir
          .listSync()
          .whereType<File>()
          .firstWhere((element) => isFastBrstm(element.path));
      File normalFile = mDir
          .listSync()
          .whereType<File>()
          .firstWhere((element) => !isFastBrstm(element.path));

      //copia i due file
      normalFile
          .copySync(path.join(musicDir.path, '${line.substring(0, 3)}.brstm'));
      fastFile.copySync(
          path.join(musicDir.path, '${line.substring(0, 3)}_f.brstm'));
      //File(path.join(workspaceMyMusic.path,)).copySync(musicDir.path, line.substring(0, 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Patch window",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.amber,
          iconTheme: IconThemeData(color: Colors.red.shade700),
        ),
        body: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Center(
              //     child: Text(patchStatus == PatchingStatus.running
              //         ? "patching..."
              //         : "Patch Completed!")),
              Center(
                  child: Column(children: [
                patchStatus == PatchingStatus.running
                    ? Text("Patching...",
                        style: TextStyle(
                            fontSize: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.fontSize))
                    : patchStatus == PatchingStatus.completed
                        ? Text("Patch is completed",
                            style: TextStyle(
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.fontSize))
                        : const Text(''),
                if (patchStatus == PatchingStatus.running)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        LoadingAnimationWidget.fourRotatingDots(
                            color: Colors.amberAccent, size: 50),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            progressText,
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.fontSize),
                          ),
                        )
                      ],
                    ),
                  )
              ])),
              Visibility(
                visible: missingTracks.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Wrap(
                    children: [
                      Center(
                        child: Text(
                          "ERROR: TRACK FILES NOT FOUND",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              backgroundColor: Colors.red,
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.fontSize),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "the following tracks were not found in MyTracks folder:",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.fontSize),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width / 3,
                            height: 300,
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: missingTracks.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                        color: Colors.amber.shade300,
                                        border: Border.all(
                                          color: Colors.black,
                                        )),
                                    child: SelectableText(
                                      "${missingTracks[index]}.szs",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                  );
                                }),
                          ),
                        ),
                      ),
                      Visibility(
                          visible: patchStatus == PatchingStatus.aborted,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 30.0),
                              child: Text(
                                "the patching process has been stopped.",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.fontSize),
                              ),
                            ),
                          ))
                    ],
                  ),
                ),
              )
            ])));
  }
}
