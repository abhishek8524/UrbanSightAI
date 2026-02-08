import 'package:cloud_firestore/cloud_firestore.dart';

// Collection names
const String usersCollection = 'users';
const String reportsCollection = 'reports';
const String statusHistorySubcollection = 'statusHistory';

/// Users collection reference.
CollectionReference<Map<String, dynamic>> get usersRef =>
    FirebaseFirestore.instance.collection(usersCollection);

/// Single user document reference.
DocumentReference<Map<String, dynamic>> userRef(String uid) =>
    usersRef.doc(uid);

/// Reports collection reference.
CollectionReference<Map<String, dynamic>> get reportsRef =>
    FirebaseFirestore.instance.collection(reportsCollection);

/// Single report document reference.
DocumentReference<Map<String, dynamic>> reportRef(String reportId) =>
    reportsRef.doc(reportId);

/// Status history subcollection for a report.
CollectionReference<Map<String, dynamic>> statusHistoryRef(String reportId) =>
    reportRef(reportId).collection(statusHistorySubcollection);

/// Single status entry document reference.
DocumentReference<Map<String, dynamic>> statusHistoryDoc(
  String reportId,
  String entryId,
) =>
    statusHistoryRef(reportId).doc(entryId);
