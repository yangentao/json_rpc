part of 'rpc.dart';

class RpcService implements TextReceiver {
  RpcClient client = RpcClient();
  RpcServer server = RpcServer();

  @override
  String? onRecvText(String text) {
    dynamic pk = Rpc.detectText(text);
    switch (pk) {
      case RpcRequest request:
        return server.onRequest(request)?.jsonText;
      case RpcResponse response:
        client.onResponse(response);
        return null;
      case List<RpcPacket> ls:
        List<RpcMap> jList = [];
        for (RpcPacket p in ls) {
          if (p is RpcRequest) {
            var r = server.onRequest(p);
            if (r != null) {
              jList.add(r.toJson());
            }
          } else if (p is RpcResponse) {
            client.onResponse(p);
          }
        }
        if (jList.isNotEmpty) {
          return json.encode(jList);
        }
    }
    return null;
  }

  Future<Object?> request(RpcTextSender textSender, String method, {RpcMap? args}) {
    return client.request(textSender, method, map: args);
  }

  Future<bool> notify(RpcTextSender textSender, String method, {RpcMap? args}) {
    return RpcClient.notify(textSender, method, map: args);
  }

  void addAll(List<RpcAction> actions) {
    for (var e in actions) {
      addAction(e);
    }
  }

  void addGroup(String group, String method, Function action, {bool context = false, bool expand = true}) {
    server.addGroup(group, method, action, context: context, expand: expand);
  }

  void add(String method, Function action, {bool context = false, bool expand = true}) {
    server.add(method, action, context: context, expand: expand);
  }

  void addAction(RpcAction action) {
    server.addAction(action);
  }

  void before(RpcInterceptor interceptor) {
    server.before(interceptor);
  }

  void after(RpcInterceptor interceptor) {
    server.after(interceptor);
  }
}
