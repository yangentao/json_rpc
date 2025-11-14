part of 'rpc.dart';

class RpcError {
  final int code;
  final String message;
  final Object? data;

  RpcError(this.code, this.message, [this.data]);

  RpcError.server(this.code, this.message, [this.data]) {
    assert(code >= 32000 && code <= 32099);
  }

  RpcError.from(RpcMap map)
      : code = map[Rpc.CODE],
        message = map[Rpc.MESSAGE],
        data = map[Rpc.DATA];

  @override
  String toString() {
    return "RpcError(code:$code, message:$message, data: $data)";
  }

  RpcMap toMap() {
    RpcMap m = RpcMap();
    m[Rpc.CODE] = code;
    m[Rpc.MESSAGE] = message;
    if (data != null) m[Rpc.DATA] = data.toString();
    return m;
  }

  RpcError withData(Object data) {
    return RpcError(code, message, data);
  }

  static RpcError parse = RpcError(32700, "Parse Error");
  static RpcError invalidRequest = RpcError(32600, "Invalid Request");
  static RpcError methodNotFound = RpcError(32601, "Method NOT Found");
  static RpcError invalidParams = RpcError(32602, "Invalid Params");
  static RpcError internal = RpcError(32603, "Internal Error");
}

Never errorRpc(String message, {int code = -1, Object? data}) {
  throw RpcError(code, message, data);
}
