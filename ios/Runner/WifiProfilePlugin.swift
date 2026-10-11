// Adapted from geteduroam/apple-app (EAPConfigurator.swift)
// Copyright 2022-2024, The Commons Conservancy geteduroam Programme
// BSD 3-Clause License - keep this notice and include the full LICENSE.md in your repo/legal notices.

import Flutter
import NetworkExtension
import OSLog
import Security

private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WifiProfile", category: "wifi")

// MARK: - Network config

struct OrgWifiConfig {
    var ssids: [String]
    var consortiumOIDs: [String] = []
    var hs20Domain: String? = nil               // = EAPIdentityProvider ID attribute
    var outerEAP: NEHotspotEAPSettings.EAPType  // EAP type 25 = PEAP, 21 = TTLS
    var innerAuth: NEHotspotEAPSettings.TTLSInnerAuthenticationType = .eapttlsInnerAuthenticationMSCHAPv2
    var outerIdentity: String? = nil
    var trustedServerNames: [String]
    var caCertificatesBase64: [String]
    var usernameSuffix: String? = nil
    var usernameSuffixIsHint: Bool = true       // true: append suffix if user typed no "@"

    init(map: [String: Any]) throws {
        func strings(_ key: String) -> [String] { (map[key] as? [Any])?.compactMap { $0 as? String } ?? [] }

        ssids = strings("ssids")
        consortiumOIDs = strings("consortiumOIDs")
        hs20Domain = map["hs20Domain"] as? String
        trustedServerNames = strings("serverIds")
        caCertificatesBase64 = strings("caCertificates")
        outerIdentity = map["outerIdentity"] as? String
        usernameSuffix = map["innerIdentitySuffix"] as? String
        usernameSuffixIsHint = (map["innerIdentityHint"] as? Bool) ?? true

        // EAP type numbers from the eap-config XML (IANA EAP method types)
        switch map["outerEapType"] as? Int {
        case 21: outerEAP = .EAPTTLS
        case 25: outerEAP = .EAPPEAP
        case 43: outerEAP = .EAPFAST
        default: throw WifiProfileError.unsupportedEAPType
        }
        // Inner method: positive = EAP type, negative = non-EAP (-1 PAP, -2 MSCHAP, -3 MSCHAPv2)
        switch map["innerEapType"] as? Int {
        case -1: innerAuth = .eapttlsInnerAuthenticationPAP
        case -2: innerAuth = .eapttlsInnerAuthenticationMSCHAP
        case 26: innerAuth = .eapttlsInnerAuthenticationEAP
        default: innerAuth = .eapttlsInnerAuthenticationMSCHAPv2
        }
    }
}

// MARK: - Errors

enum WifiProfileError: Error, LocalizedError {
    case noNetworks
    case badCertificate
    case caImportFailed
    case invalidUsername(suffix: String)
    case emptyCredentials
    case keychain(OSStatus)
    case unsupportedEAPType
    case badConfig

    var errorDescription: String? {
        switch self {
        case .noNetworks: return "No SSID or OID configured"
        case .badCertificate: return "Could not parse CA certificate"
        case .caImportFailed: return "Could not set trusted server certificates"
        case .invalidUsername(let s): return "Username must end with @\(s)"
        case .emptyCredentials: return "Username and password are required"
        case .keychain(let status): return "Keychain error (\(status))"
        case .unsupportedEAPType: return "Unsupported EAP type in profile"
        case .badConfig: return "Missing or invalid network config"
        }
    }
}

// MARK: - Configurator

final class WifiConfigurator {
    private let config: OrgWifiConfig
    private let teamID: String   // Apple Developer Team ID (NOT the bundle ID)
    private var accessGroup: String { "\(teamID).com.apple.networkextensionsharing" }

    init(config: OrgWifiConfig, teamID: String) {
        self.config = config
        self.teamID = teamID
    }

