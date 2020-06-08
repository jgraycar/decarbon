// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:string_validator/string_validator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const String _title = 'DECARBON';

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User>.value(
      value: AuthService().user,
      child: MaterialApp(
        title: _title,
        routes: {
          '/signin': (BuildContext context) => SignIn(),
          '/register': (BuildContext context) => Register(),
        },
        home: Wrapper(),
        theme: ThemeData(
          // Define the default brightness and colors.
          brightness: Brightness.light,
          primaryColor: Colors.white,
          accentColor: Colors.cyan[600],
          splashColor: Colors.transparent,

          // Define the default font family.
          fontFamily: 'Helvetica',

          // Define the default TextTheme. Use this to specify the default
          // text styling for headlines, titles, bodies of text, and more.
          textTheme: TextTheme(
            headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            title: TextStyle(fontSize: 10.0, fontStyle: FontStyle.italic),
            body1: TextStyle(fontSize: 14.0),
          ),

          appBarTheme: AppBarTheme(
            elevation: 1,
          ),

          // Button styling
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(25.0),
            ),
          ),

          // Form styling
          inputDecorationTheme: InputDecorationTheme(
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1.0)),
            errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1.0)),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red[200], width: 1.0)),
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// Loading Spinner

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Center(
          child: SpinKitRing(
            color: Colors.black,
            size: 50.0,
          ),
        ));
  }
}

// User Authentication

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);

    // return either Home or Auth widget
    if (user == null) {
      return Authenticate();
    } else {
      return Home();
    }
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // create user obj based on FirebaseUser
  User _userFromFirebaseUser(FirebaseUser user) {
    return user != null ? User(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<User> get user {
    return _auth.onAuthStateChanged.map(_userFromFirebaseUser);
  }

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email and password
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;

      // create a new userData document for the user with the uid
      await _databaseService.updateUserData(
          user.uid, 'No name provided', 'Omnivore', 0);
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign in with google account
  // register with google account
  // sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;
  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    if (showSignIn) {
      return SignIn(toggleView: toggleView);
    } else {
      return Register(toggleView: toggleView);
    }
  }
}

// User log in widget and log in form

class SignIn extends StatefulWidget {
  final Function toggleView;
  SignIn({this.toggleView});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'images/decarbon_icon.png',
                      width: 30,
                    ),
                    SizedBox(height: 10.0),
                    Image.asset('images/decarbon-logo.png'),
                    SizedBox(height: 60.0),
                    TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Email',
                        ),
                        validator: (val) =>
                            val.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() => email = val);
                        }),
                    SizedBox(height: 20.0),
                    TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                        ),
                        validator: (val) => val.length < 6
                            ? 'Enter a password longer than 6 characters'
                            : null,
                        onChanged: (val) {
                          setState(() => password = val);
                        }),
                    SizedBox(height: 20.0),
                    RaisedButton(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.black),
                          borderRadius: new BorderRadius.circular(3.0),
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            setState(() => loading = true);
                            dynamic result = await _auth
                                .signInWithEmailAndPassword(email, password);
                            if (result == null) {
                              setState(() {
                                error =
                                    'Count not log in with those credentials';
                                loading = false;
                              });
                            }
                          }
                        }),
                    SizedBox(height: 12.0),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red, fontSize: 14.0),
                    ),
                    SizedBox(height: 60.0),
                    GestureDetector(
                      onTap: () {
                        widget.toggleView();
                      },
                      child: Text('Or register'),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

// User Register widget and register form

class Register extends StatefulWidget {
  final Function toggleView;
  Register({this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // text field state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.white,
            body: Container(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'images/decarbon_icon.png',
                      width: 30,
                    ),
                    SizedBox(height: 10.0),
                    Image.asset('images/decarbon-logo.png'),
                    SizedBox(height: 60.0),
                    TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Email',
                        ),
                        validator: (val) =>
                            val.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() => email = val);
                        }),
                    SizedBox(height: 20.0),
                    TextFormField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                        ),
                        validator: (val) => val.length < 6
                            ? 'Enter a password longer than 6 characters'
                            : null,
                        onChanged: (val) {
                          setState(() => password = val);
                        }),
                    SizedBox(height: 20.0),
                    RaisedButton(
                      color: Colors.black,
                      child: Text(
                        'Register',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          setState(() => loading = true);
                          dynamic result = await _auth
                              .registerWithEmailAndPassword(email, password);
                          if (result == null) {
                            setState(() {
                              error = 'Please supply a valid email';
                              loading = false;
                            });
                          }
                        }
                      },
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      error,
                      style: TextStyle(color: Colors.red, fontSize: 14.0),
                    ),
                    SizedBox(height: 60.0),
                    GestureDetector(
                      onTap: () {
                        widget.toggleView();
                      },
                      child: Text('Or log in'),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

// App Home

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle();
  static List<Widget> _widgetOptions = <Widget>[
    RandomWords(),
    MyHomePage(),
    UserProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dehaze),
            title: Text('Transactions'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.language),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 4,
      ),
    );
  }
}

