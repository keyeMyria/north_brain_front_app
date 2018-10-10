import 'dart:async';
import 'dart:collection';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:north_brain_front_app/shared/constants/general/GeneralConstants.dart';
import 'package:north_brain_front_app/shared/services/general/CacheService.dart';
import 'package:north_brain_front_app/shared/services/general/TokenService.dart';
import 'package:uuid/uuid.dart';

/// 类名：通用工具类
/// 用途：常用的工具、静态方法的集合
class CommonService {

  //方法：提示信息，通过android、ios的toast实现。
  static hint(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: GeneralConstants.CONSTANT_COMMON_HINT_TIME
    );
  }

  /// 方法：设置HTTP头
  static setHeaders(String path) async {
    Map<String, String> headers = new HashMap();

    if (path.indexOf(GeneralConstants.CONSTANT_COMMON_ROUTE_PATH_STORAGE) == -1) {
      headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_CONTENT_TYPE] =
          GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_CONTENT_TYPE_VALUE;
    }

    headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_ACCEPT] =
        GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_ACCEPT_VALUE;

    headers[GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_API_KEY] =
        GeneralConstants.CONSTANT_COMMON_HTTP_HEADER_API_KEY_VALUE;

    var token = await TokenService.getToken();

    if (token != null && token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_TOKEN] != null) {
      headers[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_TOKEN] =
          token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_TOKEN];
    }

    return headers;
  }

  //方法：根据token中保存的公共信息，形成params对象
  static setParams(Map<String, String> params) async {
    Map<String, String> parameters = new HashMap();

    parameters.addAll(params);

    String serialNo = await getSerialNo();

    if (serialNo != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SERIAL_NO] = serialNo;
    }

    parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_APP_TYPE] =
        GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_APP_TYPE_VALUE;

    parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_CATEGORY] =
        GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_CATEGORY_VALUE;

    var token = await TokenService.getToken();

    if (token != null && token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SESSION] != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SESSION] =
          token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_SESSION];
    }

    if (token != null && token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_USER] != null) {
      parameters[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_USER] =
          token[GeneralConstants.CONSTANT_COMMON_HTTP_PARAM_PUBLIC_USER];
    }

    return parameters;
  }

  //方法：获取当前业务流水号
  static Future<String> getSerialNo() async {
    var serialNo = await CacheService.get(GeneralConstants.CONSTANT_COMMON_CACHE_SERIAL_NO);

    return serialNo;
  }


  //方法：新生成一条业务流水号，并存储在cache中
  static Future<String> setSerialNo() async {
    var uuid = new Uuid();

    String serialNo = uuid.v4();

    await CacheService.save(GeneralConstants.CONSTANT_COMMON_CACHE_SERIAL_NO, serialNo);

    return serialNo;
  }

  static dynamic encrypt(String content, bool isTemporary) {

  }


}