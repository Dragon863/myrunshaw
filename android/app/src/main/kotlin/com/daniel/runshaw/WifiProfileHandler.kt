// adapted from geteduroam/android-app (PlatformWifiConfigData.kt, WifiConfigViewModel.kt,
// CertificateUtilities.kt)
// Copyright 2022-2023, The Commons Conservancy geteduroam Programme, BSD 3-Clause License

package com.daniel.runshaw

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiEnterpriseConfig
import android.net.wifi.WifiEnterpriseConfig.Eap
import android.net.wifi.WifiEnterpriseConfig.Phase2
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSuggestion
import android.net.wifi.hotspot2.PasspointConfiguration
import android.net.wifi.hotspot2.pps.Credential
import android.net.wifi.hotspot2.pps.HomeSp
import android.os.Build
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

private const val TAG = "WifiProfile"

class WifiProfileException(val code: String, message: String) : Exception(message)

// config (built from the map dart sends, which dart parsed from the CAT .eap file)

class OrgWifiConfig(
        val ssids: List<String>,
        val consortiumOids: List<Long>,
        val realm: String?,
        val outerEapType: Int, // 21 = TTLS, 25 = PEAP
        val innerEapType: Int?, // 26 / -3 = MSCHAPv2, -1 = PAP, -2 = MSCHAP
        val outerIdentity: String?,
        val serverIds: List<String>,
        val caCertificates: List<X509Certificate>,
        val usernameSuffix: String?,
) {
    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromMap(m: Map<String, Any?>): OrgWifiConfig {
            val certFactory = CertificateFactory.getInstance("X.509")
            val certs =
                    (m["caCertificates"] as? List<String> ?: emptyList()).mapNotNull {
                        try {
                            certFactory.generateCertificate(
                                    ByteArrayInputStream(Base64.decode(it, Base64.DEFAULT))
                            ) as
                                    X509Certificate
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to parse CA certificate", e)
                            null
                        }
                    }
            return OrgWifiConfig(
                    ssids = m["ssids"] as? List<String> ?: emptyList(),
                    consortiumOids =
                            (m["consortiumOIDs"] as? List<String> ?: emptyList()).mapNotNull {
                                it.toLongOrNull(16)
                            },
                    realm = m["hs20Domain"] as? String,
                    outerEapType = (m["outerEapType"] as? Number)?.toInt() ?: 0,
                    innerEapType = (m["innerEapType"] as? Number)?.toInt(),
                    outerIdentity = m["outerIdentity"] as? String,
                    serverIds = m["serverIds"] as? List<String> ?: emptyList(),
                    caCertificates = certs,
                    usernameSuffix = m["usernameSuffix"] as? String,
            )
        }
    }
}

// MethodChannel handler

class WifiProfileHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        // Remove the hardcoded package prefix, keep only the path suffix
        private const val CHANNEL_SUFFIX = "/wifi_profile"
        private const val REQ_ADD_NETWORKS = 4711
    }

    // A helper property to generate the exact channel name dynamically
    val channelName: String
        get() = "${activity.packageName}$CHANNEL_SUFFIX"

    private var pendingResult: MethodChannel.Result? = null
    private val wifi: WifiManager
        get() = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, channelName).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> {
                val username = call.argument<String>("username")
                val password = call.argument<String>("password")
                val cfgMap = call.argument<Map<String, Any?>>("config")
                if (username.isNullOrEmpty() || password.isNullOrEmpty() || cfgMap == null) {
                    result.error("bad_args", "username, password, config required", null)
                    return
                }
                if (pendingResult != null) {
                    result.error("busy", "Another request is in progress", null)
                    return
                }
                try {
                    configure(OrgWifiConfig.fromMap(cfgMap), username, password, result)
                } catch (e: WifiProfileException) {
                    result.error(e.code, e.message, null)
                } catch (e: SecurityException) {
                    result.error("permission", e.message, null)
                } catch (e: IllegalArgumentException) {
                    // System rejected the configuration (e.g. missing CA / invalid SSID)
                    result.error("config_rejected", e.message, null)
                }
            }
            "remove" -> {
                // removes suggestions this app added. networks added through the Android 12+
                // system dialog cannot be removed by an app; the user must "forget" them :(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    try {
                        wifi.removeNetworkSuggestions(emptyList())
                    } catch (e: Exception) {
                        Log.w(TAG, e)
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** call from MainActivity.onActivityResult, returns true if it p tcessedhe result. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQ_ADD_NETWORKS) return false
        val result = pendingResult ?: return true
        pendingResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.error("user_cancelled", "User declined the Wi-Fi prompt", null)
            return true
        }
        val codes =
                data?.getIntegerArrayListExtra(Settings.EXTRA_WIFI_NETWORK_RESULT_LIST)
                        ?: arrayListOf()
        // 0 = success, 2 = already exists (fine), 1 = add/update failed
        if (codes.contains(Settings.ADD_WIFI_RESULT_ADD_OR_UPDATE_FAILED)) {
            result.error("add_failed", "Android could not add the network", null)
        } else {
            result.success(null)
        }
        return true
    }

    // install paths use the same logic as geteduroam
    //   API 31+  : system "Add networks" dialog for SSIDs, suggestion for Passpoint
    //   API 29-30: network suggestions (user approves via notification)
    //   API 26-28: legacy WifiConfiguration

    private fun configure(
            config: OrgWifiConfig,
            rawUsername: String,
            password: String,
            result: MethodChannel.Result
    ) {
        val username = resolveUsername(config, rawUsername)
        val enterprise = buildEnterpriseConfig(config, username, password)
        val passpoint = buildPasspointConfig(config, username, password)

        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                if (passpoint != null) addPasspointSuggestion(passpoint)
                val suggestions = ArrayList(buildSsidSuggestions(config, enterprise))
                if (suggestions.isEmpty())
                        throw WifiProfileException("no_networks", "No SSID configured")
                val intent =
                        Intent(Settings.ACTION_WIFI_ADD_NETWORKS)
                                .putParcelableArrayListExtra(
                                        Settings.EXTRA_WIFI_NETWORK_LIST,
                                        suggestions
                                )
                pendingResult = result
                activity.startActivityForResult(intent, REQ_ADD_NETWORKS)
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                val suggestions = buildSsidSuggestions(config, enterprise)
                if (suggestions.isEmpty())
                        throw WifiProfileException("no_networks", "No SSID configured")
                wifi.removeNetworkSuggestions(emptyList())
                val status = wifi.addNetworkSuggestions(suggestions)
                if (status != WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS) {
                    throw WifiProfileException(
                            "suggestion_failed_$status",
                            "addNetworkSuggestions returned $status"
                    )
                }
                passpoint?.let { installPasspoint(it) }
                result.success(null)
            }
            else -> {
                addLegacy(config, enterprise)
                passpoint?.let { installPasspoint(it) }
                result.success(null)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun addLegacy(config: OrgWifiConfig, enterprise: WifiEnterpriseConfig) {
        for (ssid in config.ssids) {
            val wc =
                    WifiConfiguration().apply {
                        SSID = "\"$ssid\""
                        priority = 1
                        status = WifiConfiguration.Status.ENABLED
                        allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_EAP)
                        allowedKeyManagement.set(WifiConfiguration.KeyMgmt.IEEE8021X)
                        enterpriseConfig = enterprise
                    }
            val id = wifi.addNetwork(wc)
            if (id != -1) {
                wifi.disconnect()
                wifi.enableNetwork(id, true)
                wifi.reconnect()
            }
        }
    }

    /** append suffix if user gave no "@" */
    private fun resolveUsername(config: OrgWifiConfig, raw: String): String {
        val suffix = config.usernameSuffix
        if (suffix.isNullOrEmpty()) return raw
        val user = if (raw.contains("@")) raw else "$raw@$suffix"
        if (!user.endsWith("@$suffix")) {
            throw WifiProfileException("invalid_username", "Username must end with @$suffix")
        }
        return user
    }

    private fun buildEnterpriseConfig(
            config: OrgWifiConfig,
            username: String,
            password: String
    ): WifiEnterpriseConfig {
        val eap =
                when (config.outerEapType) {
                    21 -> Eap.TTLS
                    25 -> Eap.PEAP
                    else ->
                            throw WifiProfileException(
                                    "unsupported_eap",
                                    "Unsupported EAP type ${config.outerEapType}"
                            )
                }
        val cas = config.caCertificates.filter { isCa(it) }
        if (cas.isEmpty() || config.serverIds.isEmpty()) {
            // refuse to install a profile that can't validate the RADIUS server
            throw WifiProfileException(
                    "unverifiable_network",
                    "Config has no CA certificate or server name"
            )
        }
        return WifiEnterpriseConfig().apply {
            eapMethod = eap
            phase2Method = phase2(config.innerEapType) ?: Phase2.NONE
            identity = username
            this.password = password
            config.outerIdentity?.let { anonymousIdentity = it }
            caCertificates = cas.toTypedArray()
            domainSuffixMatch = domainSuffixMatch(config.serverIds)
        }
    }

    private fun buildSsidSuggestions(
            config: OrgWifiConfig,
            enterprise: WifiEnterpriseConfig
    ): List<WifiNetworkSuggestion> =
            config.ssids.map { ssid ->
                WifiNetworkSuggestion.Builder()
                        .setSsid(ssid)
                        .setWpa2EnterpriseConfig(enterprise)
                        .setIsAppInteractionRequired(true)
                        .build()
            }

    /**
     * passpoint on Android only supports EAP-TTLS for username/password credentials, so it is
     * skipped for PEAP profiles (the SSID path still works for those)
     */
    private fun buildPasspointConfig(
            config: OrgWifiConfig,
            username: String,
            password: String
    ): PasspointConfiguration? {
        if (config.consortiumOids.isEmpty() || config.outerEapType != 21) return null
        val realm = config.realm ?: return null
        val roots = config.caCertificates.filter { isRootCa(it) }
        if (roots.size != 1) {
            Log.w(TAG, "Passpoint skipped: exactly one root CA supported, got ${roots.size}")
            return null
        }
        val user =
                Credential.UserCredential().apply {
                    this.username = username
                    this.password =
                            Base64.encodeToString(
                                    password.toByteArray(Charsets.UTF_8),
                                    Base64.NO_WRAP
                            )
                    eapType = 21
                    nonEapInnerMethod =
                            when (phase2(config.innerEapType)) {
                                Phase2.MSCHAPV2 -> "MS-CHAP-V2"
                                Phase2.PAP -> "PAP"
                                Phase2.MSCHAP -> "MS-CHAP"
                                else -> null
                            }
                }
        return PasspointConfiguration().apply {
            homeSp =
                    HomeSp().apply {
                        fqdn = domainSuffixMatch(config.serverIds)
                        friendlyName = "$realm via Passpoint"
                        roamingConsortiumOis = config.consortiumOids.toLongArray()
                    }
            credential =
                    Credential().apply {
                        this.realm = realm
                        caCertificate = roots[0]
                        userCredential = user
                    }
        }
    }

    private fun addPasspointSuggestion(p: PasspointConfiguration) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        try {
            wifi.removeNetworkSuggestions(emptyList())
            val status =
                    wifi.addNetworkSuggestions(
                            listOf(WifiNetworkSuggestion.Builder().setPasspointConfig(p).build())
                    )
            if (status != WifiManager.STATUS_NETWORK_SUGGESTIONS_SUCCESS)
                    Log.w(TAG, "Passpoint suggestion status $status")
        } catch (e: Exception) {
            Log.w(
                    TAG,
                    "Passpoint suggestion failed (non-fatal)",
                    e
            ) // passpoint is best-effort, SSID is the main path
        }
    }

    @Suppress("DEPRECATION")
    private fun installPasspoint(p: PasspointConfiguration) {
        try {
            try {
                wifi.removePasspointConfiguration(p.homeSp.fqdn)
            } catch (_: Exception) {}
            wifi.addOrUpdatePasspointConfiguration(p)
        } catch (e: Exception) {
            Log.w(TAG, "Passpoint install failed (non-fatal)", e)
        }
    }

    // Helpers

    /**
     * Inner method: EAP type 26 (CAT reports TTLS/PEAP-MSCHAPv2 this way) or negative non-EAP code.
     */
    private fun phase2(inner: Int?): Int? =
            when (inner) {
                -1 -> Phase2.PAP
                -2 -> Phase2.MSCHAP
                -3, 26 -> Phase2.MSCHAPV2
                else -> null
            }

    /**
     * Android 10+: semicolon-separated list. Android 9: single suffix, so use the common suffix.
     */
    private fun domainSuffixMatch(serverIds: List<String>): String {
        val joined = serverIds.joinToString(";")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && joined.length < 256) joined
        else commonDomainSuffix(serverIds)
    }

    private fun commonDomainSuffix(names: List<String>): String {
        val split = names.map { it.split('.').reversed() }
        val n = split.minOf { it.size }
        val common =
                (0 until n).takeWhile { i -> split.all { it[i] == split[0][i] } }.map {
                    split[0][it]
                }
        return common.reversed().joinToString(".")
    }

    private fun isRootCa(c: X509Certificate) =
            c.subjectX500Principal == c.issuerX500Principal && isCa(c)

    private fun isCa(c: X509Certificate): Boolean {
        val usage = c.keyUsage
        if (usage != null && usage.size > 5 && usage[5]) return true // keyCertSign
        return c.getExtensionValue("2.5.29.19") != null && c.basicConstraints != -1
    }
}
