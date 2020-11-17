import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import 'package:unify/Components/Constants.dart';
import 'package:unify/Models/club.dart';
import 'package:unify/Models/course.dart';
import 'package:unify/Models/user.dart';
import 'package:http/http.dart' as http;

class Post {
  String id;
  String userId;
  String username;
  String content;
  int timeStamp;
  bool isAnonymous;
  String courseId;
  int likeCount;
  int commentCount;
  Map<dynamic, dynamic> comments;
  String imgUrl;
  String questionOne;
  String questionTwo;
  int questionOneLikeCount;
  int questionTwoLikeCount;
  bool isLiked;
  Map<dynamic, dynamic> votes;
  bool isVoted;
  int whichOption;
  String tcQuestion;

  Post(
      {this.id,
      this.userId,
      this.username,
      this.content,
      this.timeStamp,
      this.isAnonymous,
      this.courseId,
      this.likeCount,
      this.commentCount,
      this.comments,
      this.imgUrl,
      this.questionOne,
      this.questionTwo,
      this.questionOneLikeCount,
      this.questionTwoLikeCount,
      this.isLiked,
      this.votes,
      this.isVoted,
      this.whichOption,
      this.tcQuestion});
}

FirebaseAuth firebaseAuth = FirebaseAuth.instance;

var postsDB = FirebaseDatabase.instance.reference().child('posts');

var postDBrefUofT =
    FirebaseDatabase.instance.reference().child('posts').child('UofT');
var postDBrefYork =
    FirebaseDatabase.instance.reference().child('posts').child('YorkU');
var coursepostDBrefUofT =
    FirebaseDatabase.instance.reference().child('courseposts').child('UofT');
var coursepostDBrefYork =
    FirebaseDatabase.instance.reference().child('courseposts').child('YorkU');
var courseDBUofT =
    FirebaseDatabase.instance.reference().child('courses').child('UofT');
var courseDBYorkU =
    FirebaseDatabase.instance.reference().child('courses').child('YorkU');

var clubpostDBrefUofT =
    FirebaseDatabase.instance.reference().child('clubposts').child('UofT');
var clubpostDBrefYork =
    FirebaseDatabase.instance.reference().child('clubposts').child('YorkU');
var clubDBUofT =
    FirebaseDatabase.instance.reference().child('clubs').child('UofT');
var clubDBYorkU =
    FirebaseDatabase.instance.reference().child('clubs').child('YorkU');

// 0 - University of Toronto | 1 - York University

Future<bool> createPost(Post post) async {
  PostUser user = await getUser(firebaseAuth.currentUser.uid);
  var uniKey = Constants.checkUniversity();

  var db = postsDB.child(uniKey == 0 ? 'UofT' : 'YorkU');
  var key = db.push();
  final Map<String, dynamic> data = {
    "userId": firebaseAuth.currentUser.uid,
    "name": user.name,
    "content": post.content,
    "timeStamp": DateTime.now().millisecondsSinceEpoch,
    "isAnonymous": post.isAnonymous,
    "courseId": post.courseId,
    "likeCount": 0,
    "commentCount": 0,
    "imgUrl": post.imgUrl
  };

  if (post.questionOne != null && post.questionTwo != null) {
    data['questionOne'] = post.questionOne;
    data['questionTwo'] = post.questionTwo;
    data['questionOneLikeCount'] = 0;
    data['questionTwoLikeCount'] = 0;
  }

  if (post.tcQuestion != null) {
    data['tcQuestion'] = post.tcQuestion;
  }

  await key.set(data);
  DataSnapshot ds = await key.once();
  if (ds.value != null) {
    return true;
  } else {
    return false;
  }
}

Future<String> fetchQuestion() async {
  var db = FirebaseDatabase.instance.reference().child("question");
  var snapshot = await db.once().catchError((onError) {
    print(onError.toString());
  });
  print(snapshot.value);
  return snapshot.value;
}

