import * as functions from 'firebase-functions';
import * as plaid from 'plaid';

// The Firebase Admin SDK to access Cloud Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// add item from Plaid Link into Firestore by exchanging public_token with Plaid API
export const addItem = functions.https.onRequest(async (req, res) => {

  const plaidClient = new plaid.Client(
    process.env.PLAID_CLIENT_ID = `5e37326608bbc300147b421c`,
    process.env.PLAID_SECRET = `e426be468ca55de1286a829669872d`,
    process.env.PUBLIC_KEY = `cc12481ba9e7bd47809561ea23b521`,
    plaid.environments.sandbox,
    {version: '2019-05-29'} // '2019-05-29' | '2018-05-22' | '2017-03-08'
  );

  functions.logger.log("Req:", req.body);
  const public_token = req.body.data.public_token;
  const user_uid = req.body.data.user_uid;


  plaidClient.exchangePublicToken(public_token).then(exchangeTokenRes => {
    const accessToken = exchangeTokenRes.access_token;
    functions.logger.log("Exchange Token Res:", exchangeTokenRes);

    return plaidClient.getAccounts(accessToken).then(getAccountsRes => {
      return {
        accessToken,
        getAccountsRes,
      };
    });
  }).then(getAccountsAndAccessTokenRes => {
    functions.logger.log("Get Accounts and Access Token Res:", getAccountsAndAccessTokenRes);
    const accessToken = getAccountsAndAccessTokenRes.accessToken;
    const getAccountsRes = getAccountsAndAccessTokenRes.getAccountsRes;
    functions.logger.log(accessToken);
    functions.logger.log(getAccountsRes.item.item_id);
    functions.logger.log(getAccountsRes.accounts); 

    // Add item, access token, accounts to user doc in Firestore
    admin.firestore().collection('userData').document(user_uid).collection('items').document(getAccountsRes.item.item_id).set({
      access_token: accessToken,
      // accounts: getAccountsRes.accounts,
    });
    functions.logger.log("Added item, access token, accounts to user doc in Firestore"); 

  }).catch(err => {
    // Indicates a network or runtime error.
    if (!(err instanceof plaid.PlaidError)) {
      res.sendStatus(500);
      return;
    }

    // Indicates plaid API error
    functions.logger.log('/exchange token returned an error', {
      error_type: err.error_type,
      error_code: res.statusCode,
      error_message: err.error_message,
      display_message: err.display_message,
/*       request_id: err.request_id,
      status_code: err.status_code, */
    });

/*     // Retreive transactions for last 90 days
    const now = moment();
    const today = now.format('YYYY-MM-DD');
    const ninetyDaysAgo = now.subtract(90, 'days').format('YYYY-MM-DD');

    plaidClient.getTransactions(accessToken, ninetyDaysAgo, today, (err, res) => {
      functions.logger.log(res.transactions);
    }); */

  });

/* .catch(err => {


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
  functions.logger.log('Kyle says hello :D')
  response.send(`Hello ${request.body.person} from ${request.body.name}!!!`);
});