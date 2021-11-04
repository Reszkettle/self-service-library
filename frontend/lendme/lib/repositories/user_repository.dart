import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lendme/exceptions/exceptions.dart';
import 'package:lendme/models/resource.dart';
import 'package:lendme/models/user.dart';
import 'package:lendme/models/user_info.dart';

class UserRepository {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User> getUser(String uid) async {
    try {
      DocumentSnapshot snapshot = await _firestore
          .collection("users")
          .doc(uid)
          .get();
      Map<String, dynamic>? map = snapshot.data() as Map<String, dynamic>?;
      if(map == null) {
        throw ResourceNotFoundException();
      }
      User user = _map2User(map, uid);
      return user;
    } catch (e) {
      throw UnknownException();
    }
  }

  Stream<Resource<User>> getUserStream(String uid) {
    try {
      return _firestore
          .collection("users")
          .doc(uid)
          .snapshots()
      .map((snapshot) {
        Map<String, dynamic>? map = snapshot.data();
        if(map == null) {
          return Resource.error(ResourceNotFoundException());
        }
        User user = _map2User(map, uid);
        return Resource.success(user);
      });
    } catch (e) {
      throw UnknownException();
    }
  }

  Future setUserInfo(String uid, UserInfo userInfo) async {
    try {
      Map<String, dynamic> data = {
        'info': _userInfo2Map(userInfo)
      };

      await _firestore.runTransaction((transaction) async {
        DocumentReference ref = _firestore.collection("users").doc(uid);
        transaction.update(ref, data);
      });
    } catch (e) {
      throw UnknownException();
    }
  }

  User _map2User(Map<String, dynamic> map, String uid) {
    Timestamp t = map['createdAt'] as Timestamp;
    return User(
        uid: uid,
        avatarUrl: map['avatarUrl'] as String?,
        createdAt: t.toDate(),
        info: _map2UserInfo(map['info'])
    );
  }

  UserInfo _map2UserInfo(Map<String, dynamic> map) {
    return UserInfo(
        firstName: map['firstName'] as String?,
        lastName: map['lastName'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?
    );
  }

  Map<String, dynamic> _userInfo2Map(UserInfo map) {
    return {
      'firstName': map.firstName,
      'lastName': map.lastName,
      'phone': map.phone,
      'email': map.email
    };
  }
}
