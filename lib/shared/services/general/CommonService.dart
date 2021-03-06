import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:north_brain_front_app/shared/constants/general/GeneralConstants.dart';
import 'package:north_brain_front_app/shared/models/general/Token.dart';
import 'package:north_brain_front_app/shared/services/general/CacheService.dart';
import 'package:north_brain_front_app/shared/services/general/TokenService.dart';
import 'package:uuid/uuid.dart';
import "package:pointycastle/pointycastle.dart";
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


/// 类名：通用工具类
/// 用途：常用的工具、静态方法的集合
class CommonService {

  //方法：提示信息，通过android、ios的toast实现。
  static hint(String msg) {
    if (msg == null || msg == '') {
      return;
    }

    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: GeneralConstants.CONSTANT_COMMON_HINT_TIME
    );
  }

  /// 方法：设置HTTP头
  static Future<Map<String, String>> setHeaders(String url) async {
    if (url == null || url == '') {
      return null;
    }

    Map<String, String> headers = new HashMap();

    if (url.indexOf(GeneralConstants.CONSTANT_COMMON_ROUTE_PATH_STORAGE) == -1) {
      headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_CONTENT_TYPE] =
          GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_CONTENT_TYPE_VALUE;
    }

    headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_ACCEPT] =
        GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_ACCEPT_VALUE;

    headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_API_KEY] =
        GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_API_KEY_VALUE;

    Token token = await TokenService.getToken();

    if (token != null && token.jwt != null) {
      headers[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_TOKEN] =
          token.jwt;
    }

    return headers;
  }

  //方法：根据token中保存的公共信息，形成params对象
  static Future<Map<String, String>> setParams(Map<String, dynamic> params) async {
    Map<String, String> parameters = new HashMap();

    if (params != null) {
      parameters.addAll(params);
    }

    String serialNo = await getSerialNo();

    if (serialNo != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SERIAL_NO] = serialNo;
    }

    parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_APP_TYPE] =
        GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_APP_TYPE_VALUE;

    parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_CATEGORY] =
        GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_CATEGORY_VALUE;

    var token = await TokenService.getToken();

    if (token != null && token.session != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SESSION] =
          token.session;
    }

    if (token != null && token.user != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_USER] =
          token.user;
    }

    return parameters;
  }

  //方法：获取当前业务流水号
  static Future<String> getSerialNo() async {
    String serialNo = await CacheService.get(GeneralConstants.CONSTANT_COMMON_CACHE_SERIAL_NO);

    Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_LOG_SERIAL_NO_PROMPT}${serialNo}');

    return serialNo;
  }


  //方法：新生成一条业务流水号，并存储在cache中
  static Future<String> setSerialNo() async {
    Uuid uuid = new Uuid();

    String serialNo = uuid.v4();

    bool isSaved = await CacheService.save(GeneralConstants.CONSTANT_COMMON_CACHE_SERIAL_NO,
        serialNo);

    if (isSaved) {
      Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_LOG_SERIAL_NO_PROMPT}${serialNo}');

      return serialNo;
    }

    return null;
  }

  //方法：将字符串转换成Uint8List格式
  static Uint8List transformStringToUint8List(String value) =>
      new Uint8List.fromList(utf8.encode(value));

  //方法：加密
  static Future<String> encrypt (String content, bool isTemporary) async {
    if (content == null || content == '') {
      return null;
    }

    RSAPublicKey rsaPublicKey;

    if (isTemporary) {
      rsaPublicKey = new RSAPublicKey(
          BigInt.parse(GeneralConstants.CONSTANT_COMMON_TEMPORARY_PUBLIC_KEY_MODULUS),
          BigInt.parse(GeneralConstants.CONSTANT_COMMON_PUBLIC_KEY_EXPONENT));
    } else {
      Token token = await TokenService.getToken();

      rsaPublicKey = new RSAPublicKey(
          BigInt.parse(token.downPublicKey),
          BigInt.parse(GeneralConstants.CONSTANT_COMMON_PUBLIC_KEY_EXPONENT));
    }

    PublicKeyParameter<RSAPublicKey> publicKeyParameter =
    new PublicKeyParameter<RSAPublicKey>(rsaPublicKey);

    AsymmetricBlockCipher asymmetricBlockCipher =
    new AsymmetricBlockCipher(GeneralConstants.CONSTANT_COMMON_SECURITY_ASYMMETRIC_ALGORITHM);

    asymmetricBlockCipher.reset();
    asymmetricBlockCipher.init(true, publicKeyParameter);

    Uint8List encryptedContent =
    asymmetricBlockCipher.process(transformStringToUint8List(content));

    String encryptedContentString = String.fromCharCodes(encryptedContent);

    Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_LOG_ENCRYPTED_DATA_PROMPT}${encryptedContentString}');

    return encryptedContentString;
  }

  //方法：解密
  static Future<String> decrypt(String content) async {
    if (content == null || content == '') {
      return null;
    }

    Token token = await TokenService.getToken();

    RSAPrivateKey rsaPrivateKey = new RSAPrivateKey(
        BigInt.parse(token.upPrivateKeyModulus),
        BigInt.parse(token.upPrivateKeyExponent),
        BigInt.parse(token.upPrivateKeyPrimeP),
        BigInt.parse(token.upPrivateKeyPrimeQ));

    PrivateKeyParameter<RSAPrivateKey> privateKeyParameter =
    new PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey);

    AsymmetricBlockCipher cipher
    = new AsymmetricBlockCipher(GeneralConstants.CONSTANT_COMMON_SECURITY_ASYMMETRIC_ALGORITHM);

    cipher.reset();
    cipher.init(true, privateKeyParameter);

    Uint8List decryptedContent =
    cipher.process(transformStringToUint8List(content));

    String decryptedContentString = String.fromCharCodes(decryptedContent);

    Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_LOG_DECRYPTED_DATA_PROMPT}${decryptedContentString}');

    return decryptedContentString;
  }

  //方法：http错误处理
  static handleError(error) {
    if (error == null || error.statusCode == null || error.type == null) {
      return;
    }

    switch (error.type) {
      case DioErrorType.DEFAULT:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_DEFAULT_ERROR);
        Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_HTTP_DEFAULT_ERROR}${error.message}');
        break;
      case DioErrorType.RESPONSE:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_RESPONSE_ERROR);
        Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_HTTP_RESPONSE_ERROR}${error.message}');
        break;
      case DioErrorType.CONNECT_TIMEOUT:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_CONNECT_TIMEOUT_ERROR);
        Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_HTTP_CONNECT_TIMEOUT_ERROR}${error.message}');
        break;
      case DioErrorType.RECEIVE_TIMEOUT:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_RECEIVE_TIMEOUT_ERROR);
        Logger.root.fine('${GeneralConstants.CONSTANT_COMMON_HTTP_RECEIVE_TIMEOUT_ERROR}${error.message}');
        break;
      default:
        break;
    }

    switch (error.statusCode) {
      case 200:
        break;
      case 401:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_DEFAULT_ERROR);
        break;
      case 505:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_DEFAULT_ERROR);
        break;
      default:
        CommonService.hint(GeneralConstants.CONSTANT_COMMON_HTTP_DEFAULT_ERROR);
        break;
    }
  }

  //方法：获取当前时间的值
  static DateTime currentDate() {
    return DateTime.now();
  }

  //方法：获取前一天时间的值
  static DateTime beforeDate() {
    DateTime now = new DateTime.now();

    return new DateTime(now.year, now.month, now.day - 1, now.hour, now.minute,
      now.second, now.millisecond, now.microsecond);
  }

  //方法：获取本地存储的路径
  static getLocalPath() async {
    Directory applicationDirectory;

    if (Platform.isIOS) {
      applicationDirectory = await getApplicationDocumentsDirectory();
    } else {
      applicationDirectory = await getExternalStorageDirectory();
    }

    PermissionStatus permissionStatus = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    if (permissionStatus != PermissionStatus.granted) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler().requestPermissions([PermissionGroup.storage]);

      if (permissions[PermissionGroup.storage] != PermissionStatus.granted) {
        return null;
      }
    }

    Directory applicationDocumentPath
    = Directory(applicationDirectory.path + GeneralConstants.CONSTANT_COMMON_APPLICATION_DIRECTORY_DOCUMENT);

    await applicationDocumentPath.create(recursive: true);

    return applicationDirectory;
  }

  //方法：通过路径获取文件名
  static getFileNameByPath(String path) {
    return path.substring(path.lastIndexOf(GeneralConstants.CONSTANT_COMMON_APPLICATION_DIRECTORY_SEPARATOR));
  }

  //方法：保存图像
  static saveImage(String url) async {

    Future<String> _findPath(String imageUrl) async {
      final CacheManager cacheManager = await CacheManager.getInstance();
      final file = await cacheManager.getFile(imageUrl);

      if (file == null) {
        return null;
      }

      Directory localPath = await CommonService.getLocalPath();

      if (localPath == null) {
        return null;
      }

      final String name = getFileNameByPath(file.path);
      final resultFile = await file.copy(localPath.path + name);

      return resultFile.path;
    }

    return _findPath(url);
  }

  //方法：拷贝
  static copy(String data, BuildContext context) {
    Clipboard.setData(new ClipboardData(text: data));

    CommonService.hint(GeneralConstants.CONSTANT_COMMON_COPY_SUCCESS_HINT);
  }
}