import 'package:http/http.dart' as http;
import 'package:runshaw/utils/config.dart';
import 'package:xml/xml.dart';

const catEapUrl =
    'https://cat.eduroam.org/user/API.php?action=downloadInstaller&device=eap-generic&profile=${MyRunshawConfig.eduroamCatProfile}';

class EapConfigException implements Exception {
  EapConfigException(this.message);
  final String message;
  @override
  String toString() => 'EapConfigException: $message';
}

/// fetches the latest profile from eduroam CAT, throws [EapConfigException]
/// if the download or parsing fails
Future<Map<String, dynamic>> fetchEapConfig() async {
  final http.Response res;
  try {
    res = await http
        .get(Uri.parse(catEapUrl))
        .timeout(const Duration(seconds: 10));
  } catch (e) {
    throw EapConfigException('Could not reach eduroam CAT: $e');
  }
  if (res.statusCode != 200 || !res.body.contains('<EAPIdentityProvider')) {
    throw EapConfigException(
        'Unexpected CAT response (HTTP ${res.statusCode})');
  }
  try {
    return parseEapConfig(res.body);
  } catch (e) {
    throw EapConfigException('Could not parse CAT profile: $e');
  }
}

/// parse the EAP-metadata XML into the map the platform side expects.
Map<String, dynamic> parseEapConfig(String xml) {
  final doc = XmlDocument.parse(xml);
  final idp = doc.findAllElements('EAPIdentityProvider').first;

  String? text(XmlElement? e, String name) =>
      e?.findElements(name).firstOrNull?.innerText.trim();

  final method = idp.findAllElements('AuthenticationMethod').first;
  final outerType = int.parse(method
      .findElements('EAPMethod')
      .first
      .findElements('Type')
      .first
      .innerText
      .trim());

  final server = method.findElements('ServerSideCredential').firstOrNull;
  final client = method.findElements('ClientSideCredential').firstOrNull;
  final inner = method.findElements('InnerAuthenticationMethod').firstOrNull;

  // inner type: EAP (e.g. 26 = MSCHAPv2) or non-EAP (1 PAP, 2 MSCHAP, 3 MSCHAPv2 -> negative)
  int? innerType;
  final innerEap = inner?.findElements('EAPMethod').firstOrNull;
  final innerNonEap = inner?.findElements('NonEAPAuthMethod').firstOrNull;
  if (innerEap != null) {
    innerType = int.tryParse(text(innerEap, 'Type') ?? '');
  } else if (innerNonEap != null) {
    final n = int.tryParse(text(innerNonEap, 'Type') ?? '');
    innerType = n == null ? null : -n;
  }

  final ssids = idp
      .findAllElements('IEEE80211')
      .map((e) => text(e, 'SSID'))
      .whereType<String>()
      .toList();
  final oids = idp
      .findAllElements('IEEE80211')
      .map((e) => text(e, 'ConsortiumOID'))
      .whereType<String>()
      .toList();

  return {
    // should be student.runshaw.ac.uk but no need to hardcode when CAT exists
    'hs20Domain': idp.getAttribute('ID'),
    // just 'eduroam'
    'ssids': ssids,
    'consortiumOIDs': oids,
    'outerEapType': outerType,
    'innerEapType': innerType,
    'outerIdentity': text(client, 'OuterIdentity'),
    'usernameSuffix': text(client, 'InnerIdentitySuffix'),
    'serverIds': server
            ?.findElements('ServerID')
            .map((e) => e.innerText.trim())
            .toList() ??
        [],
    'caCertificates': server
            ?.findElements('CA')
            .where((e) =>
                e.getAttribute('format') == 'X.509' &&
                e.getAttribute('encoding') == 'base64')
            .map((e) => e.innerText.replaceAll(RegExp(r'\s'), ''))
            .toList() ??
        [],
  };
}
