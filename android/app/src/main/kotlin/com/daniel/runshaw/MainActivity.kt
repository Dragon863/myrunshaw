package com.daniel.runshaw

// WIDGET_CATEGORY_HOME_SCREEN is provided by AppWidgetProviderInfo
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.os.Build
import android.os.Bundle
import androidx.collection.intSetOf
import androidx.glance.appwidget.GlanceAppWidgetManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val widgetPreviewScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        publishWidgetPreviewIfNeeded()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "runshaw/widget")
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "hasWidget" -> {
                            try {
                                val appWidgetManager =
                                        getSystemService(AppWidgetManager::class.java)
                                val providerComponent =
                                        ComponentName(
                                                this@MainActivity,
                                                RunshawPayWidgetReceiver::class.java
                                        )
                                val ids = appWidgetManager.getAppWidgetIds(providerComponent)
                                result.success(ids != null && ids.isNotEmpty())
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
    }

    private fun publishWidgetPreviewIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            return
        }

        widgetPreviewScope.launch {
            val appWidgetManager = getSystemService(AppWidgetManager::class.java)
            val providerComponent =
                    ComponentName(this@MainActivity, RunshawPayWidgetReceiver::class.java)
            val providerInfo =
                    appWidgetManager.installedProviders.firstOrNull {
                        it.provider == providerComponent
                    }
                            ?: return@launch

            if (providerInfo.generatedPreviewCategories and
                            AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN != 0
            ) {
                return@launch
            }

            try {
                appWidgetManager.setWidgetPreview(
                        providerComponent,
                        AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN,
                        android.widget.RemoteViews(packageName, R.layout.widget_preview)
                )
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}
