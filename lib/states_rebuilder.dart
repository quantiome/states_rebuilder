library states_rebuilder;

import 'package:flutter/widgets.dart';

///Your logics classes extend `StatesRebuilder` to create your own business logic BloC (alternatively called ViewModel or Model).
class StatesRebuilder {
  Map<dynamic, List<VoidCallback>> _innerMap =
      {}; //key holds the stateID and the value holds the state
  // String _defaultTag;

  /// Method to add states to the _innerMap
  addToInnerMap({dynamic tag, VoidCallback listener}) {
    _innerMap[tag] = _innerMap[tag] ?? [];
    _innerMap[tag].add(listener);
  }

  /// stateMap getter
  Map<dynamic, List<dynamic>> get innerMap => _innerMap;

  /// You call `rebuildState` inside any of your logic classes that extends `StatesRebuilder`.
  /// It offers you two alternatives to rebuild any of your widgets.
  ///
  ///  `setState` : an optional VoidCallback to execute inside the Flutter setState() method
  ///
  ///  `ids`: First alternative to rebuild a particular widget indirectly by giving its id
  ///
  ///  `states` : Second alternative to rebuild a particular widget directly by giving its State

  void rebuildStates([List<dynamic> states, List hashTag]) {
    print(states);
    print(hashTag);
    if (states == null && hashTag == null) {
      _innerMap.forEach((k, v) {
        v?.forEach((e) {
          if (e != null) e();
        });
      });
    } else {
      if (states != null) {
        for (final state in states) {
          if (state is _StateBuilderState ||
              state is _StateBuilderStateTickerMix) {
            state?._listener();
          } else {
            final ss = _innerMap[state];
            ss?.forEach((e) {
              if (e != null) e();
            });
          }
        }
      }
      if (hashTag != null) {
        _innerMap[hashTag[0]][1]();
      }
    }
  }
}

typedef _StateBuildertype = Widget Function(BuildContext context, List hashtag);

class StateBuilder extends StatefulWidget {
  /// You wrap any part of your widgets with `StateBuilder` Widget to make it available inside your logic classes and hence can rebuild it using `rebuildState` method
  ///
  ///  `stateID`: you define the ID of the state. This is the first alternative
  ///  `blocs`: You give a list of the logic classes (BloC) you want this ID will be available.
  ///
  ///  `builder` : You define your top most Widget
  ///
  ///  `initState` : for code to be executed in the initState of a StatefulWidget
  ///
  ///  `dispose`: for code to be executed in the dispose of a StatefulWidget
  ///
  ///  `didChangeDependencies`: for code to be executed in the didChangeDependencies of a StatefulWidget
  ///
  ///  `didUpdateWidget`: for code to be executed in the didUpdateWidget of a StatefulWidget
  ///
  /// `withTickerProvider`

  StateBuilder({
    Key key,
    this.stateID,
    this.tag,
    this.blocs,
    @required this.builder,
    this.initState,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.withTickerProvider = false,
  })  : assert(builder != null),
        // assert(stateID == null ||
        //     blocs != null), // blocs must not be null if the stateID is given
        super(key: key);

  ///The build strategy currently used update the state.
  ///StateBuilder widget can berebuilt from the logic class using
  ///the `rebuildState` method.
  ///
  ///The builder is provided with an [State] object.
  @required
  final _StateBuildertype builder;

  ///Called when this object is inserted into the tree.
  final void Function(State state) initState;

  ///Called when this object is removed from the tree permanently.
  final void Function(State state) dispose;

  ///Called when a dependency of this [State] object changes.
  final void Function(State state) didChangeDependencies;

  ///Called whenever the widget configuration changes.
  final void Function(StateBuilder oldWidget, State state) didUpdateWidget;

  ///Unique name of your widget. It is used to rebuild this widget
  ///from your logic classes.
  ///
  ///It can be String (for small projects) or enum member (enums are preferred for big projects).
  final dynamic stateID;
  final dynamic tag;

  ///List of your logic classes you want to rebuild this widget from.
  ///The logic class should extand  `StatesRebuilder`of the states_rebuilder package.
  final List<StatesRebuilder> blocs;

  ///set to true if you want your state class to mix with `TickerProviderStateMixin`
  ///Default value is false.
  final bool withTickerProvider;

