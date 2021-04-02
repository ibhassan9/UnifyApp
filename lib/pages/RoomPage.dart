import 'dart:async';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_unicons/unicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:timeago/timeago.dart';
import 'package:unify/Components/Constants.dart';
import 'package:unify/Models/message.dart';
import 'package:unify/Models/notification.dart';
import 'package:unify/Models/product.dart';
import 'package:unify/Models/room.dart';
import 'package:unify/Models/user.dart' as u;
import 'package:unify/pages/ProfilePage.dart';
import 'package:unify/pages/RoomInfoPage.dart';
import 'package:unify/widgets/ChatBubbleLeftGroup.dart';
import 'package:unify/widgets/ChatBubbleRightGroup.dart';
import 'package:unify/widgets/SayHiWidget.dart';
import 'package:intl/intl.dart';

class RoomPage extends StatefulWidget {
  final Room room;
  RoomPage({Key key, @required this.room}) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with WidgetsBindingObserver {
  TextEditingController chatController = TextEditingController();
  var uniKey = Constants.checkUniversity();
  var myID = firebaseAuth.currentUser.uid;
  var db = FirebaseDatabase.instance.reference().child('rooms');
  int eventCount = 0;
  int removedCount = 0;
  ScrollController _scrollController = new ScrollController();
  Stream<Event> myChat;
  bool seen = false;
  bool isSending = false;
  int renders = 0;
  bool listRendered = false;
  Product prod;

  Widget build(BuildContext context) {
    Padding chatBox = Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            border:
                Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // SizedBox(width: 3.0),
                    // Unicon(UniconData.uniImage,
                    //     color: Theme.of(context).accentColor),
                    // SizedBox(width: 5.0),
                    InkWell(
                      onTap: () {
                        if (widget.room.adminId ==
                            FirebaseAuth.instance.currentUser.uid) {
                          Room.delete(id: widget.room.id).then((value) {
                            if (value) {
                              Navigator.pop(context, true);
                            }
                          });
                        } else {
                          Room.leave(roomId: widget.room.id).then((value) {
                            if (value) {
                              setState(() {
                                widget.room.inRoom = false;
                                widget.room.members.removeWhere((element) =>
                                    element.id ==
                                    FirebaseAuth.instance.currentUser.uid);
                                Navigator.pop(context, true);
                              });
                            }
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(20.0)),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                          child: Text(
                            widget.room.adminId ==
                                    FirebaseAuth.instance.currentUser.uid
                                ? "End"
                                : "Leave",
                            style: GoogleFonts.quicksand(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 5.0),
                    Flexible(
                        child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(20.0)),
                      child: TextField(
                        onTap: () {
                          Timer(
                              Duration(milliseconds: 300),
                              () => _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeIn));
                        },
                        textInputAction: TextInputAction.done,
                        maxLines: null,
                        controller: chatController,
                        decoration: new InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                              left: 15, bottom: 5, top: 5, right: 15),
                          hintText: "Insert message here",
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
                    )),
                    isSending
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                                height: 10,
                                width: 10,
                                child: LoadingIndicator(
                                  indicatorType: Indicator.ballClipRotate,
                                  color: Theme.of(context).accentColor,
                                )),
                          )
                        : IconButton(
                            icon: Icon(
                              FlutterIcons.send_mdi,
                              color: Theme.of(context).accentColor,
                            ),
                            onPressed: () async {
                              if (chatController.text.isEmpty || isSending) {
                                return;
                              }
                              setState(() {
                                isSending = true;
                              });
                              var res = await Room.sendMessage(
                                  message: chatController.text,
                                  roomId: widget.room.id);
                              if (res) {
                                sendPush(text: chatController.text);
                                chatController.clear();
                                setState(() {
                                  isSending = false;
                                  prod = null;
                                });
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent +
                                      10,
                                  curve: Curves.easeOut,
                                  duration: const Duration(milliseconds: 300),
                                );
                              }
                            },
                          )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 30.0,
        shadowColor: Theme.of(context).dividerColor.withOpacity(0.5),
        centerTitle: true,
        backgroundColor: Theme.of(context).backgroundColor,
        title: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CachedNetworkImage(
                  imageUrl: widget.room.imageUrl,
                  width: 35.0,
                  height: 35.0,
                  fit: BoxFit.cover),
            ),
            SizedBox(height: 5.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.room.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).accentColor),
                ),
                SizedBox(height: 3.0),
                Text(
                  widget.room.members.length.toString() + ' members',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).buttonColor),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Unicon(UniconData.uniInfoCircle,
                color: Theme.of(context).accentColor),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RoomInfoPage(room: widget.room)));
            },
          )
        ],
      ),
      // appBar: AppBar(
      //   brightness: Theme.of(context).brightness,
      //   backgroundColor: Theme.of(context).backgroundColor,
      //   centerTitle: false,
      //   iconTheme: IconThemeData(color: Theme.of(context).accentColor),
      //   leadingWidth: 0,
      //   leading: Container(),
      //   toolbarHeight: 100,
      //   title: Row(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       ClipRRect(
      //         borderRadius: BorderRadius.circular(15),
      //         child: CachedNetworkImage(
      //           imageUrl: widget.room.imageUrl,
      //           width: 30,
      //           height: 30,
      //           fit: BoxFit.cover,
      //         ),
      //       ),
      //       SizedBox(width: 10.0),
      //       Flexible(
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           children: [
      //             Text(
      //               "The topic of discussion is:",
      //               maxLines: 1,
      //               overflow: TextOverflow.ellipsis,
      //               style: GoogleFonts.quicksand(
      //                   fontSize: 11,
      //                   fontWeight: FontWeight.w500,
      //                   color: Theme.of(context).accentColor),
      //             ),
      //             SizedBox(height: 3.0),
      //             Text(
      //               widget.room.name,
      //               maxLines: 2,
      //               overflow: TextOverflow.ellipsis,
      //               style: GoogleFonts.quicksand(
      //                   fontSize: 13,
      //                   fontWeight: FontWeight.w600,
      //                   color: Theme.of(context).accentColor),
      //             ),
      //             SizedBox(height: 3.0),
      //             Text(
      //               widget.room.members.length.toString() + ' member(s)',
      //               style: GoogleFonts.quicksand(
      //                   fontSize: 13,
      //                   fontWeight: FontWeight.w500,
      //                   color: Theme.of(context).buttonColor),
      //             ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      //   actions: <Widget>[
      //     IconButton(
      //       icon: Unicon(UniconData.uniInfoCircle, color: Colors.blue),
      //       onPressed: () {
      //         Navigator.push(
      //             context,
      //             MaterialPageRoute(
      //                 builder: (context) => RoomInfoPage(room: widget.room)));
      //       },
      //     )
      //   ],
      //   elevation: 0.5,
      // ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Stack(children: [
          ListView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              StreamBuilder(
                stream: myChat,
                builder: (context, snap) {
                  if (snap.hasData &&
                      !snap.hasError &&
                      snap.data.snapshot.value != null) {
                    Map data = snap.data.snapshot.value;
                    List<Message> messages = [];
                    for (var key in data.keys) {
                      Message msg = Message(
                          id: key,
                          messageText: data[key]['messageText'],
                          receiverId: data[key]['receiverId'],
                          senderId: data[key]['senderId'],
                          timestamp: data[key]['timeStamp']);
                      if (data[key]['prodId'] != null) {
                        msg.productId = data[key]['prodId'];
                      }
                      messages.add(msg);
                    }

                    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    if (messages.isNotEmpty) {
                      if (seen == false) {
                        seen = true;
                      }
                    }

                    Function scroll = () {
                      Timer(
                          Duration(milliseconds: 300),
                          () => _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeIn));
                    };

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        renders += 1;
                        if (renders == messages.length - 1) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent);
                          });
                        }

                        Message msg = messages[index];
                        var date =
                            DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
                        var formattedDate = DateFormat.yMMMd().format(date);
                        var date_now = DateTime.now();
                        var formattedNow = DateFormat.yMMMd().format(date_now);
                        if (index == 0) {
                          if (msg.senderId == myID) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Column(
                                children: [
                                  Text(
                                    formattedDate == formattedNow
                                        ? "Today"
                                        : formattedDate,
                                    style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .accentColor
                                            .withOpacity(0.7)),
                                  ),
                                  ChatBubbleRightGroup(
                                      msg: msg,
                                      scroll: scroll,
                                      meLastSender: index == 0
                                          ? true
                                          : messages[index - 1].senderId ==
                                                      firebaseAuth
                                                          .currentUser.uid ||
                                                  (formattedDate !=
                                                          formattedNow &&
                                                      messages[index - 1]
                                                              .senderId ==
                                                          firebaseAuth
                                                              .currentUser.uid)
                                              ? false
                                              : true),
                                ],
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Column(
                                children: [
                                  Text(
                                    formattedDate == formattedNow
                                        ? "Today"
                                        : formattedDate,
                                    style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .accentColor
                                            .withOpacity(0.7)),
                                  ),
                                  ChatBubbleLeftGroup(
                                      msg: msg,
                                      scroll: scroll,
                                      meLastSender: index == 0
                                          ? true
                                          : messages[index - 1].senderId ==
                                                      msg.senderId ||
                                                  (formattedDate !=
                                                          formattedNow &&
                                                      messages[index - 1]
                                                              .senderId ==
                                                          msg.senderId)
                                              ? false
                                              : true),
                                ],
                              ),
                            );
                          }
                        } else {
                          if (index > 0) {
                            Message _old = messages[index - 1];
                            var _date = DateTime.fromMillisecondsSinceEpoch(
                                _old.timestamp);
                            var _formattedDate =
                                DateFormat.yMMMd().format(_date);
                            if (_formattedDate == formattedDate) {
                              if (msg.senderId == myID) {
                                return ChatBubbleRightGroup(
                                    msg: msg,
                                    scroll: scroll,
                                    meLastSender: index == 0
                                        ? true
                                        : messages[index - 1].senderId ==
                                                    firebaseAuth
                                                        .currentUser.uid ||
                                                (formattedDate !=
                                                        formattedNow &&
                                                    messages[index - 1]
                                                            .senderId ==
                                                        firebaseAuth
                                                            .currentUser.uid)
                                            ? false
                                            : true);
                              } else {
                                return ChatBubbleLeftGroup(
                                    msg: msg,
                                    scroll: scroll,
                                    meLastSender: index == 0
                                        ? true
                                        : messages[index - 1].senderId ==
                                                    msg.senderId ||
                                                (formattedDate !=
                                                        formattedNow &&
                                                    messages[index - 1]
                                                            .senderId ==
                                                        msg.senderId)
                                            ? false
                                            : true);
                              }
                            } else {
                              if (msg.senderId == myID) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        formattedDate == formattedNow
                                            ? "Today"
                                            : formattedDate,
                                        style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .accentColor
                                                .withOpacity(0.7)),
                                      ),
                                      ChatBubbleRightGroup(
                                          msg: msg,
                                          scroll: scroll,
                                          meLastSender: index == 0
                                              ? true
                                              : messages[index - 1].senderId ==
                                                          firebaseAuth
                                                              .currentUser
                                                              .uid ||
                                                      (formattedDate !=
                                                              formattedNow &&
                                                          messages[index - 1]
                                                                  .senderId ==
                                                              firebaseAuth
                                                                  .currentUser
                                                                  .uid)
                                                  ? false
                                                  : true),
                                    ],
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        formattedDate == formattedNow
                                            ? "Today"
                                            : formattedDate,
                                        style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .accentColor
                                                .withOpacity(0.7)),
                                      ),
                                      ChatBubbleLeftGroup(
                                          msg: msg,
                                          scroll: scroll,
                                          meLastSender: index == 0
                                              ? true
                                              : messages[index - 1].senderId ==
                                                          msg.senderId ||
                                                      (formattedDate !=
                                                              formattedNow &&
                                                          messages[index - 1]
                                                                  .senderId ==
                                                              msg.senderId)
                                                  ? false
                                                  : true),
                                    ],
                                  ),
                                );
                              }
                            }
                          } else {
                            if (msg.senderId == myID) {
                              return ChatBubbleRightGroup(
                                  msg: msg,
                                  scroll: scroll,
                                  meLastSender: index == 0
                                      ? true
                                      : messages[index - 1].senderId ==
                                                  firebaseAuth
                                                      .currentUser.uid ||
                                              (formattedDate != formattedNow &&
                                                  messages[index - 1]
                                                          .senderId ==
                                                      firebaseAuth
                                                          .currentUser.uid)
                                          ? false
                                          : true);
                            } else {
                              return ChatBubbleLeftGroup(
                                  msg: msg,
                                  scroll: scroll,
                                  meLastSender: index == 0
                                      ? true
                                      : messages[index - 1].senderId ==
                                                  msg.senderId ||
                                              (formattedDate != formattedNow &&
                                                  messages[index - 1]
                                                          .senderId ==
                                                      msg.senderId)
                                          ? false
                                          : true);
                            }
                          }
                        }
                      },
                    );
                  } else
                    return Center(child: SayHiWidget(receiver: null));
                },
              ),
            ],
          )
        ]),
      ),
      bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0), child: chatBox),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    var chats = db
        .child(uniKey == 0
            ? 'UofT'
            : uniKey == 1
                ? 'YorkU'
                : 'WesternU')
        .child(widget.room.id)
        .child('chat');
    if (FirebaseAuth.instance.currentUser.uid != widget.room.adminId) {
      if (widget.room.inRoom) {
      } else {
        Room.join(roomId: widget.room.id).then((value) async {
          if (value) {
            await u.getUser(FirebaseAuth.instance.currentUser.uid).then((user) {
              if (this.mounted) {
                setState(() {
                  widget.room.inRoom = true;
                  widget.room.members.add(user);
                });
              }
            });
          }
        });
      }
    }
    myChat = chats.onValue;
    db
        .child(uniKey == 0
            ? 'UofT'
            : uniKey == 1
                ? 'YorkU'
                : 'WesternU')
        .child(widget.room.id)
        .child('members')
        .onChildRemoved
        .listen((event) {
      eventCount += 1;
      print(event.snapshot.key);
      print('event listening');
      if (eventCount > 1) {
        return;
      }
      AwesomeDialog(
        context: context,
        dialogType: DialogType.NO_HEADER,
        animType: AnimType.BOTTOMSLIDE,
        body: Column(
          children: [
            Text(
              event.snapshot.key == FirebaseAuth.instance.currentUser.uid
                  ? "You have been removed from this room"
                  : "This room has been ended.",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10.0),
            Text(
              event.snapshot.key == FirebaseAuth.instance.currentUser.uid
                  ? 'Please refrain from joining in the next 20 minutes to prevent account suspension.'
                  : "You can start your own room by clicking on the 'Start a room' button",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        btnOkColor: Colors.teal,
        btnOkOnPress: () {
          //Navigator.pop(context);
          Navigator.pop(context, true);
          eventCount = 0;
        },
      )..show();
    });
  }

  void sendPush({String text}) {
    List<String> tokens = [];
    for (var user in widget.room.members) {
      tokens.add(user.device_token);
    }
    sendPushRoomChat(tokens, text, widget.room);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    chatController.dispose();
    _scrollController.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // print(state);

    // if (state == AppLifecycleState.inactive) {
    //   if (widget.room.adminId == FirebaseAuth.instance.currentUser.uid) {
    //   } else {
    //     Room.leave(roomId: widget.room.id).then((value) {
    //       if (value) {
    //         setState(() {
    //           widget.room.inRoom = false;
    //           widget.room.members.removeWhere((element) =>
    //               element.id == FirebaseAuth.instance.currentUser.uid);
    //         });
    //         //Navigator.pop(context, true);
    //       }
    //     });
    //   }
    // } else if (state == AppLifecycleState.resumed) {
    //   Navigator.pop(context, true);
    // }

    // final isBackground = state == AppLifecycleState.paused;

    // if (isBackground) {}

    /* if (isBackground) {
      // service.stop();
    } else {
      // service.start();
    }*/
  }
}
