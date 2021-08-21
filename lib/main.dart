import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

/// We are using a StatefulWidget such that we only create the [Future] once,
/// no matter how many times our widget rebuild.
/// If we used a [StatelessWidget], in the event where [App] is rebuilt, that
/// would re-initialize FlutterFire and make our application re-enter loading state,
/// which is undesired.
class App extends StatefulWidget {
  // Create the initialization Future outside of `build`:
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  /// The future is part of the state of our widget. We should not call `initializeApp`
  /// directly inside [build].
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize FlutterFire:
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print(snapshot.error.toString());
          return Container(color: Colors.red);
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          //return MyListApp();
          return MaterialApp(
            title: 'ほほほ',
            //home: UserRegistrationPage(),
            home: UserAuthPage(),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return CircularProgressIndicator();
      },
    );
  }
}

class UserAuthPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => UserAuthPageState();
}

class UserAuthPageState extends State<UserAuthPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String message = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ユーザー認証')),
      body: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メールアドレスを入力してください。';
                  }
                },
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              SizedBox(
                height: 10.0,
              ),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'パスワード'),
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              SizedBox(
                height: 10.0,
              ),
              ElevatedButton(
                  onPressed: () async {
                    print('onPressed');
                    try {
                      final credential = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                              email: email, password: password);
                      setState(() {
                        message = '登録成功.${credential.user!.displayName}';

                        Navigator.of(context).push(MaterialPageRoute(
                            settings: RouteSettings(name: '/list'),
                            builder: (context) => MyList()));
                      });
                    } catch (e) {
                      setState(() {
                        message = '登録失敗:${e.toString()}';
                      });
                    }
                  },
                  child: Text('ログイン')),
              SizedBox(
                height: 10.0,
              ),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

class UserRegistrationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => UserRegistrationPageState();
}

class UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ユーザー登録')),
      body: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メールアドレスを入力してください。';
                  }
                },
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              SizedBox(
                height: 10.0,
              ),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'パスワード'),
                onChanged: (value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              SizedBox(
                height: 10.0,
              ),
              ElevatedButton(
                  onPressed: () async {
                    print('onPressed');
                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                              email: email, password: password);
                      setState(() {
                        message = '登録成功.${credential.user!.displayName}';
                      });
                    } catch (e) {
                      setState(() {
                        message = '登録失敗:${e.toString()}';
                      });
                    }
                  },
                  child: Text('ユーザー登録')),
              SizedBox(
                height: 10.0,
              ),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO ここが起点。
class MyListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hello',
      home: MyList(),
    );
  }
}

class MyList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyListState();
}

