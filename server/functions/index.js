const functions = require('firebase-functions');

// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// Take the text parameter passed to this HTTP endpoint and insert it into
// Cloud Firestore under the path /messages/:documentId/original
exports.addItem = functions.https.onRequest(async (req, res) => {

  // Grab the Plaid public token.
  const publicToken = req.body;

  // Push the public token into Plaid.
  const plaidPost = https.onCall 

  // Receive the access token from Plaid (along with metadata?).
  const plaidResponse = ...

  // Push the access token, item ID (IID), metadata into Firestore with Firebase admin SDK.
  const writeResult = await admin.firestore().collection('items').document($IID).add({access_token: access_token, metadata: metadata});

  // Send back a message that we've succesfully added the Item
  res.json({result: `Item with ID: $IID added.`});
});