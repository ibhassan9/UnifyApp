import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:unify/Models/club.dart';
import 'package:unify/Models/course.dart';
import 'package:unify/Models/user.dart';
import 'package:unify/pages/MyProfilePage.dart';
import 'package:unify/pages/ProfilePage.dart';

class MemberWidget extends StatefulWidget {
  final PostUser user;
  final Club club;
  final bool isCourse;
  final Function delete;

  MemberWidget({Key key, this.user, this.club, this.isCourse, this.delete});

  @override
  _MemberWidgetState createState() => _MemberWidgetState();
}

class _MemberWidgetState extends State<MemberWidget> {
  final FirebaseAuth _fAuth = FirebaseAuth.instance;
  TextEditingController bioC = TextEditingController();
  TextEditingController sC = TextEditingController();
  TextEditingController igC = TextEditingController();
  TextEditingController lC = TextEditingController();

  String imgUrl = '';
  PostUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
      child: InkWell(
        onTap: () {
          if (user == null) {
            return;
          }
          if (user.id == _fAuth.currentUser.uid) {
            showBarModalBottomSheet(
                context: context,
                builder: (context) => ProfilePage(
                      user: user,
                      heroTag: user.id,
                      isMyProfile: true,
                    ));
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => ));
          } else {
            showBarModalBottomSheet(
                context: context,
                builder: (context) =>
                    ProfilePage(user: user, heroTag: user.id));
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) =>
            //             ));
          }
          //showProfile(widget.user, context, bioC, sC, igC, lC, null, null);
        },
        child: user != null
            ? Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).backgroundColor),
                child: Wrap(children: <Widget>[
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          child: Row(
                            children: <Widget>[
                              imgUrl == null || imgUrl == ''
                                  ? CircleAvatar(
                                      backgroundColor: Colors.grey[400],
                                      child: Text(
                                          widget.user.name.substring(0, 1),
                                          style: GoogleFonts.quicksand(
                                              color: Theme.of(context)
                                                  .backgroundColor)))
                                  : Hero(
                                      tag: user.id,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: Image.network(
                                          imgUrl,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: Center(
                                                child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: LoadingIndicator(
                                                      indicatorType: Indicator
                                                          .ballScaleMultiple,
                                                      color: Theme.of(context)
                                                          .accentColor,
                                                    )),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                              SizedBox(width: 10.0),
                              Text(
                                _fAuth.currentUser.uid == widget.user.id
                                    ? 'You'
                                    : widget.user.name,
                                style: GoogleFonts.quicksand(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentColor),
                              )
                            ],
                          ),
                        ),
                        widget.isCourse == false
                            ? user.id == widget.club.adminId
                                ? Container(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          10.0, 7.0, 10.0, 7.0),
                                      child: Text(
                                        'Admin',
                                        style: GoogleFonts.quicksand(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white),
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent,
                                        borderRadius:
                                            BorderRadius.circular(3.0)))
                                : Visibility(
                                    visible: _fAuth.currentUser.uid ==
                                            widget.club.adminId &&
                                        _fAuth.currentUser.uid != user.id,
                                    child: InkWell(
                                        onTap: () {
                                          widget.delete();
                                        },
                                        child: Icon(AntDesign.close,
                                            color:
                                                Theme.of(context).accentColor,
                                            size: 20.0)))
                            : SizedBox(),
                      ]),
                  Divider(),
                ]))
            : Container(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getUser(widget.user.id).then((value) {
      setState(() {
        imgUrl = value.profileImgUrl;
        user = value;
      });
    });
  }
}
