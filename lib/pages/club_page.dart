import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unify/pages/join_requests_list.dart';
import 'package:unify/Components/Constants.dart';
import 'package:unify/pages/members_list_page.dart';
import 'package:unify/widgets/PostWidget.dart';
import 'package:unify/Models/club.dart';
import 'package:unify/Models/course.dart';
import 'package:unify/pages/course_calender_page.dart';
import 'package:unify/Models/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unify/Models/user.dart';
import 'package:unify/pages/PostPage.dart';

class ClubPage extends StatefulWidget {
  final Club club;

  ClubPage({Key key, this.club}) : super(key: key);

  @override
  _ClubPageState createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage> {
  int sortBy = 0;
  Future<List<Post>> clubFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        brightness: Brightness.light,
        title: Text(
          widget.club.name,
          style: GoogleFonts.quicksand(
            textStyle: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.7,
        iconTheme: IconThemeData(color: Colors.black),
        actions: <Widget>[
          IconButton(
            icon: Icon(AntDesign.plus),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PostPage(
                            club: widget.club,
                          ))).then((value) {
                setState(() {
                  clubFuture = fetchClubPosts(widget.club, sortBy);
                });
              });
            },
          ),
          IconButton(
            icon: Icon(AntDesign.team),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MembersListPage(
                            members: widget.club.memberList,
                            club: widget.club,
                            isCourse: false,
                          )));
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CourseCalendarPage(
                            course: null,
                            club: widget.club,
                          )));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (sortBy == 0) {
                          sortBy = 1;
                        } else {
                          sortBy = 0;
                        }
                        clubFuture = fetchClubPosts(widget.club, sortBy);
                      });
                    },
                    child: Center(
                      child: Text(
                        "Sorting by: ${sortBy == 0 ? 'Recent' : 'You first'}",
                        style: GoogleFonts.quicksand(
                          textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                ),
                FutureBuilder(
                  future: clubFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount:
                            snapshot.data != null ? snapshot.data.length : 0,
                        itemBuilder: (BuildContext context, int index) {
                          Post post = snapshot.data[index];
                          var timeAgo = new DateTime.fromMillisecondsSinceEpoch(
                              post.timeStamp);
                          Function f = () async {
                            var res =
                                await deletePost(post.id, null, widget.club);
                            Navigator.pop(context);
                            if (res) {
                              setState(() {
                                clubFuture =
                                    fetchClubPosts(widget.club, sortBy);
                              });
                              previewMessage("Post Deleted", context);
                            } else {
                              previewMessage("Error deleting post!", context);
                            }
                          };

                          Function b = () async {
                            var res = await block(post.userId);
                            Navigator.pop(context);
                            if (res) {
                              setState(() {
                                clubFuture =
                                    fetchClubPosts(widget.club, sortBy);
                              });
                              previewMessage("User blocked.", context);
                            }
                          };

                          Function h = () async {
                            var res = await hidePost(post.id);
                            Navigator.pop(context);
                            if (res) {
                              setState(() {
                                clubFuture =
                                    fetchClubPosts(widget.club, sortBy);
                              });
                              previewMessage("Post hidden from feed.", context);
                            }
                          };

                          return PostWidget(
                              post: post,
                              timeAgo: timeago.format(timeAgo),
                              club: widget.club,
                              deletePost: f,
                              block: b,
                              hide: h);
                        },
                      );
                    } else {
                      return Container(
                        height: MediaQuery.of(context).size.height / 1.4,
                        child: Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.face,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 10),
                              Text("There are no posts :(",
                                  style: GoogleFonts.quicksand(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey),
                                  )),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<Null> refresh() async {
    this.setState(() {
      clubFuture = fetchClubPosts(widget.club, sortBy);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    clubFuture = fetchClubPosts(widget.club, sortBy);
  }
}