    func configure(username: String, password: String) async throws {
        guard !username.isEmpty, !password.isEmpty else { throw WifiProfileError.emptyCredentials }
        let user = try resolveUsername(username)

        // remove any previous profile first so re-onboarding replaces it
        remove()

        let eap = try buildEAPSettings(username: user, password: password)

        var configurations: [NEHotspotConfiguration] = []
        if !config.consortiumOIDs.isEmpty, let domain = config.hs20Domain {
            let hs20 = NEHotspotHS20Settings(domainName: domain, roamingEnabled: true)
            hs20.roamingConsortiumOIs = config.consortiumOIDs.map { $0.uppercased() }
            configurations.append(NEHotspotConfiguration(hs20Settings: hs20, eapSettings: eap))
        }
        for ssid in config.ssids {
            configurations.append(NEHotspotConfiguration(ssid: ssid, eapSettings: eap))
        }
        guard !configurations.isEmpty else { throw WifiProfileError.noNetworks }

        for configuration in configurations {
            do {
                try await NEHotspotConfigurationManager.shared.apply(configuration)
            } catch let error as NSError
                where error.domain == NEHotspotConfigurationErrorDomain
                   && error.code == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                // already joined this network: treat as success (not handled in the original app)
                log.info("Already associated, continuing")
            }
        }
    }

    func remove() {
        for ssid in config.ssids {
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        }
        if let domain = config.hs20Domain {
            NEHotspotConfigurationManager.shared.removeConfiguration(forHS20DomainName: domain)
        }
    }

    // MARK: Username

    private func resolveUsername(_ raw: String) throws -> String {
        guard let suffix = config.usernameSuffix, !suffix.isEmpty else { return raw }
        let user = (config.usernameSuffixIsHint && !raw.contains("@")) ? "\(raw)@\(suffix)" : raw
        guard user.hasSuffix("@\(suffix)") else { throw WifiProfileError.invalidUsername(suffix: suffix) }
        return user
    }

    // MARK: EAP settings

    private func buildEAPSettings(username: String, password: String) throws -> NEHotspotEAPSettings {
        let eap = NEHotspotEAPSettings()
        eap.supportedEAPTypes = [NSNumber(value: config.outerEAP.rawValue)]
        eap.ttlsInnerAuthenticationType = config.innerAuth
        eap.username = username
        eap.password = password
        eap.isTLSClientCertificateRequired = false
        if let outer = config.outerIdentity { eap.outerIdentity = outer }

        if !config.trustedServerNames.isEmpty {
            eap.trustedServerNames = config.trustedServerNames
        }
        if !config.caCertificatesBase64.isEmpty {
            let certs = try config.caCertificatesBase64.map(addCertificate)
            guard eap.setTrustedServerCertificates(certs) else { throw WifiProfileError.caImportFailed }
        }
        return eap
    }

    // MARK: Keychain (CA must live in the networkextensionsharing access group)

    private func addCertificate(_ base64: String) throws -> SecCertificate {
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData)
        else { throw WifiProfileError.badCertificate }

        let label = (SecCertificateCopySubjectSummary(cert) as String?) ?? UUID().uuidString

        let add: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrLabel as String: label,
            kSecReturnRef as String: kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        var item: CFTypeRef?
        var status = SecItemAdd(add as CFDictionary, &item)
        if status == errSecSuccess, let item { return item as! SecCertificate }
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            // -34018 = errSecMissingEntitlement -> check keychain-access-groups entitlement + teamID
            throw WifiProfileError.keychain(status)
        }

        // Duplicate: fetch the existing one
        let get: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: label,
            kSecReturnRef as String: kCFBooleanTrue!,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        status = SecItemCopyMatching(get as CFDictionary, &item)
        guard status == errSecSuccess, let item else { throw WifiProfileError.keychain(status) }
        return item as! SecCertificate
    }
}

// MARK: - Flutter MethodChannel

