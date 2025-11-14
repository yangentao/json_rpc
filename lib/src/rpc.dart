import 'dart:async';
import 'dart:convert';

import 'package:entao_log/entao_log.dart';

part 'rpc_client.dart';
part 'rpc_context.dart';
part 'rpc_error.dart';
part 'rpc_request.dart';
part 'rpc_response.dart';
part 'rpc_server.dart';
part 'rpc_service.dart';
part 'rpc_utils.dart';

TagLog logRpc = TagLog("RPC");

typedef RpcMap = Map<String, dynamic>;
typedef RpcList = List<dynamic>;

class Rpc {
  static String JSONRPC = "jsonrpc";
  static String VERSION = "2.0";
  static String ID = "id";
  static String METHOD = "method";
  static String PARAMS = "params";
  static String RESULT = "result";
  static String ERROR = "error";
  static String CODE = "code";
  static String MESSAGE = "message";
  static String DATA = "data";

  static int _autoID = 1;

  static int get nextID => _autoID++;

  /// RpcPacket,   Or, List&ltRpcPacket&gt
  static dynamic detectText(String text) {
    var jv = json.decode(text);
    switch (jv) {
      case RpcMap map:
        return detectPacket(map);
      case List<dynamic> list:
        List<RpcPacket> ls = list
            .map((e) {
              if (e is RpcMap) {
                return detectPacket(e);
              } else {
                return null;
              }
            })
            .nonNulls
            .toList();
        if (ls.isNotEmpty) return ls;
    }
    return null;
  }

  static RpcPacket? detectPacket(RpcMap map) {
    if (!_verifyVersion(map)) return null;
    if (map.containsKey(Rpc.RESULT) || map.containsKey(Rpc.ERROR)) {
      return RpcResponse.from(map);
    }
    if (map.containsKey(Rpc.METHOD)) return RpcRequest.from(map);
    return null;
  }
}

bool _verifyVersion(RpcMap map) {
  return map[Rpc.JSONRPC] == Rpc.VERSION;
}

sealed class RpcPacket {
  RpcPacket();

  RpcMap toJson() {
    RpcMap map = RpcMap();
    map[Rpc.JSONRPC] = Rpc.VERSION;
    onJson(map);
    return map;
  }

  void onJson(RpcMap map) {}

  @override
  String toString() {
    RpcMap map = toJson();
    return json.encode(map );
  }
}

typedef RpcTextSender = FutureOr<bool> Function(String text);

abstract mixin class TextReceiver {
  /// 返回值表示要发给对方的数据. client总是返回null.
  String? onRecvText(String text);
}