//RandomWords

class RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final Set<WordPair> _saved = Set<WordPair>();
  final _biggerFont = const TextStyle(fontSize: 16.0);

  @override
  Widget build(BuildContext context) {
    void _showAccountsPanel() {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: AccountsPanel(),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        backgroundColor: Colors.white,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.search), onPressed: null),
        title: Text('Purchases'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.account_balance), onPressed: _showAccountsPanel),
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return Divider();

          final index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final bool alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  RandomWordsState createState() => RandomWordsState();
}

class AccountsPanel extends StatefulWidget {
  @override
  _AccountsPanelState createState() => _AccountsPanelState();
}

class _AccountsPanelState extends State<AccountsPanel> {
  void _showPlaidLink() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return MaterialApp(
            initialRoute: PlaidThree.id,
            routes: {
              PlaidThree.id: (context) => PlaidThree(),
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Tap + to add an account.')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[50],
        onPressed: _showPlaidLink,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}

class PlaidThree extends StatefulWidget {
  static const id = 'plaid_screen_id';

  @override
  _PlaidThreeState createState() => _PlaidThreeState();
}

class _PlaidThreeState extends State<PlaidThree> {
  PlaidLink _plaidLink;

  @override
  void initState() {
    super.initState();

    _plaidLink = PlaidLink(
      clientName: "Decarbon",
      publicKey: "cc12481ba9e7bd47809561ea23b521",
      // oauthRedirectUri: "myapp://test", //required for android!
      // oauthNonce: "",
      // userLegalName: "John Doe", //required for auth product
      // userEmailAddress: "johndoe@app.com", //required for auth product
      // webhook: optional, receive notifications once a userʼs transactions have been processed and are ready for use. https://github.com/jorgefspereira/plaid_flutter/blob/master/lib/plaid_flutter.dart
      env: EnvOption.sandbox,
      products: <ProductOption>[ProductOption.transactions],
      accountSubtypes: {
        "depository": ["checking", "savings"], // only for auth product
      },
      onAccountLinked: (publicToken, metadata) {
        print("onAccountLinked: $publicToken metadata: $metadata");
      },
      onAccountLinkError: (error, metadata) {
        print("onAccountError: $error metadata: $metadata");
      },
      onEvent: (event, metadata) {
        print("onEvent: $event metadata: $metadata");
      },
      onExit: (metadata) {
        print("onExit: $metadata");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: Center(
                child: RaisedButton(
      onPressed: () {
        _plaidLink.open();
      },
      child: Text("Open Plaid Link"),
    ))));
  }
}

// TheWorld

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({this.title});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int theriGroupVakue = 0;

  final Map<int, Widget> logoWidgets = const <int, Widget>{
    0: Text("D"),
    1: Text("W"),
    2: Text("M"),
    3: Text("Y")
  };

  static Widget giveCenter(String yourText) {
    return Center(
      child: Text("$yourText"),
    );
  }

  List<Widget> bodies = [
    giveCenter("Home Page"),
    giveCenter("Search Page"),
    giveCenter("Chat Room"),
    giveCenter("Blahblah")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bodies[theriGroupVakue],
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          'images/decarbon-logo.png',
          width: 110,
        ),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 45.0),
          child: Padding(
            padding: EdgeInsets.only(top: 5.0, bottom: 10.0),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 15.0,
                ),
                Expanded(
                  child: CupertinoSlidingSegmentedControl(
                    groupValue: theriGroupVakue,
                    onValueChanged: (changeFromGroupValue) {
                      setState(() {
                        theriGroupVakue = changeFromGroupValue;
                      });
                    },
                    children: logoWidgets,
                  ),
                ),
                SizedBox(
                  width: 15.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// UserProfile

class UserProfileState extends State<UserProfile> {
  final AuthService _auth = AuthService();
  final GlobalKey _scaffoldKey = new GlobalKey();
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    void _showSettingsPanel() {
      showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 60.0, horizontal: 60.0),
            child: SettingsForm(),
          );
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        backgroundColor: Colors.white,
      );
    }

    return StreamBuilder<UserData>(
        stream: _databaseService.getUserProfileData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;
            return Scaffold(
              key: _scaffoldKey,
              appBar: AppBar(
                title: Text('Profile'),
                leading: IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () async {
                    await _auth.signOut();
                  },
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () => _showSettingsPanel(),
                  ),
                ],
              ),
              body: Center(
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, 40, 0, 0),
                  child: Column(
                    children: <Widget>[
                      Text(userData.name,
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.restaurant),
                          Container(
                            margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                            child: Text(userData.diet),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.wb_sunny),
                          Container(
                            margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                            child: Text(
                                "${userData.renewables.toString()}% renewable"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
                key: _scaffoldKey,
                appBar: AppBar(
                  title: Text('Profile'),
                  leading: IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () async {
                      await _auth.signOut();
                    },
                  ),
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () => _showSettingsPanel(),
                    ),
                  ],
                ),
                body: null);
          }
        });
  }
}