extension OrgWifiConfig {
    /// Build from the map Dart sends (parsed from the CAT .eap file).
    init(map: [String: Any]) throws {
        guard let ssids = map["ssids"] as? [String],
              let outer = map["outerEapType"] as? Int,
              let eapType = WifiConfigurator.outerEapType(outer)
        else { throw WifiProfileError.noNetworks }
        self.init(
            ssids: ssids,
            consortiumOIDs: map["consortiumOIDs"] as? [String] ?? [],
            hs20Domain: map["hs20Domain"] as? String,
            outerEAP: eapType,
            innerAuth: WifiConfigurator.innerAuth(map["innerEapType"] as? Int),
            outerIdentity: map["outerIdentity"] as? String,
            trustedServerNames: map["serverIds"] as? [String] ?? [],
            caCertificatesBase64: map["caCertificates"] as? [String] ?? [],
            usernameSuffix: map["usernameSuffix"] as? String
        )
    }
}

extension WifiConfigurator {
    // Same EAP type numbers as the original getOuterEapType / getInnerAuthMethod
    static func outerEapType(_ n: Int) -> NEHotspotEAPSettings.EAPType? {
        switch n {
        case 21: return .EAPTTLS
        case 25: return .EAPPEAP
        case 43: return .EAPFAST
        default: return nil   // 13 (EAP-TLS) not supported in this trimmed version
        }
    }
    static func innerAuth(_ n: Int?) -> NEHotspotEAPSettings.TTLSInnerAuthenticationType {
        switch n {
        case -1: return .eapttlsInnerAuthenticationPAP
        case -2: return .eapttlsInnerAuthenticationMSCHAP
        case -3: return .eapttlsInnerAuthenticationMSCHAPv2
        case 26: return .eapttlsInnerAuthenticationEAP   // EAP-MSCHAPv2
        default: return .eapttlsInnerAuthenticationMSCHAPv2
        }
    }
}

final class WifiProfilePlugin {
       static var channelName: String { "\(Bundle.main.bundleIdentifier ?? "")/wifi_profile" }   // keep in sync with dart

    static func register(messenger: FlutterBinaryMessenger, teamID: String) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

        channel.setMethodCallHandler { call, result in
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "bad_args", message: "arguments required", details: nil))
                return
            }
            switch call.method {
            case "configure":
                guard let username = args["username"] as? String,
                      let password = args["password"] as? String,
                      let cfgMap = args["config"] as? [String: Any]
                else {
                    result(FlutterError(code: "bad_args", message: "username, password, config required", details: nil))
                    return
                }
                Task { @MainActor in
                    do {
                        let configurator = WifiConfigurator(config: try OrgWifiConfig(map: cfgMap), teamID: teamID)
                        try await configurator.configure(username: username, password: password)
                        result(nil)
                    } catch {
                        result(WifiProfilePlugin.flutterError(for: error))
                    }
                }
            case "remove":
                if let cfgMap = args["config"] as? [String: Any],
                   let cfg = try? OrgWifiConfig(map: cfgMap) {
                    WifiConfigurator(config: cfg, teamID: teamID).remove()
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func flutterError(for error: Error) -> FlutterError {
        let ns = error as NSError
        if ns.domain == NEHotspotConfigurationErrorDomain {
            switch ns.code {
            case NEHotspotConfigurationError.userDenied.rawValue:
                return FlutterError(code: "user_cancelled", message: "User declined the Wi-Fi prompt", details: nil)
            case NEHotspotConfigurationError.applicationIsNotInForeground.rawValue:
                return FlutterError(code: "not_in_foreground", message: "App must be in the foreground", details: nil)
            default:
                return FlutterError(code: "hotspot_\(ns.code)", message: ns.localizedDescription, details: nil)
            }
        }
        if let e = error as? WifiProfileError {
            return FlutterError(code: "config_error", message: e.errorDescription, details: nil)
        }
        return FlutterError(code: "unknown", message: error.localizedDescription, details: nil)
    }
}
