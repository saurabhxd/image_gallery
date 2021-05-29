import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

GlobalKey<_MediaGridState> globalKey = GlobalKey();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final dateController = TextEditingController();
  var date;
  var pickedStartDate;
  var pickedEndDate;

  @override
  void dispose() {
    // Clean up the controller when the widget is removed
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Gallery'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 200.0,
                  child: TextField(
                    controller: dateController,
                    textAlign: TextAlign.center,
                    readOnly: true,
                    decoration:
                        InputDecoration(hintText: 'Enter Start and End Date'),
                    onTap: () async {
                      date = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100));
                      dateController.text =
                          '${DateFormat('yyyy/MM/dd').format(date.start).toString()} - ${DateFormat('yyyy/MM/dd').format(date.end).toString()}';
                      pickedStartDate = date.start;
                      pickedEndDate = date.end;
                    },
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (pickedStartDate == null && pickedEndDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Enter Start and end Date',
                            style: TextStyle(color: Colors.black)),
                        duration: Duration(microseconds: 500),
                      ));
                    } else {
                      setState(() {
                        globalKey.currentState.fetchNewMedia();
                      });
                    }
                  },
                  child: Text(
                    'Show Photos',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(
                  height: 50.0,
                ),
                Container(
                  child: Text(
                    'Photos:',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                  ),
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(
                  height: 20.0,
                ),
                MediaGrid(
                  key: globalKey,
                  startDate: pickedStartDate,
                  endDate: pickedEndDate,
                )
              ],
            ),
          ),
        ));
  }
}

class MediaGrid extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  MediaGrid({this.startDate, this.endDate, Key key}) : super(key: key);

  @override
  _MediaGridState createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  List<Widget> _mediaList = [];
  int currentPage = 0;
  int lastPage;

  void fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermission();
    if (result) {
      // success
      //load the album list
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          createTimeCond:
              DateTimeCond(min: widget.startDate, max: widget.endDate),
        ),
      );
      print(albums);
      List<AssetEntity> media =
          await albums[0].getAssetListRange(start: 0, end: 100);
      print(media);
      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder(
            future: asset.thumbDataWithSize(200, 200),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 5, bottom: 5),
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Container();
            },
          ),
        );
        _mediaList.clear();
      }

      setState(() {
        _mediaList.addAll(temp);
        temp.clear();
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
          itemCount: _mediaList.length,
          shrinkWrap: true,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
          itemBuilder: (BuildContext context, int index) {
            return _mediaList[index];
          }),
    );
  }
}
