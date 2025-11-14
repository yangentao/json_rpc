part of 'rpc.dart';

final class RpcResponse extends RpcPacket {
  final Object? id;
  final Object? result;
  final RpcError? error;

  RpcResponse({required this.id, this.result, this.error}) : assert(result == null || error == null);

  RpcResponse.success({required Object this.id, required this.result}) : error = null;

  RpcResponse.failed({required this.id, required RpcError this.error}) : result = null;

  bool get success => error == null;

  bool get failed => error != null;

  int get intID => id as int;

  String get stringID => id as String;

  bool get resultBool => result as bool;

  int get resultInt => result as int;

  double get resultDouble => result as double;

  String get resultString => result as String;

  RpcList get resultList => result as RpcList;

  RpcMap get resultMap => result as RpcMap;

  String get jsonText => toString();

  @override
  void onJson(RpcMap map) {
    super.onJson(map);
    map[Rpc.ID] = id;
    if (success) {
      map[Rpc.RESULT] = result;
    } else {
      map[Rpc.ERROR] = error!.toMap();
    }
  }

  static RpcResponse from(RpcMap map) {
    if (!_verifyVersion(map)) throw RpcError.parse;
    Object id = map[Rpc.ID];
    RpcMap? error = map[Rpc.ERROR];
    if (error != null) {
      return RpcResponse.failed(id: id, error: RpcError.from(error));
    } else {
      dynamic result = map[Rpc.RESULT];
      return RpcResponse.success(id: id, result: result);
    }
  }

  static List<RpcResponse> fromBatch(RpcList list) {
    return list.mapList((e) => from(e));
  }
}