Future<List<Post>> fetchPosts(int sortBy) async {
  var uniKey = Constants.checkUniversity();
  List<Post> p = List<Post>();
  var db = uniKey == 0
      ? FirebaseDatabase.instance.reference().child("posts").child('UofT')
      : FirebaseDatabase.instance.reference().child("posts").child('YorkU');

  var snapshot = await db.once();
  var blockList = await getBlocks();
  var hiddenList = await getHiddenList();

  Map<dynamic, dynamic> values = snapshot.value;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var filters = prefs.getStringList('filters');

  values.forEach((key, value) {
    var post = Post(
        id: key,
        userId: value['userId'],
        username: value['name'],
        content: value['content'],
        timeStamp: value['timeStamp'],
        isAnonymous:
            value['isAnonymous'] != null ? value['isAnonymous'] : false,
        courseId: value['courseId'],
        likeCount: value['likes'] != null ? value['likes'].length : 0,
        imgUrl: value['imgUrl']);

    if (value['comments'] != null) {
      post.commentCount = value['comments'].length;
    } else {
      post.commentCount = 0;
    }

    if (value['questionOne'] != null && value['questionTwo'] != null) {
      if (value['votes'] != null) {
        List<int> voteCounts = getVotes(value['votes']);
        post.questionOneLikeCount = voteCounts[0];
        post.questionTwoLikeCount = voteCounts[1];
      } else {
        post.questionOneLikeCount = 0;
        post.questionTwoLikeCount = 0;
      }
      post.questionOne = value['questionOne'];
      post.questionTwo = value['questionTwo'];
    }

    if (value['votes'] != null) {
      var voted = checkIsVoted(value['votes']);
      post.votes = value['votes'];
      post.isVoted = voted;
      print(post.isVoted);
      if (voted) {
        int option = whichOption(value['votes']);
        if (option != 0) {
          post.whichOption = option;
        }
      }
    } else {
      post.isVoted = false;
    }

    if (value['likes'] != null) {
      var liked = checkIsLiked(value['likes']);
      post.isLiked = liked;
    } else {
      post.isLiked = false;
    }

    if (value['tcQuestion'] != null) {
      post.tcQuestion = value['tcQuestion'];
    }

    var i = 0;

    if (post.userId != firebaseAuth.currentUser.uid) {
      if (filters != null) {
        for (var filter in filters) {
          if (post.content.toLowerCase().contains(filter.toLowerCase())) {
            i += 1;
          }
        }
      }
    }

    if (i == 0 &&
        blockList.contains(post.userId) == false &&
        hiddenList.contains(post.id) == false) {
      p.add(post);
    }
  });

  if (sortBy == 0) {
    p.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  } else {
    p.sort((a, b) => (b.userId == firebaseAuth.currentUser.uid)
        .toString()
        .compareTo((a.userId == firebaseAuth.currentUser.uid).toString()));
  }
  return p;
}

List<int> getVotes(Map<dynamic, dynamic> votes) {
  int questionOneLikeCount = 0;
  int questionTwoLikeCount = 0;
  for (var value in votes.values) {
    if (value == 1) {
      questionOneLikeCount += 1;
    } else {
      questionTwoLikeCount += 1;
    }
  }
  return [questionOneLikeCount, questionTwoLikeCount];
}

int whichOption(Map<dynamic, dynamic> votes) {
  int val = 0;
  for (var value in votes.keys) {
    if (value == firebaseAuth.currentUser.uid) {
      val = votes[value];
    }
  }
  return val;
}

bool checkIsLiked(Map<dynamic, dynamic> likes) {
  for (var value in likes.values) {
    if (value == firebaseAuth.currentUser.uid) {
      return true;
    }
  }
  return false;
}

bool checkIsVoted(Map<dynamic, dynamic> votes) {
  for (var value in votes.keys) {
    if (value == firebaseAuth.currentUser.uid) {
      return true;
    }
  }
  return false;
}