class MyListState extends State<MyList> {
  final _kkStream =
      FirebaseFirestore.instance.collection('kashikari-memo').snapshots();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('list'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: StreamBuilder(
          stream: _kkStream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return Text('loading...');
            return ListView(
              children: snapshot.data!.docs.map((document) {
                var data = document.data()! as Map<String, dynamic>;
                var d = data['date'] as Timestamp;
                return ListTile(
                  leading: Icon(Icons.android),
                  title: Text('${data['borrowOrLend']} 誰が:${data['stuff']}'),
                  subtitle: Text('date:${d.toDate()}\n'
                      '誰に:${data['user']}'),
                  //trailing: Icon(Icons.mode_edit),
                  trailing: IconButton(
                    onPressed: () {
                      print('mode_edit icon onPressed.');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            settings: RouteSettings(name: '/edit'),
                            builder: (context) => InputForm(document)),
                      );
                    },
                    icon: Icon(Icons.mode_edit),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('floatingActionButton');
          Navigator.of(context).push(MaterialPageRoute(
            settings: RouteSettings(name: '/new'),
            builder: (context) => InputForm(null),
          ));
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class InputForm extends StatefulWidget {
  final DocumentSnapshot? _doc; // nullable

  InputForm(this._doc);

  @override
  State<StatefulWidget> createState() => _InputForm();
}

enum BorrowOrLend { borrow, lend }

class _InputFormData {
  var borrowOrLend = BorrowOrLend.borrow;
  String user = ""; //todo
  String stuff = ""; // todo
  var date = DateTime.now();
  var path = "";
}

class _InputForm extends State<InputForm> {
  final _formData = _InputFormData();
  final _key = GlobalKey<FormState>();

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime(2023));
    if (pickedDate != null) {
      setState(() {
        print('_selectDate:${_formData.date}');
        _formData.date = pickedDate;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    print('###initState###');
    if (widget._doc != null) {
      print(widget._doc);
      print(widget._doc!.exists);
      print(widget._doc!['borrowOrLend']);
      // todo: もっと良い書き方。 convert
      _formData.borrowOrLend = BorrowOrLend.values
          .firstWhere((e) => e.toString() == widget._doc!['borrowOrLend']);
      _formData.stuff = widget._doc!['stuff'];
      _formData.user = widget._doc!['user'];
    }
  }

  @override
  Widget build(BuildContext context) {
    print('###build###');
    return Scaffold(
        appBar: AppBar(
          title: Text('入力画面'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print('saved');
                if (_key.currentState!.validate()) {
                  print('validate ok.');
                  _key.currentState!.save();
                  print('save currentState.');
                  // todo データ名が冗長なのでdoc.set(_formData)のようにしたい。
                  // FireStore can set object with converter.
                  // https://firebase.google.cn/docs/firestore/manage-data/add-data?hl=ja
                  //
                  FirebaseFirestore.instance
                      .collection('kashikari-memo')
                      .doc(widget._doc?.id)
                      .set({
                    'borrowOrLend': _formData.borrowOrLend.toString(),
                    'user': _formData.user,
                    'stuff': _formData.stuff,
                    'date': Timestamp.fromDate(_formData.date),
                  }).then((value) => Navigator.of(context).pop());
                } else {
                  print('invalidate!');
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                print('delete');
                FirebaseFirestore.instance
                    .collection('kashikari-memo')
                    .doc(widget._doc?.id)
                    .delete()
                    .then((value) => Navigator.of(context).pop());
              },
            ),
          ],
        ),
        body: SafeArea(
            child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _key,
            child: Column(
              children: [
                RadioListTile(
                    title: Text('借り'),
                    value: BorrowOrLend.borrow,
                    groupValue: _formData.borrowOrLend,
                    onChanged: _changeBorrowOrLend),
                RadioListTile(
                    title: Text('貸し'),
                    value: BorrowOrLend.lend,
                    groupValue: _formData.borrowOrLend,
                    onChanged: _changeBorrowOrLend),
                TextFormField(
                  decoration: InputDecoration(
                      icon: Icon(Icons.person),
                      hintText: '相手の名前',
                      labelText: '名前'),
                  validator: (str) {
                    if (str == null || str.isEmpty) {
                      print('show error message!');
                      print('str is null or empty');
                      return 'required';
                    }
                    print('validator user: arg=$str');
                  },
                  onSaved: (s) {
                    _formData.user = s ?? '';
                    print('saved(user): ${_formData.user}');
                  },
                  initialValue: _formData.user,
                ),
                TextFormField(
                  decoration: InputDecoration(
                      icon: Icon(Icons.business_center),
                      hintText: '貸し借りした物',
                      labelText: 'ローン'),
                  validator: (str) {
                    if (str == null || str.isEmpty) {
                      print('show error message!');
                      print('str is null or empty');
                      return 'required';
                    }
                    print('validator user: loan=$str');
                  },
                  onSaved: (s) {
                    _formData.stuff = s ?? '';
                    print('saved(stuff): ${_formData.stuff}');
                  },
                  initialValue: _formData.stuff,
                ),
                Text('締切日 ${_formData.date}'),
                ElevatedButton(
                  onPressed: () {
                    print('call date picker.');
                    _selectDate(context);
                  },
                  child: Text('締切日変更'),
                )
              ],
            ),
          ),
        )));
  }

  _changeBorrowOrLend(value) {
    print('called _changeBorrowOrLend value=:$value');
    print('  _formData.borrowOrLend=:${_formData.borrowOrLend}');
    setState(() {
      _formData.borrowOrLend = value;
    });
  }
}
