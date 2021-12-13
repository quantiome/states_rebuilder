import 'package:flutter/material.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

void main() {
  runApp(const MyApp());
}

final navigator = RM.injectNavigator(
  // CASE1: in WEB
  //    In web try enter '/user-info'. If the user is signed you will navigate
  //    to the '/user-info'. If the user is not signed, he will redirected to
  //    tge sign in page and after signing he will be navigated to the '/user-info'
  // CASE2: In Other platform try uncomment the below line to see similar effect.
  // initialLocation: '/user-info',
  routes: {
    '/': (data) => const HomePage(),
    '/sign-in': (data) => const SignInScreen(),
    '/user-info': (data) => const UserInfo(),
  },
  onNavigate: (data) {
    final location = data.location;
    if (!authBloc.isSignedIn && location != '/sign-in') {
      // User is not signed and tries to enter the app without signing in
      //
      // Redirect the user to the sign in page
      return data.redirectTo('/sign-in');
    }
    if (authBloc.isSignedIn && location == '/sign-in') {
      // User is signed and tries to enter the sign in page
      //
      // Redirect the user to the home page
      return data.redirectTo('/');
    }
  },
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Books App',
      routeInformationParser: navigator.routeInformationParser,
      routerDelegate: navigator.routerDelegate,
    );
  }
}

// Simple data class for the user
class User {
  User(this.username, this.password);
  final String username;
  final String password;
}

@immutable
// The business logic for signing in and out
class AuthBloc {
  final _user = RM.inject<User?>(
    () => null,
    sideEffects: SideEffects.onData((user) {
      if (user != null) {
        final toLocation = navigator.routeData.redirectedFrom?.location;
        if (toLocation != null) {
          navigator.toAndRemoveUntil(toLocation);
        }
      }
      navigator.onNavigate();
    }),
  );

  bool get isSignedIn => _user.state != null;
  User? get user => _user.state;

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _user.state = null;
  }

  Future<void> signIn(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _user.state = User(username, password);
  }
}

final authBloc = AuthBloc();

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    Key? key,
  }) : super(key: key);

  static final _form = RM.injectForm(
    submit: () => authBloc.signIn(
      _username.text,
      _password.text,
    ),
  );
  static final _username = RM.injectTextEditing(
    validators: [(value) => value!.isEmpty ? 'Required' : null],
  );
  static final _password = RM.injectTextEditing(
    validators: [(value) => value!.isEmpty ? 'Required' : null],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Card(
            child: Container(
              constraints: BoxConstraints.loose(const Size(600, 600)),
              padding: const EdgeInsets.all(8),
              child: OnFormBuilder(
                listenTo: _form,
                builder: () {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sign in',
                          style: Theme.of(context).textTheme.headline4),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Username',
                          errorText: _username.error,
                        ),
                        controller: _username.controller,
                        focusNode: _username.focusNode,
                      ),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: _password.error,
                        ),
                        obscureText: true,
                        controller: _password.controller,
                        focusNode: _password.focusNode,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: _form.submit,
                          child: const Text('Sign in'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to User information'),
          onPressed: () => navigator.to('/user-info'),
        ),
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UserName: ${authBloc.user!.username}'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Sign out'),
          onPressed: () => authBloc.signOut(),
        ),
      ),
    );
  }
}