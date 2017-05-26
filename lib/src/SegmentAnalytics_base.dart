library analytics;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';


class Analytics {
  static Analytics _singleton;
  static String endpoint = "https://api.segment.io/v1";
  static String writeKey;
  static AnalyticsClient client = new AnalyticsClient(new Client());

  factory Analytics({String apiKey}) {
    if (_singleton == null) {
      _singleton = new Analytics._internal(apiKey);
      return _singleton;
    } else {
      return _singleton;
    }
  }

  Analytics._internal(String segmentApiKey) {
    writeKey = "Basic ${BASE64.encode(UTF8.encode("$segmentApiKey").toString().codeUnits)}";
  }

  void identify(String userID, Map properties) {
    Map payload = {"type": "identify", "traits": properties, "userId": userID, "context": defaultContext()};
    client.postSilentMicrotask("$endpoint/identify", body: JSON.encode(payload));
  }

  void identifyIP(String userID, String ip) {
    Map context = defaultContext();
    context["ip"] = ip;
    Map payload = {"type": "identify", "userId": userID, "context": context};
    client.postSilentMicrotask("$endpoint/identify", body: JSON.encode(payload));
  }

  trackRevenue(String userId, double value, String eventName) async {
    Map properties = {"revenue": value};
    track(userId, eventName, properties: properties);
  }


  void track(String userId, String event, {Map properties, Map context}) {
    if (properties == null) {
      properties = new Map();
    }

    if (context == null) {
      context = defaultContext();
    } else {
      context.addAll(defaultContext());
    }

    Map payload = {
      "userId": userId,
      "context": new Map.from(context),
      "event": event,
      "properties": new Map.from(properties)
    };
    client.postSilentMicrotask("$endpoint/track", body: JSON.encode(payload));
  }

  Map defaultContext() {
    return {
      "library": {"name": "analytics-dart", "version": "0.1"}
    };
  }
}

class AnalyticsClient extends BaseClient {
  String userAgent;
  Client _inner;

  AnalyticsClient(this._inner);

  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['Content-Type'] = "application/json";
    request.headers["Authorization"] = Analytics.writeKey;
    return _inner.send(request);
  }

  postSilentMicrotask(url, {Map<String, String> headers, body, Encoding encoding}) async {
    scheduleMicrotask(() async {
      await this.post(url, headers: headers, body: body, encoding: encoding);
    });
  }
}
