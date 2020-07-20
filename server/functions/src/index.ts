import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();

import * as plaid from 'plaid';

const plaidClient = new plaid.Client(
  functions.config().plaid.client_id,
  functions.config().plaid.secret,
  functions.config().plaid.public_key,
  plaid.environments.sandbox,
  {version: '2019-05-29'}, // '2019-05-29' | '2018-05-22' | '2017-03-08'
);

const SUPPORTED_ACCOUNT_TYPES = ["checking", "credit card"]

// add item from Plaid Link into Firestore by exchanging public_token with Plaid API
export const addItem = functions.https.onRequest(async (req, res) => {

  functions.logger.log("Req:", req.body);
  const publicToken = req.body.data.public_token;
  const userId = req.body.data.user_id;
  functions.logger.log("User ID:", userId);

  plaidClient.exchangePublicToken(publicToken).then(async (exchangeTokenRes: plaid.TokenResponse) => {
    const accessToken = exchangeTokenRes.access_token;
    functions.logger.log("Exchange Token Res:", exchangeTokenRes);

    const getAccountsRes = await plaidClient.getAccounts(accessToken);
    const getInstitutionRes = await plaidClient.getInstitutionById(getAccountsRes.item.institution_id);
    return {
      accessToken,
      getAccountsRes,
      getInstitutionRes,
    };
  }).then(getItemDetailsRes => {
    functions.logger.log("Get Item Details Res:", getItemDetailsRes);
    const accessToken = getItemDetailsRes.accessToken;
    const getAccountsRes: plaid.AccountsResponse = getItemDetailsRes.getAccountsRes;
    const getInstitutionRes: plaid.GetInstitutionByIdResponse<plaid.Institution> = getItemDetailsRes.getInstitutionRes;
    
    functions.logger.log("User ID:", userId);
    functions.logger.log("Access Token:", accessToken);
    functions.logger.log("Item:", getAccountsRes.item);
    functions.logger.log("Institution:", getInstitutionRes.institution)
    functions.logger.log("Accounts:", getAccountsRes.accounts);
    
    // Add item to user doc in Firestore

    // Add accounts
    getAccountsRes.accounts.forEach((accountElement: plaid.Account) => {
      if (!SUPPORTED_ACCOUNT_TYPES.includes(accountElement.subtype || '')) {
        functions.logger.log("Account was not added to Firestore:", accountElement.name);
        return;
      }

      admin.firestore().collection('userData').doc(userId).collection('items').doc(getAccountsRes.item.item_id).collection('accounts').doc(accountElement.account_id).set({
        mask: accountElement.mask,
        name: accountElement.name,
        official_name: accountElement.official_name,
        subtype: accountElement.subtype,
        type: accountElement.type,
      }).catch(() => {
        functions.logger.log('Error adding account to Firestore');
      });

      functions.logger.log("Account added to Firestore:", accountElement.name);
    });

    // Add access token and institution ID
    return admin.firestore().collection('userData').doc(userId).collection('items').doc(getAccountsRes.item.item_id).set({
      access_token: accessToken,
      institution_id: getAccountsRes.item.institution_id,
      institution_name: getInstitutionRes.institution.name,
      country_codes: getInstitutionRes.institution.country_codes,
    });
  }).then(() => {
    functions.logger.log("Added Plaid item to user doc in Firestore!");

  }).catch(err => {
    if (err instanceof plaid.PlaidError) {
      // Indicates plaid API error
      functions.logger.error('Plaid error', {
        error_type: err.error_type,
        error_code: res.statusCode,
        error_message: err.error_message,
        display_message: err.display_message,
        // request_id: err.request_id,
        // status_code: err.status_code,
      });
    } else {
      functions.logger.error("Unidentified error:", err);
    }
    res.sendStatus(500);
    return;

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