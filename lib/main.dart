import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() =>runApp(ViewMaps());

class ViewMaps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Map<PermissionGroup, PermissionStatus> permissions;

  @override
  void initState() {
    super.initState();
    getPermission();
    llenar();
    ActualizarTCP();
  }

  Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = Set();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(10.410973, -75.513970),
    zoom: 15.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encontrar Estaciones de servicio'),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            markers: _markers,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ],
      ),
    );
  }

  void getPermission() async {
    permissions = await PermissionHandler().requestPermissions([
      PermissionGroup.location,
    ]);
  }

  void ActualizarTCP() async {
    Socket.connect("192.168.1.61", 1337).then((socket) {
      print('Connected to: '
          '${socket.remoteAddress.address}:${socket.remotePort}');

      //Establish the onData, and onDone callbacks
      socket.listen((data) {
        print(new String.fromCharCodes(data).trim());
        final marcador = json.decode(new String.fromCharCodes(data).trim());
        print(marcador['nombre']);
        addMarkers(marcador['nombre'], marcador['lat'], marcador['lng']);
      },
          onDone: () {
            print("Done");
            socket.destroy();
          });
    });
  }

  void ActualizarUDP() async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 1337).then((RawDatagramSocket socket){
      print('Datagram socket ready to receive');
      print('${socket.address.address}:${socket.port}');
      socket.send("up".codeUnits,new InternetAddress('192.168.1.61'), 1337);
      socket.listen((RawSocketEvent e){
        Datagram d = socket.receive();
        if (d == null) return;

        String message = new String.fromCharCodes(d.data).trim();
        final marcador = json.decode(message);
        print(marcador['nombre']);
        addMarkers(marcador['nombre'], marcador['lat'], marcador['lng']);
      });
    });
  }

  void llenar() async {
    print('pregunta...');
    final response = await http.get('http://192.168.1.61:3000/station');
    final list = json.decode(response.body);
    list.forEach((marcador) =>
    {
      print(marcador['nombre']),
      addMarkers(marcador['nombre'], marcador['lat'], marcador['lng'])
    });
  }

  void addMarkers(nombre, lat, lng) async {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(nombre),
          position: LatLng(lat, lng),
        ),
      );
    });
  }
}