class UserProfile extends StatefulWidget {
  @override
  UserProfileState createState() => UserProfileState();
}

class SettingsForm extends StatefulWidget {
  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final List<String> diet = ['Omnivore', 'Pescatarian', 'Vegetarian', 'Vegan'];
  final DatabaseService _databaseService = DatabaseService();

  // form values
  String _currentName;
  String _currentDiet;
  int _currentRenewables;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    final AuthService _auth = AuthService();

    return StreamBuilder<UserData>(
        stream: _databaseService.getUserProfileData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            UserData userData = snapshot.data;

            return Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Text('Update Profile',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 30.0),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name *'),
                    initialValue: userData.name,
                    validator: (val) =>
                        val.isEmpty ? 'Please enter a name' : null,
                    onChanged: (val) => setState(() => _currentName = val),
                  ),
                  SizedBox(height: 20.0),
                  // dropdown
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Diet'),
                    isDense: true,
                    value: _currentDiet ?? userData.diet,
                    items: diet.map((diet) {
                      return DropdownMenuItem(
                          value: diet, child: Text('$diet'));
                    }).toList(),
                    onChanged: (val) => setState(() => _currentDiet = val),
                  ),
                  SizedBox(height: 20.0),
                  Stack(
                    children: <Widget>[
                      Container(
                        width: 115,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Renewables',
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: userData.renewables.toString(),
                          validator: (val) {
                            if (val.isEmpty) {
                              return 'Enter an integar between 0 and 100';
                            } else if (int.parse(val) > 100) {
                              return 'Enter an integar between 0 and 100';
                            } else if (int.parse(val) < 0) {
                              return 'Enter an integar between 0 and 100';
                            } else {
                              return null;
                            }
                          },
                          onChanged: (val) => setState(
                              () => _currentRenewables = int.parse(val)),
                        ),
                      ),
                      Container(
                          width: 115,
                          height: 50,
                          padding: EdgeInsets.fromLTRB(0, 0, 15, 0),
                          alignment: Alignment.centerRight,
                          child: Text('%')),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  RaisedButton(
                    child: Text(
                      'Update',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        await _databaseService.updateUserData(
                          user.uid,
                          _currentName ?? userData.name,
                          _currentDiet ?? userData.diet,
                          _currentRenewables ?? userData.renewables,
                        );
                        Navigator.pop(context);
                      }
                      print(_currentName);
                      print(_currentDiet);
                      print(_currentRenewables);
                    },
                  ),
                  SizedBox(height: 20.0),
/*                GestureDetector(
                  onTap: () async {
                    await _auth.signOut();
                  },
                  child: Text('Log out'),
                ),*/
                ],
              ),
            );
          } else {
            return Loading();
          }
        });
  }
}

// DATA MODEL

class User {
  final String uid;

  User({this.uid});
}

class UserData {
  final String uid;
  final String name;
  final String diet;
  final int renewables;

  UserData({this.uid, this.name, this.diet, this.renewables});
}

class DatabaseService {
  // final String uid;
  // DatabaseService({this.uid});

  // collection reference userData
  final CollectionReference userData = Firestore.instance.collection(
      'userData'); // Need to add .where clause here? how to make uid dynamic?

  // update single user's data
  Future updateUserData(
      String uid, String name, String diet, int renewables) async {
    return await userData.document(uid).setData({
      'name': name,
      'diet': diet,
      'renewables': renewables,
    });
  }

  // get user doc stream
  Stream<UserData> getUserProfileData(String uid) {
    UserData _userProfileDataFromSnapshot(DocumentSnapshot snapshot) {
      String name = snapshot.data['name'];
      String diet = snapshot.data['diet'];
      int renewables = snapshot.data['renewables'];
      return UserData(
        uid: uid,
        name: name,
        diet: diet,
        renewables: renewables,
      );
    }

    return userData.document(uid).snapshots().map(_userProfileDataFromSnapshot);
  }
}
