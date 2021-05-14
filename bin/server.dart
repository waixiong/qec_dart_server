import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart' as shelf;
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_static/shelf_static.dart' as shelf_static;
// import 'package:shelf_router/shelf_router.dart' as shelf_router;

// import 'package:image/image.dart';
// import 'dart:math' as Math;


// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = '0.0.0.0';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var staticFiles = VirtualDirectory('../static')
      ..allowDirectoryListing = false 
      ..followLinks = true;

  // var staticHandler = shelf_static.createStaticHandler('../static/nightsky', defaultDocument:'index.html', serveFilesOutsidePath: true, listDirectories: true );

  // final router = shelf_router.Router()
  //   // ..get('/item/<itemid>', (shelf.Request request, String itemid) {});
  //   //..add('GET', '/', staticHandler)
  //   // ..get('/nightsky/<resource>', _getFile );
  //   ..add('GET', '/nightsky/<resource>', _getFile );
  //   // ..add('GET', '/nightsky/index.html', _getFile )
  //   // ..add('GET', '/nightsky/main.dart.js', _getFile )
  //   // ..add('GET', '/nightsky/main.dart.js.map', _getFile )
  //   // ..add('GET', '/nightsky/assets/FontManifest.json', _getFile )
  //   // ..add('GET', '/nightsky/assets/fonts/MaterialIcons-Regular.ttf', _getFile )
  //   // ..add('GET', '/nightsky/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf', _getFile )
  //   // ..add('GET', '/nightsky/assets/assets/StarSky.flr', _getFile );
  
  // var handler = const shelf.Pipeline()
  //     .addMiddleware(shelf.logRequests())
  //     .addHandler(router.handler);

  // var server = await io.serve(handler, _hostname, port);
  // SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
  // securityContext.useCertificateChain('../config/ssl/certificate.crt');
  // securityContext.usePrivateKey('../config/ssl/private.key');
  // var server = await HttpServer.bindSecure(_hostname, port, securityContext).catchError((e){
  //   print('[${DateTime.now()}] ERROR ${e.runtimeType} : ${e}');
  // });
  // Map<String, String> envVars = Platform.environment;

  var server = await HttpServer.bind(_hostname, port);
  
  server.listen((HttpRequest request) async {
    // request.response.headers.add('Access-Control-Allow-Origin', '*.getitqec.com');
    // request.response.headers.add('Access-Control-Allow-Origin', '*.angelmortal.xyz');
    // request.response.headers.add('Access-Control-Allow-Origin', '*');
    var pathString = request.uri.toString();
    print('PathUri: '+pathString);
    // List<String> pathArr = pathString.split('/');
    try {
      var realPath = pathString.substring(pathString.indexOf('/', 1));
      print('1: '+realPath);
      realPath = realPath.substring(realPath.indexOf('/', 1));
      print('Real: '+realPath);

      if(pathString.startsWith('/api', 0)) {
        print('[${DateTime.now()}] /api ${pathString}');
        // API
      } else {
        if(pathString[pathString.length-1]=='/') {
          print('[${DateTime.now()}] / ${pathString}');
          // default html
          var htmlFile = File('../static/${request.uri.path}index.html');
          // var exist = await File('../static/${request.uri.path}index.html').exists();
          if(await htmlFile.exists()) {
            staticFiles.serveFile(htmlFile, request);
          } else {
            await staticFiles.serveRequest(request);
          }
        } else {
          // check file or directory
          print('[${DateTime.now()}] request ${pathString}');
          var fType = await FileSystemEntity.type('../static/${request.uri.path}', );
          switch (fType) {
            // case FileSystemEntityType.file:
            //   await staticFiles.serveRequest(request);
            //   break;

            case FileSystemEntityType.directory:
              // File htmlFile = File('../static/${request.uri.path}/index.html');
              // if(await htmlFile.exists()) {
              //   staticFiles.serveFile(htmlFile, request);
              // } else {
              //   await staticFiles.serveRequest(request);
              // }
              await request.response.redirect(Uri.parse('$realPath/'),status: HttpStatus.movedPermanently);
              break;

            default:
              await staticFiles.serveRequest(request);
          }
        }
      }
    } catch(e) {
      print('Error $e');
      request.response.statusCode = HttpStatus.notFound;
    }
  }).onError((e){
    print('[${DateTime.now()}] ERROR ${e.runtimeType} : ${e}');
  });
  print('Serving at https://${server.address.host}:${server.port}');
}

shelf.Response _echoRequest(shelf.Request request) =>
    shelf.Response.ok('Request for "${request.url}"');

Future<shelf.Response> _getFile(shelf.Request request, String resource) async {
  print('R : $resource withL ${resource.length}');
  var path = request.url.toString();
  if(path[path.length-1]=='/') path += 'index.html';
  var file = File('../static/${path}');
  return shelf.Response.ok(await file.readAsBytes(), headers: {'Content-Type': lookupMimeType(file.path)});
}