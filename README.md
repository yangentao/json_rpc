## JSON RPC 2.0 for dart language
ONLY JSON RPC 2.0 protocol implemented. NO transport dependency. 
 
## Server Side
* Register method use server.addAction().
* When server transport receive a text packet, call server.onRecvText(). 
* errorRpc() will raise an exception with 'RpcError', this will response to client.
* RpcAction.context, indicate whether a method need RpcContext parameter.
* RpcAction.expand, indicate whether expand all parameters when invoke a method.


## Client Side
* RpcClient.request() invoke server method which has a response
* RpcClient.notify() invoke server method which has NO response
* RpcClient.remote() with a transport callback, invoke server method which has a response immediately.  
  it can be used on http request or blocked tcp connection.
* When client transport receive a text packet, call client.onRecvText().

## Usage
* Server define methods, and register them.
```dart 
String echoIndex(String name, int age) {
  return "echoIndex: $name, $age";
}

String echoName({required String name, required int age}) {
  return "echoName: $name, $age";
}

RpcServer server = RpcServer();
server.addAction(RpcAction("echoName", echoName));
server.addAction(RpcAction("echoIndex", echoIndex));
// when transport receive text packet, give it to rpc server
server.onRecvText(jsonPacket);
```
* Client invoke remote method over any transport.
```dart 
RpcClient client = RpcClient();
// 'sender' is transport, it's like this:  FutureOr<bool> Function(String text)
// it can implements by TCP/UDP/WebSocket/Http etc.
Object? result = await client.request(sender, "echoName", map: {"name": "entao", "age": 33} );
Object? resultIndex = await client.request(sender, "echoIndex", list: ["tom", 99] );
// transport over HTTP or blocked tcp like this:
Object? result = await RpcClient.remote("echoName", map: {"name": "entao", "age": 33}, transport: (jsonText){
  String s = http.post(uri: '...', body: jsonText);
  return s;
});

```



## Example
Full code at 'example/udp_example.dart'  

* Server define methods
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:entao_jsonrpc/entao_jsonrpc.dart';

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

```

* Server prepare UDP socket.

```dart 
RpcServer server = RpcServer();
const int SERVER_PORT = 20000;

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
```

* Server register methods
```dart 
void prepareServerActions() {
  // register actions on server side.
  // if context parameter is true, the first argument is 'RpcContext context'
  server.addAction(RpcAction("echoName", echoName, context: false, expand: true));
  // default, context=false, expand=true
  server.addAction(RpcAction("echoIndex", echoIndex));

  // expand is ignored when no result (null) received
  server.addAction(RpcAction("echoVoid", echoVoid, context: false));
  server.addAction(RpcAction("echoContext", echoContext, context: true, expand: false));
  server.addAction(RpcAction("echoContextParams", echoContextParams, context: true, expand: false));
  // ONLY expand parameter named 'name' OR 'age'
  server.addAction(RpcAction("echoNameWithContext", echoNameWithContext, context: true, expand: true, names: {"name", "age"}));
} 
```

* Client prepare UDP socket
```dart  
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
```

* Client Invoke Remote Methods.

```dart  

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

```
 

* The Main function
```dart  
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
} 
```

* Log on/off
```dart  
logRpc.off();  // rpc log off
logRpc.on(level: LogLevel.error) // only errors will output 
```