Future<bool> createCoursePost(Post post, Course course) async {
  PostUser user = await getUser(firebaseAuth.currentUser.uid);
  var uniKey = Constants.checkUniversity();
  var coursePostDB = uniKey == 0 ? coursepostDBrefUofT : coursepostDBrefYork;
  var courseDB = uniKey == 0 ? courseDBUofT : courseDBYorkU;
  var key = coursePostDB.child(course.id).push();

  final Map<String, dynamic> data = {
    "userId": firebaseAuth.currentUser.uid,
    "name": user.name,
    "content": post.content,
    "timeStamp": DateTime.now().millisecondsSinceEpoch,
    "isAnonymous": post.isAnonymous,
    "courseId": post.courseId,
    "commentCount": 0,
    "imgUrl": post.imgUrl
  };

  if (post.questionOne != null && post.questionTwo != null) {
    data['questionOne'] = post.questionOne;
    data['questionTwo'] = post.questionTwo;
    data['questionOneLikeCount'] = 0;
    data['questionTwoLikeCount'] = 0;
  }

  if (post.tcQuestion != null) {
    data['tcQuestion'] = post.tcQuestion;
  }

  await key.set(data);

  DataSnapshot snap;

  snap = await courseDB.child(course.id).child("postCount").once();

  var countValue = snap.value + 1;

  final Map<String, dynamic> postCount = {
    "postCount": countValue,
  };

  await courseDB.child(course.id).update(postCount);

  DataSnapshot ds = await key.once();
  if (ds.value != null) {
    return true;
  } else {
    return false;
  }
}

Future<bool> createClubPost(Post post, Club club) async {
  PostUser user = await getUser(firebaseAuth.currentUser.uid);
  var uniKey = Constants.checkUniversity();
  var clubPostDB = uniKey == 0 ? clubpostDBrefUofT : clubpostDBrefYork;
  var clubDB = uniKey == 0 ? clubDBUofT : clubDBYorkU;
  var key = clubPostDB.child(club.id).push();

  final Map<String, dynamic> data = {
    "userId": firebaseAuth.currentUser.uid,
    "name": user.name,
    "content": post.content,
    "timeStamp": DateTime.now().millisecondsSinceEpoch,
    "isAnonymous": post.isAnonymous,
    "courseId": post.courseId,
    "commentCount": 0,
    "imgUrl": post.imgUrl
  };

  if (post.questionOne != null && post.questionTwo != null) {
    data['questionOne'] = post.questionOne;
    data['questionTwo'] = post.questionTwo;
    data['questionOneLikeCount'] = 0;
    data['questionTwoLikeCount'] = 0;
  }

  if (post.tcQuestion != null) {
    data['tcQuestion'] = post.tcQuestion;
  }

  await key.set(data);

  DataSnapshot snap;

  snap = await clubDB.child(club.id).child("postCount").once();

  var countValue = snap.value + 1;

  final Map<String, dynamic> postCount = {
    "postCount": countValue,
  };

  await clubDB.child(club.id).update(postCount);

  DataSnapshot ds = await key.once();
  if (ds.value != null) {
    return true;
  } else {
    return false;
  }
}

Future<List> getImage() async {
  final picker = ImagePicker();

  final f =
      await picker.getImage(source: ImageSource.gallery, imageQuality: 50);
  var image = Image.file(File(f.path));
  List lst = [image, File(f.path)];
  return lst;
}

