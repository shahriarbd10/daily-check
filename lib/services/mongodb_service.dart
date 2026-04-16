import 'package:mongo_dart/mongo_dart.dart';
import 'dart:developer';

class MongoDBService {
  static const String mongoUrl = "mongodb://shahriarsgr_db_user:1S6tmAaRbwnKC6J0@ac-akbcvvl-shard-00-00.dvurtqp.mongodb.net:27017,ac-akbcvvl-shard-00-01.dvurtqp.mongodb.net:27017,ac-akbcvvl-shard-00-02.dvurtqp.mongodb.net:27017/?ssl=true&replicaSet=atlas-fpfuzx-shard-0&authSource=admin&appName=daily-office";
  static const String collectionName = "schedules";

  static dynamic db;
  static dynamic collection;

  static Future<void> connect() async {
    try {
      db = await Db.create(mongoUrl);
      await db.open();
      inspect(db);
      collection = db.collection(collectionName);
      print("Connected to MongoDB Atlas successfully");
    } catch (e) {
      print("Error connecting to MongoDB: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getSchedules() async {
    try {
      final schedules = await collection.find().toList();
      return schedules;
    } catch (e) {
      print("Error fetching schedules: $e");
      return [];
    }
  }

  static Future<void> addSchedule(Map<String, dynamic> schedule) async {
    try {
      await collection.insertOne(schedule);
    } catch (e) {
      print("Error adding schedule: $e");
    }
  }

  static Future<void> close() async {
    await db.close();
  }
}
