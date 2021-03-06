import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

Future<Null> isWorking;

class MyDb {
  Database db;
  initDb() async {
    if (isWorking != null) {
      await isWorking;
    }
    if (db != null) {
      return db;
    }
    var completer = new Completer<Null>();
    isWorking = completer.future;
    db = await openDatabase("gsc_like.db", version: 3,
        onCreate: (Database db, int version) async {
      await db.transaction((tx) async {
        await tx.execute("""
            CREATE TABLE `gsc_like`( 
            `id` integer NOT NULL,
            `work_title` varchar(512) NOT NULL DEFAULT '',
            `work_author` varchar(512) NOT NULL DEFAULT '',
            `work_dynasty` varchar(32) NOT NULL DEFAULT '',
            `content` text NOT NULL default '',
            `translation` text NOT NULL default '',
            `intro` text,
            `author_intro` text,
            `baidu_wiki` varchar(256) default '',
            `audio_id` integer not null default 0,
            `foreword` text,
            `annotation` text ,
            `appreciation` text ,
            `master_comment` text ,
            `layout` varchar(10) DEFAULT 'indent', 
            `like` tinyint NOT NULL default 0,
            `short_content` varchar(256) NOT NULL DEFAULT '',
            `play_url` varchar(256) NOT NULL DEFAULT '',
            `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP);
            """);
      });
    });
    completer.complete();
    isWorking = null;
    return db;
  }

  Future<int> insert(String tableName, Map<String, dynamic> map) async {
    await initDb();
    return await db.insert(tableName, map);
  }

  Future<int> delete(String tableName, int id) async {
    await initDb();
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map>> query(
    String tableName,
    List<String> columns,
    String where,
    List<dynamic> whereArgs,
  ) async {
    await initDb();
    List<Map> maps = await db.query(tableName,
        columns: columns, where: where, whereArgs: whereArgs);
    return maps;
  }

  MyDb() {
    debugPrint("init Db.................");
    initDb();
  }
}

final MyDb dB = new MyDb();

class Author {
  Map authors;

  initAuthor() async {
    String authorString = await rootBundle.loadString("data/authors.json");
    authors = json.decode(authorString);
  }

  Author() {
    initAuthor();
  }
}

final Author authorM = Author();

class Gsc {
  int id;
  int audioId;
  String workTitle;
  String workAuthor;
  String content;
  String workDynasty;
  String layout;
  String translation;
  String intro;
  String foreword;
  String appreciation;
  String shortContent;
  String playUrl;
  String masterComment;
  String annotation;
  Map authorIntro;
  int like = 0;

  void setShortContent() {
    // 句号
    var periodIndex = this.content.indexOf("。");
    if (periodIndex == -1) {
      // 感叹号
      var exclamatoryMarkIndex = this.content.indexOf("！");
      if (exclamatoryMarkIndex == -1) {
        // 问号
        var questionMarkIndex = this.content.indexOf("？");
        this.shortContent = this.content.substring(0, questionMarkIndex + 1);
      } else {
        this.shortContent = this.content.substring(0, exclamatoryMarkIndex + 1);
      }
    } else {
      this.shortContent = this.content.substring(0, periodIndex + 1);
    }
  }

  Gsc(Map gsc) {
    this.id = gsc["id"];
    this.content = gsc["content"];
    this.workAuthor = gsc["work_author"];
    this.workTitle = gsc["work_title"];
    this.workDynasty = gsc["work_dynasty"];
    this.layout = gsc["layout"];
    this.translation = gsc["translation"];
    this.intro = gsc["intro"];
    this.foreword = gsc["foreword"];
    this.appreciation = gsc["appreciation"];
    this.masterComment = gsc["master_comment"];
    this.audioId = gsc["audio_id"];
    this.annotation = gsc["annotation"];

    setShortContent();

    if (this.layout == 'indent') {
      this.content = "　　" +
          this
              .content
              .replaceAll(" ", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.translation.length > 0) {
      this.translation = "　　" +
          this
              .translation
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.foreword.length > 0) {
      this.foreword = "　　 " + this.foreword.replaceAll(" ", "");
    }
    if (this.masterComment.length > 0) {
      this.masterComment = "　　" +
          this
              .masterComment
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.intro.length > 0) {
      this.intro = "　　" +
          this
              .intro
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.annotation.length > 0) {
      this.annotation = "　　" +
          this
              .annotation
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.appreciation.length > 0) {
      this.appreciation = "　　" +
          this
              .appreciation
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
    if (this.audioId > 0) {
      this.playUrl = "https://songci.nos-eastchina1.126.net/audio/{}.m4a"
          .replaceAll("{}", this.audioId.toString());
    } else {
      this.playUrl = "";
    }
    this.isLiked();
    this.workTitle = this.workTitle.replaceAll("　", "").replaceAll("/", "∙");
    this.queryAuthor();
  }

  queryAuthor() async {
    if (authorM.authors == null) {
      await authorM.initAuthor();
    }
    Map authorIntro = authorM.authors[this.workAuthor];
    if (authorIntro != null) {
      this.authorIntro = new Map.from(authorIntro);
      this.authorIntro["intro"] = "　　" +
          this
              .authorIntro["intro"]
              .replaceAll("　", "")
              .replaceAll(new RegExp(r"\n|\t"), "\n" + "　　");
    }
  }

  isLiked() async {
    var maps = await dB.query(
        "gsc_like", ["id"], "id = ? and `like` = ?", [this.id, 1]);
    if (maps.length > 0) {
      this.like = 1;
    } else {
      this.like = 0;
    }
    return like;
  }

  toLike() async {
    var map = this.toMap();
    map["like"] = 1;
    await dB.insert("gsc_like", map);
  }

  disLike() async {
    await dB.delete("gsc_like", this.id);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    map["id"] = this.id;
    map["audio_id"] = this.audioId;
    map["work_title"] = this.workTitle;
    map["work_author"] = this.workAuthor;
    map["work_dynasty"] = this.workDynasty;
    map["content"] = this.content;
    map["appreciation"] = this.appreciation;
    map["master_comment"] = this.masterComment;
    map["translation"] = this.translation;
    map["annotation"] = this.annotation;
    map["foreword"] = this.foreword;
    map["intro"] = this.intro;
    map["layout"] = this.layout;
    map["short_content"] = this.shortContent;
    map["play_url"] = this.playUrl;
    map["author_intro"] = json.encode(this.authorIntro);
    return map;
  }

  Gsc.fromDictionary(gsc) {
    this.id = gsc["id"];
    this.content = gsc["content"];
    this.workAuthor = gsc["work_author"];
    this.workTitle = gsc["work_title"];
    this.workDynasty = gsc["work_dynasty"];
    this.layout = gsc["layout"];
    this.translation = gsc["translation"];
    this.intro = gsc["intro"];
    this.foreword = gsc["foreword"];
    this.appreciation = gsc["appreciation"];
    this.masterComment = gsc["master_comment"];
    this.audioId = gsc["audio_id"];
    this.annotation = gsc["annotation"];
    this.shortContent = gsc["short_content"];
    this.playUrl = gsc["play_url"];
    this.like = gsc["like"];
    this.authorIntro = json.decode(gsc["author_intro"]);
  }
}