void previewMessage(String msg, BuildContext context) {
  Toast.show(msg, context, duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
}

Future<bool> imageApproved(File file) async {
  try {
    var headers = {'api-key': 'e23ce550-b3cd-4e91-85c4-9cbc49c4dce4'};
    var url = "https://api.deepai.org/api/nsfw-detector";
    var uri = Uri.parse(url);
    var request = new http.MultipartRequest("POST", uri);
    request.headers.addAll(headers);

    var multipartFile =
        await http.MultipartFile.fromPath("image", file.path.toString());
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    var res = json.decode(response.body);
    var nsfw_score = res['output']['nsfw_score'];
    var confidence = res['output']['detections'][0]['confidence'];

    if (nsfw_score < 0.75 && confidence > 0.80) {
      return true;
    } else {
      return false;
    }
  } catch (err) {
    return true;
  }
}

Future<String> uploadImageToStorage(File file) async {
  try {
    final DateTime now = DateTime.now();
    final int millSeconds = now.millisecondsSinceEpoch;
    final String month = now.month.toString();
    final String date = now.day.toString();
    final String storageId = (millSeconds.toString());
    final String today = ('$month-$date');

    StorageReference ref = FirebaseStorage.instance
        .ref()
        .child("files")
        .child(today)
        .child(storageId);
    StorageUploadTask uploadTask = ref.putFile(file);

    var snapShot = await uploadTask.onComplete;

    var url = await snapShot.ref.getDownloadURL();
    var urlString = url.toString();

    return urlString;
  } catch (error) {
    return "error";
  }
}

Future<List> getImageString() async {
  try {
    final DateTime now = DateTime.now();
    final int millSeconds = now.millisecondsSinceEpoch;
    final String month = now.month.toString();
    final String date = now.day.toString();
    final String storageId = (millSeconds.toString());
    final String today = ('$month-$date');

    final picker = ImagePicker();

    final f = await picker.getImage(source: ImageSource.gallery);
    var image = Image.file(File(f.path));

    StorageReference ref = FirebaseStorage.instance
        .ref()
        .child("files")
        .child(today)
        .child(storageId);
    var file = File(f.path);
    StorageUploadTask uploadTask = ref.putFile(file);

    var snapShot = await uploadTask.onComplete;

    var url = await snapShot.ref.getDownloadURL();

    List lst = [url, image];

    return lst;
  } catch (error) {
    return [];
  }
}

Future<bool> deletePost(String postId, Course course, Club club) async {
  var uniKey = Constants.checkUniversity();
  var postdb = FirebaseDatabase.instance
      .reference()
      .child('posts')
      .child(uniKey == 0 ? 'UofT' : 'YorkU')
      .child(postId);
  var coursedb = course != null
      ? FirebaseDatabase.instance
          .reference()
          .child('courseposts')
          .child(uniKey == 0 ? 'UofT' : 'YorkU')
          .child(course.id)
          .child(postId)
      : null;
  var clubdb = club != null
      ? FirebaseDatabase.instance
          .reference()
          .child('clubposts')
          .child(uniKey == 0 ? 'UofT' : 'YorkU')
          .child(club.id)
          .child(postId)
      : null;
  // var db = FirebaseDatabase.instance
  //     .reference()
  //     .child(course == null && club == null
  //         ? 'posts'
  //         : course == null
  //             ? 'clubposts'
  //             : 'courseposts')
  //     .child(uniKey == 0 ? 'UofT' : 'YorkU')
  //     .child(postId);
  // await db.remove().catchError((err) {
  //   return false;
  // });
  course == null && club == null
      ? await postdb.remove().catchError((onError) {
          return false;
        })
      : course == null
          ? await clubdb.remove().catchError((onError) {
              return false;
            })
          : await coursedb.remove().catchError((onError) {
              return false;
            });
  return true;
}

Future<List<Post>> fetchCoursePosts(Course course, int sortBy) async {
  var uniKey = Constants.checkUniversity();
  List<Post> p = List<Post>();
  var db = uniKey == 0
      ? FirebaseDatabase.instance
          .reference()
          .child("courseposts")
          .child('UofT')
          .child(course.id)
      : FirebaseDatabase.instance
          .reference()
          .child("courseposts")
          .child('YorkU')
          .child(course.id);

  var snapshot = await db.once();
  var blockList = await getBlocks();
  var hiddenList = await getHiddenList();

  Map<dynamic, dynamic> values = snapshot.value;

  SharedPreferences prefs = await SharedPreferences.getInstance();
  var filters = prefs.getStringList('filters');

  values.forEach((key, value) {
    var post = Post(
        id: key,
        userId: value['userId'],
        username: value['name'],
        content: value['content'],
        timeStamp: value['timeStamp'],
        isAnonymous:
            value['isAnonymous'] != null ? value['isAnonymous'] : false,
        courseId: value['courseId'],
        likeCount: value['likes'] != null ? value['likes'].length : 0,
        imgUrl: value['imgUrl']);

    if (value['comments'] != null) {
      post.commentCount = value['comments'].length;
    } else {
      post.commentCount = 0;
    }

    if (value['questionOne'] != null && value['questionTwo'] != null) {
      if (value['votes'] != null) {
        List<int> voteCounts = getVotes(value['votes']);
        post.questionOneLikeCount = voteCounts[0];
        post.questionTwoLikeCount = voteCounts[1];
      } else {
        post.questionOneLikeCount = 0;
        post.questionTwoLikeCount = 0;
      }
      post.questionOne = value['questionOne'];
      post.questionTwo = value['questionTwo'];
    }

    if (value['votes'] != null) {
      var voted = checkIsVoted(value['votes']);
      post.votes = value['votes'];
      post.isVoted = voted;
      if (voted) {
        int option = whichOption(value['votes']);
        if (option != 0) {
          post.whichOption = option;
        }
      }
    } else {
      post.isVoted = false;
    }

    if (value['likes'] != null) {
      var liked = checkIsLiked(value['likes']);
      post.isLiked = liked;
    } else {
      post.isLiked = false;
    }

    if (value['tcQuestion'] != null) {
      post.tcQuestion = value['tcQuestion'];
    }

    var i = 0;

    if (filters != null) {
      if (post.userId != firebaseAuth.currentUser.uid) {
        for (var filter in filters) {
          if (post.content.toLowerCase().contains(filter.toLowerCase())) {
            i += 1;
          }
        }
      }
    }

    if (i == 0 &&
        blockList.contains(post.userId) == false &&
        hiddenList.contains(post.id) == false) {
      p.add(post);
    }
  });
  if (sortBy == 0) {
    p.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  } else {
    p.sort((a, b) => (b.userId == firebaseAuth.currentUser.uid)
        .toString()
        .compareTo((a.userId == firebaseAuth.currentUser.uid).toString()));
  }
  return p;
}

Future<List<String>> getHiddenList() async {
  var uniKey = Constants.checkUniversity();
  var uid = firebaseAuth.currentUser.uid;
  var db = FirebaseDatabase.instance
      .reference()
      .child('users')
      .child(uniKey == 0 ? 'UofT' : 'YorkU')
      .child(uid)
      .child('hiddenposts');
  var snapshot = await db.once();

  List<String> hiddenList = [];

  if (snapshot.value != null) {
    Map<dynamic, dynamic> values = snapshot.value;

    for (var key in values.keys) {
      hiddenList.add(key);
    }
  }

  return hiddenList;
}

Future<bool> hidePost(String postId) async {
  var uniKey = Constants.checkUniversity();
  var uid = firebaseAuth.currentUser.uid;
  var db = FirebaseDatabase.instance
      .reference()
      .child('users')
      .child(uniKey == 0 ? 'UofT' : 'YorkU')
      .child(uid)
      .child('hiddenposts')
      .child(postId);
  await db.set(postId).catchError((onError) {
    return false;
  });
  return true;
}

Future<bool> unhidePost(String postId) async {
  var uniKey = Constants.checkUniversity();
  var uid = firebaseAuth.currentUser.uid;
  var db = FirebaseDatabase.instance
      .reference()
      .child('users')
      .child(uniKey == 0 ? 'UofT' : 'YorkU')
      .child(uid)
      .child('hiddenposts')
      .child(postId);
  await db.remove().catchError((err) {
    return false;
  });
  return true;
}

Future<bool> like(Post post, Club club, Course course) async {
  var uniKey = Constants.checkUniversity();

  club == null && course == null
      ? await FirebaseDatabase.instance
          .reference()
          .child('posts')
          .child(uniKey == 0 ? 'UofT' : 'YorkU')
          .child(post.id)
          .child('likes')
          .child(firebaseAuth.currentUser.uid)
          .set(firebaseAuth.currentUser.uid)
          .catchError((err) {
          return false;
        })
      : club != null
          ? await FirebaseDatabase.instance
              .reference()
              .child('clubposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(club.id)
              .child(post.id)
              .child('likes')
              .child(firebaseAuth.currentUser.uid)
              .set(firebaseAuth.currentUser.uid)
              .catchError((err) {
              return false;
            })
          : await FirebaseDatabase.instance
              .reference()
              .child('courseposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(course.id)
              .child(post.id)
              .child('likes')
              .child(firebaseAuth.currentUser.uid)
              .set(firebaseAuth.currentUser.uid)
              .catchError((err) {
              return false;
            });
  return true;
}

Future<bool> vote(Post post, Club club, Course course, int option) async {
  var uniKey = Constants.checkUniversity();

  club == null && course == null
      ? await FirebaseDatabase.instance
          .reference()
          .child('posts')
          .child(uniKey == 0 ? 'UofT' : 'YorkU')
          .child(post.id)
          .child('votes')
          .child(firebaseAuth.currentUser.uid)
          .set(option)
          .catchError((err) {
          return false;
        })
      : club != null
          ? await FirebaseDatabase.instance
              .reference()
              .child('clubposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(club.id)
              .child(post.id)
              .child('votes')
              .child(firebaseAuth.currentUser.uid)
              .set(option)
              .catchError((err) {
              return false;
            })
          : await FirebaseDatabase.instance
              .reference()
              .child('courseposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(course.id)
              .child(post.id)
              .child('votes')
              .child(firebaseAuth.currentUser.uid)
              .set(option)
              .catchError((err) {
              return false;
            });
  return true;
}

Future<bool> unlike(Post post, Club club, Course course) async {
  var uniKey = Constants.checkUniversity();

  club == null && course == null
      ? await FirebaseDatabase.instance
          .reference()
          .child('posts')
          .child(uniKey == 0 ? 'UofT' : 'YorkU')
          .child(post.id)
          .child('likes')
          .child(firebaseAuth.currentUser.uid)
          .remove()
          .catchError((err) {
          return false;
        })
      : club != null
          ? await FirebaseDatabase.instance
              .reference()
              .child('clubposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(club.id)
              .child(post.id)
              .child('likes')
              .child(firebaseAuth.currentUser.uid)
              .remove()
              .catchError((err) {
              return false;
            })
          : await FirebaseDatabase.instance
              .reference()
              .child('courseposts')
              .child(uniKey == 0 ? 'UofT' : 'YorkU')
              .child(course.id)
              .child(post.id)
              .child('likes')
              .child(firebaseAuth.currentUser.uid)
              .remove()
              .catchError((err) {
              return false;
            });
  return true;
}

Future<List<Post>> fetchClubPosts(Club club, int sortBy) async {
  var uniKey = Constants.checkUniversity();
  List<Post> p = List<Post>();
  var db = uniKey == 0
      ? FirebaseDatabase.instance
          .reference()
          .child("clubposts")
          .child('UofT')
          .child(club.id)
      : FirebaseDatabase.instance
          .reference()
          .child("clubposts")
          .child('YorkU')
          .child(club.id);

  var snapshot = await db.once();
  var blockList = await getBlocks();
  var hiddenList = await getHiddenList();

  Map<dynamic, dynamic> values = snapshot.value;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var filters = prefs.getStringList('filters');

  print('test');

  values.forEach((key, value) {
    var post = Post(
        id: key,
        userId: value['userId'],
        username: value['name'],
        content: value['content'],
        timeStamp: value['timeStamp'],
        isAnonymous:
            value['isAnonymous'] != null ? value['isAnonymous'] : false,
        courseId: value['courseId'],
        likeCount: value['likes'] != null ? value['likes'].length : 0,
        imgUrl: value['imgUrl']);

    if (value['comments'] != null) {
      post.commentCount = value['comments'].length;
    } else {
      post.commentCount = 0;
    }

    if (value['questionOne'] != null && value['questionTwo'] != null) {
      if (value['votes'] != null) {
        List<int> voteCounts = getVotes(value['votes']);
        post.questionOneLikeCount = voteCounts[0];
        post.questionTwoLikeCount = voteCounts[1];
      } else {
        post.questionOneLikeCount = 0;
        post.questionTwoLikeCount = 0;
      }
      post.questionOne = value['questionOne'];
      post.questionTwo = value['questionTwo'];
    }

    if (value['votes'] != null) {
      var voted = checkIsVoted(value['votes']);
      post.votes = value['votes'];
      post.isVoted = voted;
      print(post.isVoted);
      if (voted) {
        int option = whichOption(value['votes']);
        if (option != 0) {
          post.whichOption = option;
        }
      }
    } else {
      post.isVoted = false;
    }

    if (value['likes'] != null) {
      var liked = checkIsLiked(value['likes']);
      post.isLiked = liked;
    } else {
      post.isLiked = false;
    }

    if (value['tcQuestion'] != null) {
      post.tcQuestion = value['tcQuestion'];
    }

    var i = 0;

    if (filters != null) {
      if (post.userId != firebaseAuth.currentUser.uid) {
        for (var filter in filters) {
          if (post.content.toLowerCase().contains(filter.toLowerCase())) {
            i += 1;
          }
        }
      }
    }

    if (i == 0 &&
        blockList.contains(post.userId) == false &&
        hiddenList.contains(post.id) == false) {
      p.add(post);
    }
  });

  if (sortBy == 0) {
    p.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  } else {
    p.sort((a, b) => (b.userId == firebaseAuth.currentUser.uid)
        .toString()
        .compareTo((a.userId == firebaseAuth.currentUser.uid).toString()));
  }
  return p;
}
