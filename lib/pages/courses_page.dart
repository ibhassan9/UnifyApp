import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:toast/toast.dart';
import 'package:unify/Widgets/CourseWidget.dart';
import 'package:unify/Models/course.dart';
import 'package:unify/pages/GPACalcPage.dart';

class CoursesPage extends StatefulWidget {
  @override
  _CoursesPageState createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
    with AutomaticKeepAliveClientMixin {
  bool didload = false;
  String filter;
  TextEditingController titleController = TextEditingController();
  Future<List<Course>> _courseFuture;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    addCourseDialog() {
      bool switchVal = false;
      AwesomeDialog(
          context: context,
          animType: AnimType.SCALE,
          dialogType: DialogType.NO_HEADER,
          body: StatefulBuilder(builder: (context, setState) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Don't see your course? Request it!",
                    style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).accentColor),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: titleController,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  decoration: new InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.only(
                          left: 15, bottom: 11, top: 11, right: 15),
                      hintText: "Eg. CSC437H1"),
                  style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).accentColor),
                ),
              ],
            );
          }),
          btnOkColor: Colors.deepPurpleAccent,
          btnOkOnPress: () async {
            // send request on firebase
            if (titleController.text.isEmpty || titleController.text == null) {
              return;
            }
            await requestCourse(titleController.text);
            titleController.clear();
            Toast.show("Your request has been received!", context);
          })
        ..show();
    }

    return Scaffold(
      // appBar: AppBar(
      //   brightness: Theme.of(context).brightness,
      //   backgroundColor: Theme.of(context).backgroundColor,
      //   centerTitle: false,
      //   elevation: 0.0,
      //   iconTheme: IconThemeData(color: Theme.of(context).accentColor),
      //   actions: [
      //     IconButton(
      //         icon: Icon(FlutterIcons.add_circle_mdi),
      //         onPressed: () {
      //           addCourseDialog();
      //         }),
      //     // InkWell(
      //     //   onTap: () {
      //     //     addCourseDialog();
      //     //   },
      //     //   child: Text(
      //     //     "Request a course",
      //     //     style: GoogleFonts.lexendDeca(
      //     //       GoogleFonts.overpass: GoogleFonts. inter(
      //fontFamily: Constants.fontFamily,
      //     //           fontSize: 15,
      //     //           fontWeight: FontWeight.w500,
      //     //           color: Colors.black),
      //     //     ),
      //     //   ),
      //     // ),
      //     // SizedBox(width: 10.0)
      //   ],
      //   title: Text(
      //     "Courses",
      //     style: GoogleFonts.pacifico(
      //       GoogleFonts.overpass: GoogleFonts. inter(
      //fontFamily: Constants.fontFamily,
      //           fontSize: 25,
      //           fontWeight: FontWeight.w500,
      //           color: Theme.of(context).accentColor),
      //     ),
      //   ),
      // ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Stack(
          children: <Widget>[
            ListView(
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      showBarModalBottomSheet(
                          context: context,
                          builder: (context) => GPACalculator());
                    },
                    child: Container(
                      height: 50.0,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(5.0)),
                      child: Center(
                          child: Text(
                        "GPA Calculator",
                        style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      )),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, bottom: 5.0),
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
                              hintText: "Search Courses...",
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
                didload == true
                    ? FutureBuilder(
                        future: _courseFuture,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting)
                            return Center(
                                child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: LoadingIndicator(
                                      indicatorType:
                                          Indicator.ballClipRotateMultiple,
                                      color: Colors.deepPurpleAccent,
                                    )));
                          else if (snap.hasData)
                            return ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount:
                                  snap.data != null ? snap.data.length : 0,
                              itemBuilder: (BuildContext context, int index) {
                                Course course = snap.data[index];
                                return filter == null || filter.trim() == ""
                                    ? Column(
                                        children: <Widget>[
                                          CourseWidget(course: course),
                                          Divider(),
                                        ],
                                      )
                                    : course.name.toLowerCase().trim().contains(
                                                filter.toLowerCase().trim()) ||
                                            course.code
                                                .toLowerCase()
                                                .trim()
                                                .contains(
                                                    filter.toLowerCase().trim())
                                        ? Column(
                                            children: <Widget>[
                                              CourseWidget(course: course),
                                              Divider(),
                                            ],
                                          )
                                        : new Container();
                              },
                            );
                          else if (snap.hasError)
                            return Container(
                              height: MediaQuery.of(context).size.height / 1.4,
                              child: Center(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.face,
                                      color: Theme.of(context).accentColor,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Cannot find any courses :(",
                                      style: GoogleFonts.quicksand(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          else
                            return Container(
                              height: MediaQuery.of(context).size.height / 1.4,
                              child: Center(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.face,
                                      color: Theme.of(context).accentColor,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "There are no courses :(",
                                      style: GoogleFonts.quicksand(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        })
                    : Container(),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 40,
        height: 40,
        child: FloatingActionButton(
          heroTag: 'btn2',
          backgroundColor: Colors.deepPurpleAccent,
          child: Icon(Entypo.plus, color: Colors.white),
          onPressed: () async {
            addCourseDialog();
          },
        ),
      ),
    );
  }

  Future<Null> refresh() async {
    setState(() {
      _courseFuture = fetchCourses();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _courseFuture = fetchCourses();
        setState(() {
          didload = true;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
