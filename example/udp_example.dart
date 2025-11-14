import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jsonrpc/jsonrpc.dart';

RpcServer server = RpcServer();
const int SERVER_PORT = 20000;

void prepareServerActions() {
  // register actions on server side.
  // if context parameter is true,
  //    if method is positioned, the first argument is 'RpcContext context'
  //    if method is named. an argument named 'RpcContext context' is placed.
  server.addAction(RpcAction("echoName", echoName, context: false, expand: true));
  server.addAction(RpcAction("echoIndex", echoIndex, context: false, expand: true));

  // expand is ignored when no result (null) received
  server.addAction(RpcAction("echoVoid", echoVoid, context: false));
  server.addAction(RpcAction("echoContext", echoContext, context: true, expand: false));
  server.addAction(RpcAction("echoContextParams", echoContextParams, context: true, expand: false));
  // ONLY expand parameter named 'name' OR 'age'
  server.addAction(RpcAction("echoNameWithContext", echoNameWithContext, context: true, expand: true, names: {"name", "age"}));
}

Future<RawDatagramSocket> startServer([int port = SERVER_PORT]) async {
  RawDatagramSocket serverSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, port);
  serverSocket.listen((RawSocketEvent e) {
    switch (e) {
      case RawSocketEvent.closed:
      case RawSocketEvent.readClosed:
      case RawSocketEvent.write:
        return;
      case RawSocketEvent.read:
        Datagram? d = serverSocket.receive();
        if (d != null) {
          String? response = server.onRecvText(utf8.decode(d.data));
          if (response != null) {
            serverSocket.send(utf8.encode(response), d.address, d.port);
          }
        }
    }
  });
  return serverSocket;
}

RpcClient client = RpcClient();

Future<RawDatagramSocket> startClient() async {
  RawDatagramSocket clientSocket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  clientSocket.listen((RawSocketEvent e) {
    switch (e) {
      case RawSocketEvent.closed:
      case RawSocketEvent.readClosed:
      case RawSocketEvent.write:
        return;
      case RawSocketEvent.read:
        Datagram? d = clientSocket.receive();
        if (d != null) {
          client.onRecvText(utf8.decode(d.data));
        }
    }
  });
  return clientSocket;
}

Future<void> clientInvokes(RpcTextSender sender) async {
  // named arguments
  Object? result = await client.request(sender, "echoName", map: {"name": "entao", "age": 33}, timeoutSeconds: 1);
  logRpc.d("Result echoName: ", result);
  // 2025-11-14 09:14:02.815 D RPC: Result echoName:  echoName: entao, 33

  // positioned arguments
  Object? resultIndex = await client.request(sender, "echoIndex", list: ["tom", 99], timeoutSeconds: 1);
  logRpc.d("Result echoIndex: ", resultIndex);
  // 2025-11-14 09:14:02.818 D RPC: Result echoIndex:  echoIndex: tom, 99

  // no arguments
  Object? resultEchoVoid = await client.request(sender, "echoVoid", timeoutSeconds: 1);
  logRpc.d("Result echoVoid: ", resultEchoVoid);
  // 2025-11-14 09:14:02.818 D RPC: Result echoVoid:  echoVoid: void

  // with RpcContext argument
  Object? resultEchoContext = await client.request(sender, "echoContext", list: [1, 2, 3], timeoutSeconds: 1);
  logRpc.d("Result echoContext: ", resultEchoContext);
  // 2025-11-14 09:14:02.818 D RPC: Result echoContext:  echoContext: [1, 2, 3]

  // with RpcContext argument and raw parameters result
  Object? resultEchoContextParams = await client.request(sender, "echoContextParams", map: {"a": 1, "b": 2}, timeoutSeconds: 1);
  logRpc.d("Result echoContextParams: ", resultEchoContextParams);
  // 2025-11-14 09:14:02.819 D RPC: Result echoContextParams:  echoContextParams: {a: 1, b: 2}

  // with RpcContext argument and raw parameters result
  Object? resultEchoNameWithContext = await client.request(sender, "echoNameWithContext", map: {"name": "Jerry", "age": 3, "addr": "USA"}, timeoutSeconds: 1);
  logRpc.d("Result echoNameWithContext: ", resultEchoNameWithContext);
  // 2025-11-14 09:14:02.820 D RPC: Result echoNameWithContext:  echoNameWithContext: Jerry, 3
}

void main() async {
  prepareServerActions();
  RawDatagramSocket serverSocket = await startServer(SERVER_PORT);

  RawDatagramSocket clientSocket = await startClient();

  await clientInvokes((String text) {
    int n = clientSocket.send(utf8.encode(text), InternetAddress("127.0.0.1"), SERVER_PORT);
    return n > 0;
  });

  Future.delayed(Duration(seconds: 1));
  serverSocket.close();
  clientSocket.close();
  // logRpc.off();  // rpc log off
  // logRpc.on(level: LogLevel.error) // only errors will output
}

String echoIndex(String name, int age) {
  return "echoIndex: $name, $age";
}

String echoName({required String name, required int age}) {
  return "echoName: $name, $age";
}

String echoVoid() {
  return "echoVoid: void";
}

String echoContext(RpcContext context) {
  return "echoContext: ${context.request.params}";
}

String echoContextParams(RpcContext context, dynamic params) {
  return "echoContextParams: $params";
}

// 'RpcContext context' always position first, when RpcAction.context = true
String echoNameWithContext(RpcContext context, {required String name, required int age}) {
  return "echoNameWithContext: $name, $age";
}
