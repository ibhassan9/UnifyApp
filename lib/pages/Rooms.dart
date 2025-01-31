import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:unify/Models/room.dart';
import 'package:unify/pages/CreateRoom.dart';
import 'package:unify/widgets/RoomWidget.dart';

class Rooms extends StatefulWidget {
  @override
  _RoomsState createState() => _RoomsState();
}

class _RoomsState extends State<Rooms> with AutomaticKeepAliveClientMixin {
  bool loaded = false;
  List<Room> rooms;
  String filter;
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).backgroundColor,
      //   elevation: 0.0,
      //   title: Text(
      //     'Rooms',
      //     style: GoogleFonts. inter(
      //fontFamily: Constants.fontFamily,
      //         fontSize: 25.0,
      //         color: Theme.of(context).accentColor,
      //         fontWeight: FontWeight.w600),
      //   ),
      //   centerTitle: false,
      // ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            loaded = false;
          });
          Room.fetchAll().then((value) {
            setState(() {
              rooms = value;
              loaded = true;
            });
          });
        },
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 5.0),
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(40)),
                child: Row(
                  children: [
                    SizedBox(width: 10.0),
                    Icon(FlutterIcons.search_fea,
                        size: 20.0, color: Theme.of(context).accentColor),
                    Flexible(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            filter = value;
                          });
                        },
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                              left: 10, bottom: 11, top: 11, right: 15),
                          hintText: "Search Rooms...",
                          hintStyle: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).accentColor),
                        ),
                        style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loaded
                ? ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      Room room = rooms[index];
                      Function reload = () {
                        setState(() {
                          loaded = false;
                        });
                        Room.fetchAll().then((value) {
                          setState(() {
                            rooms = value;
                            loaded = true;
                          });
                        });
                      };
                      return filter == null || filter.trim() == ""
                          ? RoomWidget(
                              room: room,
                              reload: reload,
                            )
                          : room.name
                                  .toLowerCase()
                                  .trim()
                                  .contains(filter.toLowerCase().trim())
                              ? RoomWidget(
                                  room: room,
                                  reload: reload,
                                )
                              : Container();
                    })
                : Center(
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: LoadingIndicator(
                            indicatorType: Indicator.ballClipRotateMultiple,
                            color: Colors.deepPurpleAccent)),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn3',
        elevation: 1.5,
        backgroundColor: Colors.teal,
        label: Text("Start a room",
            style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        onPressed: () async {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CreateRoom())).then((v) {
            if (v == true) {
              setState(() {
                loaded = false;
              });
              Room.fetchAll().then((value) {
                setState(() {
                  rooms = value;
                  loaded = true;
                });
                value.where((element) => element.id == v);
              });
            }
          });
        },
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Room.fetchAll().then((value) {
      setState(() {
        rooms = value;
        loaded = true;
      });
    });
  }

  bool get wantKeepAlive => true;
}
