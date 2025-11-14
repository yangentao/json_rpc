part of 'rpc.dart';

class RpcContext {
  final RpcRequest request;
  RpcResponse? response;
  final Map<String, dynamic> attrs = {};
  bool _commited = false;

  RpcContext(this.request);

  bool get commited => _commited;

  RpcResponse? success(Object? result) {
    if (commited) _error("Already commited");
    _commited = true;
    if (isNotify) return null;
    this.response = RpcResponse.success(id: request.id!, result: result);
    return this.response;
  }

  RpcResponse? failedError(RpcError e) {
    if (commited) _error("Already commited");
    _commited = true;
    if (isNotify) return null;
    this.response = RpcResponse.failed(id: request.id!, error: e);
    return this.response;
  }

  RpcResponse? failed(int code, String message, [Object? data]) {
    return failedError(RpcError(code, message, data));
  }

  String get method => request.method;

  bool get isNotify => !request.hasID;

  int get intID => request.intID;

  String get stringID => request.id as String;

  int get paramCount => request.paramCount;

  bool get hasParams => paramCount > 0;

  RpcMap? get paramMap => request.params is RpcMap ? request.params as RpcMap : null;

  RpcList? get paramList => request.params is RpcList ? request.params as RpcList : null;

  bool hasParam(String name) => true == paramMap?.containsKey(name);

  bool? getBool(String name) => paramMap?[name];

  int? getInt(String name) => paramMap?[name];

  double? getDouble(String name) => paramMap?[name];

  String? getString(String name) => paramMap?[name];

  bool? getBoolAt(int index) => paramList?.getOr(index);

  int? getIntAt(int index) => paramList?.getOr(index);

  double? getDoubleAt(int index) => paramList?.getOr(index);

  String? getStringAt(int index) => paramList?.getOr(index);

  T? getModel<T extends Object>(String name, T Function(RpcMap) mapper) {
    RpcMap? m = paramMap?[name] as RpcMap?;
    if (m == null) return null;
    return mapper(m);
  }

  T? getModelAt<T extends Object>(int index, T Function(RpcMap) mapper) {
    RpcMap? m = paramList?[index] as RpcMap?;
    if (m == null) return null;
    return mapper(m);
  }
}
