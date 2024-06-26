import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:houses_olx/house/components/card.dart' show customHouseCard;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'components/appbar.dart';

class HouseScreen extends StatefulWidget {
  final String pageInfo;
  const HouseScreen({
    Key? key,
    required this.pageInfo,
  }) : super(key: key);
  @override
  _HouseScreenState createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen>
    with SingleTickerProviderStateMixin {
  String? orderBy;
  @override
  void initState() {
    super.initState();
    checkingInfo();
  }

  checkingInfo() {
    if (widget.pageInfo == "House") {
      setState(() {
        orderBy = "house";
      });
    } else if (widget.pageInfo == "Villa") {
      setState(() {
        orderBy = "villa";
      });
    } else if (widget.pageInfo == "Apartment") {
      setState(() {
        orderBy = "apartment";
      });
    }
  }

  Future saveAndShare(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final image = File('${directory.path}/flutter.png');
    image.writeAsBytesSync(bytes);
    await Share.shareXFiles([XFile(image.path)]);
  }

  bool loading = true;
  final _controller = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final isDialOpen = ValueNotifier(false);
    return WillPopScope(
      onWillPop: () async {
        if (isDialOpen.value) {
          isDialOpen.value = false;
          return false;
        } else {
          return true;
        }
      },
      child: Screenshot(
        controller: _controller,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: customAppbar(context, widget.pageInfo),
          body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("posts")
                .where('houseType', isEqualTo: orderBy)
                .snapshots(),
            builder: (context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CupertinoActivityIndicator(
                    radius: 35,
                    animating: true,
                    color: Colors.green,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No data to display."));
              }

              return ListView.custom(
                childrenDelegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return customHouseCard(
                      snap: snapshot.data!.docs[index].data(),
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                ),
                shrinkWrap: true,
                padding: EdgeInsets.all(5),
                scrollDirection: Axis.vertical,
              );
            },
          ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor: Colors.green[900],
            overlayColor: Colors.black.withOpacity(0.04),
            spacing: 4.h,
            spaceBetweenChildren: 12.h,
            openCloseDial: isDialOpen,
            children: [
              SpeedDialChild(
                child: Icon(Icons.share),
                label: "Share",
                backgroundColor: Colors.green[300],
                onTap: () {},
              ),
              SpeedDialChild(
                child: Icon(Icons.star),
                label: "Rate App",
                backgroundColor: Colors.green[300],
                onTap: () {},
              ),
              SpeedDialChild(
                child: Icon(Icons.screenshot),
                label: "Take Snap",
                backgroundColor: Colors.green[300],
                onTap: () async {
                  final image = await _controller.capture();
                  if (image != null) {
                    saveAndShare(image);
                  }
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.add),
                label: "Add post",
                backgroundColor: Colors.green[300],
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
