part of 'injected_animation.dart';

class OnAnimation {
  final Widget Function(Animate animate) _anim;
  OnAnimation(this._anim);
  late InjectedAnimationImp _injected;
  bool _isInitialized = false;
  bool _isDirty = false;
  bool? _isChanged;
  bool _hasChanged = false;
  bool _isSchedulerBinding = false;
  final _assertionList = [];

  ///Listen to the [InjectedAnimation]
  Widget listenTo(
    InjectedAnimation inj, {
    void Function()? onInitialized,
    Key? key,
  }) {
    _injected = inj as InjectedAnimationImp;

    return StateBuilderBaseWithTicker<_OnAnimationWidget>(
      (widget, setState, ticker) {
        late VoidCallback disposer;

        final _evaluateAnimation = <String, EvaluateAnimation>{};
        late final Animate animate;

        void triggerAnimation() {
          if (_isDirty && _isChanged == true) {
            _isChanged = false;
            _injected.triggerAnimation();
          }
        }

        T? _animateTween<T>(
          dynamic Function(T? begin, bool isInitialized) fn,
          T? targetValue,
          Curve? curve,
          Curve? reverseCurve,
          String name,
          bool isTween,
        ) {
          assert(() {
            if (_isInitialized && !_isDirty) return true;
            if (_assertionList.contains(name)) {
              _assertionList.clear();
              throw ArgumentError('Duplication of <$T> with the same name is '
                  'not allowed. Use distinct name');
            }
            _assertionList.add(name);
            return true;
          }());
          EvaluateAnimation? evaluateAnimation = _evaluateAnimation[name];
          T? value;
          if (evaluateAnimation == null) {
            _evaluateAnimation[name] = evaluateAnimation = EvaluateAnimation(
              onAnimation: this,
              curve: curve,
              reverseCurve: reverseCurve,
            );
          }
          value = evaluateAnimation.animate<T>(
            fn,
            targetValue,
            curve,
            reverseCurve,
            name,
          );
          if (!_injected.isAnimating) {
            triggerAnimation();
          }
          return value;
        }

        T? animateTween<T>(
          dynamic Function(T? begin) fn,
          Curve? curve,
          Curve? reserveCurve, [
          String name = '',
        ]) {
          name = 'Tween<$T>' + name + '_TwEeN_';

          // if (!isInit && _evaluateAnimation.containsKey(name)) {
          //   return getValue(name);
          // }
          return _animateTween(
            (begin, _) => fn(begin),
            null,
            curve,
            reserveCurve,
            name,
            true,
          );
        }

        T? animateValue<T>(
          T? value,
          Curve? curve,
          Curve? reserveCurve, [
          String name = '',
        ]) {
          name = '$T' + name;

          return _animateTween<T>(
            (begin, isInitialized) => _getTween(
              isInitialized ? begin : begin ?? value,
              value,
            ),
            value,
            curve,
            reserveCurve,
            name,
            false,
          );
        }

        void _didUpdateWidget() {
          _isDirty = true;
          _evaluateAnimation.forEach((key, value) {
            value._isDirty = true;
          });
          _injected.didUpdateWidget();
        }

        final disposeDidUpdateWidget = _injected.addToDidUpdateWidgetListeners(
          () {
            _hasChanged = true;
            _didUpdateWidget();
          },
        );
        final disposeAnimationReset = _injected.addToResetAnimationListeners(
          () {
            _evaluateAnimation.forEach((key, value) {
              value.backwardAnimation = null;
              value.backwardAnimation = null;
            });
          },
        );

        return LifeCycleHooks(
          mountedState: (_) {
            if (ticker != null) {
              _injected.initialize(ticker);
            }
            onInitialized?.call();
            animate = Animate._(
              value: animateValue,
              fromTween: animateTween,
            );
            disposer = _injected.reactiveModelState.listeners
                .addListenerForRebuild((_) {
              if (_hasChanged || animate.shouldAlwaysRebuild) {
                try {
                  setState();
                } catch (e) {
                  print(e);
                }
              }
            });
          },
          dispose: (_) {
            if (ticker != null) {
              _injected.dispose();
            }
            disposer();
            disposeDidUpdateWidget();
            disposeAnimationReset();
          },
          didUpdateWidget: (_, __, ___) {
            _didUpdateWidget();
          },
          builder: (_, widget) {
            return widget.animate(animate);
          },
        );
      },
      widget: _OnAnimationWidget(_anim),
      injected: _injected,
      key: key,
    );
  }
}

class _OnAnimationWidget {
  final Widget Function(Animate animate) animate;
  _OnAnimationWidget(this.animate);
}

class Animate {
  final T? Function<T>(
    T? value,
    Curve? curve,
    Curve? reserveCurve, [
    String name,
  ]) _value;
  Curve? _curve;
  Curve? _reserveCurve;

  bool shouldAlwaysRebuild = false;
  Animate setCurve(Curve curve) {
    _curve = curve;
    return this;
  }

