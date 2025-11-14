part of 'rpc.dart';

class RpcClient implements TextReceiver {
  final Map<int, _ClientInfo> _mapReq = {};

  int get runningCount => _mapReq.length;

  @override
  String? onRecvText(String text) {
    var jo = json.decode(text);
    switch (jo) {
      case RpcMap map:
        var a = Rpc.detectPacket(map);
        if (a is RpcResponse) {
          onResponse(a);
        }
      case RpcList list:
        for (var e in list) {
          if (e is RpcMap) {
            var a = Rpc.detectPacket(e);
            if (a is RpcResponse) {
              onResponse(a);
            }
          }
        }
    }
    return null;
  }

  void onResponse(RpcResponse response) {
    var info = _mapReq.remove(response.intID);
    if (info == null) {
      logd("Not Found Response: ", response.toString());
      return;
    }
    if (response.success) {
      info.completer.complete(response.result);
    } else {
      info.completer.completeError(response.error!);
    }
  }

  Future<Object?> request(RpcTextSender textSender, String method, {RpcMap? map, RpcList? list, int timeoutSeconds = 10}) async {
    int id = Rpc.nextID;
    var r = RpcRequest.invoke(method: method, map: map, list: list, id: id);
    FutureOr<bool> sendResult = textSender(r.toString());
    if (sendResult is Future<bool>) {
      bool b = await sendResult;
      if (b != true) {
        return null;
      }
    } else {
      if (sendResult != true) {
        return null;
      }
    }
    var info = _ClientInfo(r);
    _mapReq[id] = info;
    var fu = info.completer.future;
    return fu.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () async {
        _mapReq.remove(id);
        throw TimeoutException("Method [$method] is timeout.");
      },
    );
  }

  static Future<bool> notify(RpcTextSender textSender, String method, {RpcMap? map, RpcList? list}) async {
    var r = RpcRequest.notify(method: method, map: map, list: list);
    FutureOr<bool> fo = textSender(r.toString());
    if (fo is Future<bool>) return fo;
    return fo;
  }

  static Future<Object?> remote(String method, {RpcMap? map, RpcList? list, required Future<String?> Function(String) transport}) async {
    var req = RpcRequest.invoke(method: method, map: map, list: list, id: Rpc.nextID);
    String s = req.toString();
    logRpc.d("send: ", s);
    String? resp = await transport(s);
    logRpc.d("recv: ", resp);
    if (resp == null) return null;
    var jo = json.decode(resp);
    if (jo == null) return null;
    if (jo is RpcMap) {
      RpcResponse r = RpcResponse.from(jo);
      if (r.success) return r.result;
      throw r.error!;
    }
    throw RpcError.parse;
  }
}

class _ClientInfo {
  final RpcRequest request;
  final Completer<Object?> completer = Completer<Object?>();

  _ClientInfo(this.request);
}
