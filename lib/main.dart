import 'package:flutter/material.dart';

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
          //return MyMaterialApp();
          return MyListApp();
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return CircularProgressIndicator();
      },
    );
  }
}

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
                  title: Text(
                      '貸し借り:${data['borrowOrLend']} スタッフ:${data['stuff']}'),
                  subtitle: Text('date:${d.toDate()}\n'
                      'user:${data['user']}'),
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

// bool f_check() {
//   final es = BorrowOrLend.borrow.toString();
//   final b = BorrowOrLend.values.firstWhere((e) => e.toString() == es);
//   assert(b == BorrowOrLend.borrow);
//   return b == BorrowOrLend.borrow;
// }

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

  Future<void> _sample(BuildContext context) async {
    print('wait 5sec');
    await Future.delayed(Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    print('###build###');
    DocumentReference doc =
        FirebaseFirestore.instance.collection('kashikari-memo').doc();
    // todo: thenは非同期
    // doc.get().then((DocumentSnapshot d) {
    //   if (d.exists) {
    //     print('exist');
    //     print(d['user']);
    //     _formData.user = d['user'];
    //     _formData.stuff = d['stuff'];
    //   } else {
    //     print('no exist');
    //   }
    // }).catchError((error) {
    //   print(error);
    // });

    return Scaffold(
        appBar: AppBar(
          title: Text('入力画面'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                print('saved');
                if (_key.currentState!.validate()) {
                  _key.currentState!.save();
                  // todo データ名が冗長なのでdoc.set(_formData)のようにしたい。
                  // FireStore can set object with converter.
                  // https://firebase.google.cn/docs/firestore/manage-data/add-data?hl=ja
                  //
                  print('widget id:${widget._doc}');
                  // todo: すべて新規登録になっている。doc('id').にする.
                  doc.set({
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

class MyMaterialApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hello',
      home: MySandbox(),
    );
  }
}

class MySandbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('material app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('とりあえず、ボタン遷移でサンプルを作っていく。'),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (BuildContext c) {
                      return AddUserWidget('axb', 'xxx', 15);
                    }));
                  },
                  child: Text('firestoneユーザー登録')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (BuildContext c) {
                      return LendWidget();
                    }));
                  },
                  child: Text('貸し借りアプリ')),
              Divider(
                height: 1.0,
                color: Colors.red,
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (BuildContext c) {
                      return Scaffold(
                          appBar: AppBar(
                            title: const Text('ユーザ一覧表示'),
                          ),
                          body: UserList());
                    }));
                  },
                  child: Text('firestone UserList')),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (BuildContext c) {
                      return MySample();
                    }));
                  },
                  child: const Text('サンプル遷移'))
            ],
          ),
        ));
  }
}

class UserList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final _usersStream =
      FirebaseFirestore.instance.collection('users').snapshots();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _usersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Text('FireStore error!');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            //var l = snapshot.data!.docs.length;
            var data = document.data()! as Map<String, dynamic>;
            return ListTile(
              title: Text(data['full_name']),
              subtitle: Text(data['full_name']),
            );
          }).toList(),
        );
      },
    );
  }
}

class LendWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('貸し借りアプリ'),
      ),
    );
  }
}

class MySample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('画面遷移サンプル'),
      ),
      body: Column(
        children: [
          Text('これで単純なNavigatorが使えた!'),
          ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('戻るボタン'))
        ],
      ),
    );
  }
}

class AddUserWidget extends StatelessWidget {
  final String _fullName;
  final String company;
  final int age;

  AddUserWidget(this._fullName, this.company, this.age);

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    Future<void> addUser() {
      return users
          .add({'full_name': _fullName, 'company': company, 'age': age});
    }

    return TextButton(
        onPressed: () {
          addUser();
          Navigator.of(context).pop();
        },
        child: Text('FireStoneにユーザー登録'));
  }
}