  Animate setReverseCurve(Curve curve) {
    _reserveCurve = curve;
    return this;
  }

  final T? Function<T>(
    Tween<T?> Function(T? currentValue) fn,
    Curve? curve,
    Curve? reserveCurve, [
    String name,
  ]) _fromTween;

  Animate._({
    required T? Function<T>(
      T? value,
      Curve? curve,
      Curve? reserveCurve, [
      String name,
    ])
        value,
    required T? Function<T>(
      Tween<T?> Function(T? currentValue) fn,
      Curve? curve,
      Curve? reserveCurve, [
      String name,
    ])
        fromTween,
  })  : _value = value,
        _fromTween = fromTween;

  ///Implicitly animate to the given value
  T? call<T>(T? value, [String name = '']) {
    final curve = _curve;
    final reserveCurve = _reserveCurve;
    _curve = null;
    _reserveCurve = null;
    return _value.call<T>(value, curve, reserveCurve, name);
  }

  ///Set animation explicitly by defining the Tween.
  ///
  ///The callback exposes the currentValue value
  T? fromTween<T>(Tween<T?> Function(T? currentValue) fn, [String? name]) {
    final curve = _curve;
    final reserveCurve = _reserveCurve;
    _curve = null;
    _reserveCurve = null;
    return _fromTween(fn, curve, reserveCurve, name ?? '');
  }
}

class EvaluateAnimation {
  final OnAnimation onAnimation;
  final InjectedAnimationImp injected;
  dynamic tween;
  final Curve? curve;
  final Curve? reverseCurve;

  EvaluateAnimation({
    required this.onAnimation,
    required this.curve,
    required this.reverseCurve,
  }) : injected = onAnimation._injected;

  bool _isDirty = true;
  bool _isInitialized = false;

  dynamic currentValue;
  T? animate<T>(
    dynamic Function(T? begin, bool isInitialized) fn,
    T? targetValue,
    Curve? curve,
    Curve? reserveCurve,
    String name,
    // bool isTween,
  ) {
    if (!_isDirty) {
      return currentValue = getValue(name);
    }
    _isDirty = false;
    if (!onAnimation._isSchedulerBinding) {
      onAnimation._isSchedulerBinding = true;
      SchedulerBinding.instance!.addPostFrameCallback(
        (_) {
          onAnimation
            .._isSchedulerBinding = false
            .._assertionList.clear()
            .._isInitialized = true
            .._isDirty = false;
        },
      );
    }

    if (tween != null && tween.end == targetValue) {
      onAnimation._hasChanged = true;
      return currentValue = getValue(name);
    }
    // _hasChanged = isTween;

    var newTween = fn(currentValue, _isInitialized);
    if (newTween == null) {
      _isInitialized = true;
      return null;
    }
    if (!_isInitialized) {
      _isInitialized = true;
      tween = newTween;
      currentValue = getValue(name);
      onAnimation._hasChanged = true;
    } else if (tween?.begin != newTween.begin || tween?.end != newTween.end) {
      tween = newTween;
      if (tween.begin == tween.end) {
        return tween.begin;
      }
      forwardAnimation = null;
      backwardAnimation = null;
      onAnimation._isChanged = true;
      onAnimation._hasChanged = true;
    } else {
      currentValue = getValue(name);
    }

    //At this point controller.value == 0 or 1
    // assert(controller!.value == 0.0 || controller!.value == 1.0);
    return currentValue ??
        tween.lerp(
          injected.initialValue ?? injected.lowerBound,
        );
  }

  T? getValue<T>(String name) {
    try {
      if (tween == null) return null;
      final val = _evaluate();
      return val;
    } catch (e) {
      if (e is TypeError) {
        //For tween that accept null value but when evaluated throw a Null
        //is not subtype of T (where T is the type). [Tween.transform]
        return null;
      }
      rethrow;
    }
  }

  Animatable<dynamic>? forwardAnimation;
  Animatable<dynamic>? backwardAnimation;
  dynamic _evaluate() {
    if (injected.shouldResetCurvedAnimation) {
      injected.shouldResetCurvedAnimation = false;
      forwardAnimation = null;
      backwardAnimation = null;
    }
    if (injected.reverseCurve == null && reverseCurve == null) {
      forwardAnimation ??= tween.chain(
        CurveTween(curve: curve ?? injected.curve),
      );
      return forwardAnimation!.evaluate(injected.controller!);
    }
    if (injected.controller!.status == AnimationStatus.reverse) {
      backwardAnimation ??= tween.chain(
        CurveTween(curve: reverseCurve ?? injected.reverseCurve!),
      );
      return backwardAnimation!.evaluate(injected.controller!);
    }
    forwardAnimation ??= tween.chain(
      CurveTween(curve: curve ?? injected.curve),
    );
    return forwardAnimation!.evaluate(injected.controller!);
  }
}
