import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dcrbn3/main.dart';
import 'package:dcrbn3/user.dart';

class DatabaseService {

  final String uid;
  DatabaseService({ this.uid });

  // collection reference userData = brews
  final CollectionReference userData = Firestore.instance.collection('userData');

  Future updateUserData(String name, String diet) async {
    return await userData.document(uid).setData({
      'name': name,
      'diet': diet,
    });
  }

  // userData profile from snapshot
  List<Brew> _brewListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((doc){
      return Brew(
        name: doc.data['name'] ?? '',
        diet: doc.data['diet'] ?? '',
      );
    }).toList();
  }

  // userProfileData from snapshot
  UserData _userProfileDataFromSnapshot(DocumentSnapshot snapshot) {
    return UserData(
      uid: uid,
      name: snapshot.data['name'],
      diet: snapshot.data['diet'],
    );
  }

  // get userData stream
  Stream<List<Brew>> get brews {
    return userData.snapshots()
      .map(_brewListFromSnapshot);
  }

  // get user doc stream
  Stream<UserData> get userProfileData {
    return userData.document(uid).snapshots()
      .map(_userProfileDataFromSnapshot);
  }

}

class Brew {

  final String name;
  final String diet;

  Brew({ this.name, this.diet });

}