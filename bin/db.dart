library vercheck.db;

import 'dart:async' show Future;

import 'package:dbmapper/dbmapper.dart';

import 'env.dart';


Database database;

Future initializeDatabase() {
  database = null == postgresUrl ? new MemoryDatabase() : new PostgresDatabase(postgresUrl);
  
  return Future.wait([User.userTable, Repository.repositoryTable]
    .map(createTableIfNotExists));
}

Future createTableIfNotExists(Table table) {
  return database.hasTable(table.name).then((hasTable) {
    if (hasTable) return null;
    return database.createTable(table);
  });
}

abstract class Entity<E extends Entity> {
  bool _stored = false;
  
  Entity();
  
  Entity._fromMap() {
    this._stored = true;
  }
  
  bool get isStored => _stored;
  
  Map<String, dynamic> _toMap();
  
  Future<E> save() {
    if (isStored) {
      return insert();
    }
    return update();
  }
  
  Future<E> insert();
  
  Future<E> update();
}


class User extends Entity<User> {
  static final Table userTable = (new TableBuilder("users")
    ..addField(
        (new FieldBuilder("id", type: FieldType.integer)
          ..addConstraint(primaryKey))
          .build())
    ..addField(
        new Field("login")))
    .build();

  @primaryKey
  int id;
  
  @unique
  String login;
  
  User(this.id, this.login) : super();
  
  User._fromMap(Map<String, dynamic> map)
      : super._fromMap() {
    this.id = map["id"];
    this.login = map["login"];
  }
  
  Map<String, dynamic> _toMap() {
    return {
      "id": id,
      "login": login
    };
  }
  
  Future<User> insert() {
    return database.store(userTable.name, _toMap()).then((stored) {
      return new User._fromMap(stored);
    });
  }
  
  Future<User> update() {
    return database.update(userTable.name, {"id": id}, _toMap()).then((values) {
      return this;
    });
  }
  
  Future<List<Repository>> repositories() {
    return Repository.where({"userId": id});
  }
}

class Repository extends Entity<Repository> {
  static final Table repositoryTable = (new TableBuilder("repositories")
      ..addField(
          (new FieldBuilder("id", type: FieldType.integer)
            ..addConstraint(primaryKey))
            .build())
      ..addField(
          new Field("userId", type: FieldType.integer))
      ..addField(
          new Field("name")))
      .build();
  
  @primaryKey
  int id;
  
  int userId;
  
  String name;
  
  Repository(this.id, this.userId, this.name) : super();
  
  Repository._fromMap(Map<String, dynamic> map) : super._fromMap() {
    this.id = map["id"];
    this.name = map["name"];
    this.userId = map["userId"];
  }
  
  Map<String, dynamic> _toMap() {
    return {
      "id": id,
      "name": name,
      "userId": userId
    };
  }
  
  static Future<List<Repository>> where(Map<String, dynamic> criteria) {
    return database.where(repositoryTable.name, criteria).then((values) {
      return values.map((value) => new Repository._fromMap(value)).toList();
    });
  }
  
  Future<Repository> insert() {
    return database.store(repositoryTable.name, _toMap()).then((stored) {
      return new Repository._fromMap(stored);
    });
  }
  
  Future<Repository> update() {
    return database.update(repositoryTable.name, {"id": id}, _toMap()).then((values) {
      return this;
    });
  }
}