  createState() {
    if (withTickerProvider) {
      assert(() {
        if (initState == null || dispose == null) {
          throw FlutterError('`initState` `dispose` must not be null\n'
              'You are using `TickerProviderStateMixin` so you have to instantiate \n'
              'your controllers in the initState() and dispose them in the dispose() method\n'
              'If you do not need to use any controller set `withTickerProvider` to false');
        }
        return true;
      }());
      return _StateBuilderStateTickerMix();
    } else {
      return _StateBuilderState();
    }
  }
}

class _StateBuilderState extends State<StateBuilder> {
  String _tag;
  List _hashtag = [];

  @override
  void initState() {
    super.initState();
    if (widget.stateID != null && widget.stateID != "") {
      if (widget.blocs != null) {
        widget.blocs.forEach(
          (b) {
            if (b == null) return;
            b.addToInnerMap(
              tag: widget.stateID,
              listener: _listener,
            );
          },
        );
      }
    }

    if (widget.blocs != null) {
      widget.blocs.forEach(
        (b) {
          if (b == null) return;
          _tag = (widget.tag != null && widget.tag != "")
              ? widget.tag
              : "#@dFaLt${b.hashCode}TaG30";
          _hashtag = [_tag, b._innerMap[_tag]?.length ?? 0];
          print(_hashtag);
          b.addToInnerMap(
            tag: _tag,
            listener: _listener,
          );
        },
      );
    }

    if (widget.initState != null) widget.initState(this);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.stateID != null && widget.stateID != "") {
      if (widget.blocs != null) {
        widget.blocs.forEach(
          (b) {
            if (b == null) return;
            if (b.innerMap[widget.stateID] == null) return;
            if (b.innerMap[widget.stateID][0] == null) return;
            if (b.innerMap[widget.stateID][0]["hashCode"] == this.hashCode) {
              b.innerMap.remove(widget.stateID);
            }
          },
        );
      }
    }
    if (widget.blocs != null) {
      widget.blocs.forEach(
        (b) {
          if (b == null) return;
          if (_tag == null) return;
          final entry = b.innerMap[_tag];
          if (entry == null) return;
          for (var e in entry) {
            if (e == _listener) {
              entry.remove(e);
              break;
            }
          }
          if (entry.isEmpty) {
            b.innerMap.remove(_tag);
          }
          print('$_tag = ${entry?.length}');
        },
      );
    }

    if (widget.dispose != null) widget.dispose(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null)
      widget.didChangeDependencies(this);
  }

  @override
  void didUpdateWidget(StateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.didUpdateWidget != null) widget.didUpdateWidget(oldWidget, this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _hashtag);
  }
}

class _StateBuilderStateTickerMix extends State<StateBuilder>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    if (widget.stateID != null && widget.stateID != "") {
      if (widget.blocs != null) {
        widget.blocs.forEach(
          (b) {
            if (b == null) return;
            b.addToInnerMap(
              tag: widget.stateID,
              listener: _listener,
            );
          },
        );
      }
    }

    widget.initState(this);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (widget.stateID != null && widget.stateID != "") {
      if (widget.blocs != null) {
        widget.blocs.forEach(
          (b) {
            if (b == null) return;
            if (b.innerMap[widget.stateID] == null) return;
            if (b.innerMap[widget.stateID][0] == null) return;
            if (b.innerMap[widget.stateID][0]["hashCode"] == this.hashCode) {
              b.innerMap.remove(widget.stateID);
            }
          },
        );
      }
    }

    widget.dispose(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.didChangeDependencies != null)
      widget.didChangeDependencies(this);
  }

  @override
  void didUpdateWidget(StateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.didUpdateWidget != null) widget.didUpdateWidget(oldWidget, this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, null);
  }
}

class _BlocProvider<T> extends InheritedWidget {
  final bloc;
  _BlocProvider({Key key, @required this.bloc, @required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_) => false;
}

class BlocProvider<T> extends StatefulWidget {
  final Widget child;
  final T bloc;
  BlocProvider({@required this.child, @required this.bloc});

  static T of<T>(BuildContext context) {
    final type = _typeOf<_BlocProvider<T>>();

    _BlocProvider<T> provider = context.inheritFromWidgetOfExactType(type);
    return provider?.bloc;
  }

  static Type _typeOf<T>() => T;

  @override
  _BlocProviderState createState() => _BlocProviderState<T>();
}

class _BlocProviderState<T> extends State<BlocProvider> {
  _BlocProvider<T> _blocProvider;
  @override
  void initState() {
    super.initState();
    _blocProvider = _BlocProvider<T>(
      bloc: widget.bloc,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _blocProvider;
  }
}
