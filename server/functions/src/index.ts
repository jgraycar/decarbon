import * as functions from 'firebase-functions';

// The Firebase Admin SDK to access Cloud Firestore.
// const admin = require('firebase-admin');
// admin.initializeApp();

export const helloWorld = functions.https.onRequest((request, response) => {
  console.log('Kyle says hello :D')
  response.send("Hello from Decarbon!!!");
});

/*
// add item from Plaid Link into Firestore by getting Access Token from Plaid first

exports.addItem = functions.https.onRequest(async (req, res) => {

  // Grab the Plaid public token.
  const publicToken = req.body;

  // Push the public token into Plaid.
  const plaidPost = functions.https.onCall((data, context) => {
    // Do something
  });

  // Receive the access token from Plaid (along with metadata?).
  const plaidResponse = ...

  // Push the access token, item ID (IID), metadata into Firestore with Firebase admin SDK.
  const writeResult = await admin.firestore().collection('items').document($IID).add({access_token: access_token, metadata: metadata});

  // Send back a message that we've succesfully added the Item
  res.json({result: `Item with ID: $IID added.`});
});
*/