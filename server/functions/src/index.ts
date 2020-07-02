import * as functions from 'firebase-functions';
import * as plaid from 'plaid';

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// add item from Plaid Link into Firestore by exchanging public_token with Plaid API
export const addItem = functions.https.onRequest(async (req, res) => {

  const plaidClient = new plaid.Client(
    process.env.PLAID_CLIENT_ID = `5e37326608bbc300147b421c`, // did I set this up right?
    process.env.PLAID_SECRET = `e426be468ca55de1286a829669872d`,
    process.env.PUBLIC_KEY = `cc12481ba9e7bd47809561ea23b521`,
    plaid.environments.sandbox,
    {version: '2019-05-29'} // '2019-05-29' | '2018-05-22' | '2017-03-08'
  );

  const public_token = req.body.public_token;

  plaidClient.exchangePublicToken(public_token, function(err, exchangePublicTokenRes) {
    const accessToken = exchangePublicTokenRes.access_token;

    plaidClient.getAccounts(accessToken, function(getAccountsErr, getAccountsRes) {
      console.log(getAccountsRes.item);
      console.log(getAccountsRes.accounts);

      // Add to server
      admin.firestore().collection('items').document(getAccountsRes.item).add({access_token: accessToken, accounts: getAccountsRes.accounts});
    });

/*     // Retreive transactions for last 90 days
    const now = moment();
    const today = now.format('YYYY-MM-DD');
    const ninetyDaysAgo = now.subtract(90, 'days').format('YYYY-MM-DD');

    plaidClient.getTransactions(accessToken, ninetyDaysAgo, today, (err, res) => {
      console.log(res.transactions);
    }); */

  });

  /* .catch(err => {
    // Indicates a network or runtime error.
    if (!(err instanceof plaid.PlaidError)) {
      res.sendStatus(500);
      return;
    }

    // Indicates plaid API error
    console.log('/exchange token returned an error', {
      error_type: err.error_type,
      error_code: res.statusCode,
      error_message: err.error_message,
      display_message: err.display_message,
      request_id: err.request_id,
      status_code: err.status_code,
    });

    // Inspect error_type to handle the error in your application
    switch(err.error_type) {
        case 'INVALID_REQUEST':
          // ...
          break;
        case 'INVALID_INPUT':
          // ...
          break;
        case 'RATE_LIMIT_EXCEEDED':
          // ...
          break;
        case 'API_ERROR':
          // ...
          break;
        case 'ITEM_ERROR':
          // ...
          break;
        default:
          // fallthrough
    }
  } */

});

export const helloWorld = functions.https.onRequest((request, response) => {
  console.log('Kyle says hello :D')
  response.send(`Hello ${request.body.person} from ${request.body.name}!!!`);
});