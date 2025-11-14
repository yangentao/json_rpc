part of 'rpc.dart';

extension _ListCast<T> on List<T> {
  T? getOr(int index) => index >= this.length ? null : this[index];
}

extension _IterableExt<E> on Iterable<E> {
  List<T> mapList<T>(T Function(E e) block) {
    List<T> ls = [];
    for (var e in this) {
      ls.add(block(e));
    }
    return ls;
  }
}

extension _NullableIterableExt<T extends Object> on Iterable<T?> {
  List<T> get nonNullList => nonNulls.toList();
}

extension _LetBlock<T> on T {
  R let<R>(R Function(T) block) {
    return block(this);
  }

  T also(void Function(T) block) {
    block(this);
    return this;
  }
}

Never _error(String message) {
  throw Exception(message);
}
