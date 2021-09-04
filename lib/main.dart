import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
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
          return Container(color: Colors.red);
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          //return MyListApp();
          return MultiProvider(
              providers: [
                ChangeNotifierProvider<_InputFormData>(
                  create: (context) => _InputFormData(),
                ),
              ],
              child: MaterialApp(
                title: '貸し借りアプリ',
                initialRoute: '/auth',
                routes: {
                  '/user/register': (context) => UserRegistrationPage(),
                  '/auth': (context) => UserAuthPage(),
                  '/list': (context) => MyList(),
                  '/form': (context) => InputForm(),
                },
              ));
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
                  trailing: IconButton(
                    onPressed: () {
                      // Navigatorでデータを渡さず、モデルデータで渡す。
                      var m = context.read<_InputFormData>();
                      m.id = document.id;
                      m.borrowOrLend = BorrowOrLend.values.firstWhere(
                          (e) => e.toString() == data['borrowOrLend']); // Enum
                      m.user = data['user'];
                      m.stuff = data['stuff'];
                      m.date = d.toDate();

                      Navigator.pushNamed(context, '/form');
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
          context.read<_InputFormData>().reset();
          Navigator.pushNamed(context, '/form');
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}

enum BorrowOrLend { borrow, lend }

class _InputFormData extends ChangeNotifier {
  String id = '';
  var _borrowOrLend = BorrowOrLend.borrow;
  BorrowOrLend get borrowOrLend => _borrowOrLend;
  set borrowOrLend(BorrowOrLend v) {
    _borrowOrLend = v;
    notifyListeners();
  }

  String user = ''; //todo
  String stuff = ''; // todo
  var date = DateTime.now();
  var path = '';
  void reset() {
    id = '';
    _borrowOrLend = BorrowOrLend.borrow;
    user = '';
    stuff = '';
    date = DateTime.now();
    path = '';
  }
}

class InputForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InputForm();
}

class _InputForm extends State<InputForm> {
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var groupValue = context.watch<_InputFormData>().borrowOrLend;
    return Scaffold(
        appBar: AppBar(
          title: Text('入力画面'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                if (_key.currentState!.validate()) {
                  _key.currentState!.save();
                  // todo データ名が冗長なのでdoc.set(_formData)のようにしたい。
                  // FireStore can set object with converter.
                  // https://firebase.google.cn/docs/firestore/manage-data/add-data?hl=ja
                  //
                  var m = context.read<_InputFormData>();
                  FirebaseFirestore.instance
                      .collection('kashikari-memo')
                      .doc(m.id.isEmpty ? null : m.id)
                      .set({
                    'borrowOrLend': m.borrowOrLend.toString(),
                    'user': m.user,
                    'stuff': m.stuff,
                    'date': Timestamp.fromDate(m.date),
                  }).then((value) => Navigator.of(context).pop());
                }
                // todo not validate.
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('kashikari-memo')
                    .doc(context.read<_InputFormData>().id)
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
                    groupValue: groupValue,
                    onChanged: (value) {
                      context.read<_InputFormData>().borrowOrLend =
                          BorrowOrLend.values.firstWhere((e) => e == value);
                    }),
                RadioListTile(
                    title: Text('貸し'),
                    value: BorrowOrLend.lend,
                    groupValue: groupValue,
                    onChanged: (value) {
                      context.read<_InputFormData>().borrowOrLend =
                          BorrowOrLend.values.firstWhere((e) => e == value);
                    }),
                TextFormField(
                  decoration: InputDecoration(
                      icon: Icon(Icons.person),
                      hintText: '相手の名前',
                      labelText: '名前'),
                  validator: (str) {
                    if (str == null || str.isEmpty) {
                      return 'required';
                    }
                  },
                  onSaved: (s) {
                    context.read<_InputFormData>().user = s ?? '';
                  },
                  initialValue: context.read<_InputFormData>().user,
                ),
                TextFormField(
                  decoration: InputDecoration(
                      icon: Icon(Icons.business_center),
                      hintText: '貸し借りした物',
                      labelText: 'ローン'),
                  validator: (str) {
                    if (str == null || str.isEmpty) {
                      return 'required';
                    }
                  },
                  onSaved: (s) {
                    context.read<_InputFormData>().stuff = s ?? '';
                  },
                  initialValue: context.read<_InputFormData>().stuff,
                ),
                Text('締切日 ${context.read<_InputFormData>().date}'),
                ElevatedButton(
                  onPressed: () {
                    _selectDate(context);
                  },
                  child: Text('締切日変更'),
                )
              ],
            ),
          ),
        )));
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime(2023));
    if (pickedDate != null) {
      context.read<_InputFormData>().date = pickedDate;
    }
  }
}
