package com.daniel.runshaw

import android.content.Context
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.color.colorProviders
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.actionStartActivity
import java.text.DateFormat
import java.util.Date

private const val widgetRefreshUri = "runshaw://uk.danieldb.myrunshaw/refresh-balance"

class RunshawPayWidget : GlanceAppWidget() {
        override val stateDefinition = HomeWidgetGlanceStateDefinition()
        override suspend fun provideGlance(context: Context, id: GlanceId) {
                provideContent {
                        runshawPayWidgetGlanceTheme {
                                runshawPayWidgetContent(context, currentState())
                        }
                }
        }

        override public suspend fun providePreview(context: Context, widgetCategory: Int) {
                provideContent {
                        runshawPayWidgetGlanceTheme {
                                runshawPayWidgetContent(
                                        context,
                                        HomeWidgetGlanceState(
                                                preferences =
                                                        context.getSharedPreferences(
                                                                        "preview",
                                                                        Context.MODE_PRIVATE
                                                                )
                                                                .apply {
                                                                        edit().putString(
                                                                                        "runshawpay_balance",
                                                                                        "£12.34"
                                                                                )
                                                                                .apply()
                                                                        edit().putString(
                                                                                        "runshawpay_status",
                                                                                        "ok"
                                                                                )
                                                                                .apply()
                                                                        edit().putLong(
                                                                                        "runshawpay_updated_at",
                                                                                        System.currentTimeMillis()
                                                                                )
                                                                                .apply()
                                                                }
                                        )
                                )
                        }
                }
        }
}

@Composable
fun runshawPayWidgetGlanceTheme(
        content: @Composable () -> Unit,
) {
        val fallbackColors =
                colorProviders(
                        primary = ColorProvider(Color(0xFF7A1F16), Color(0xFFF2B8B2)),
                        onPrimary = ColorProvider(Color(0xFFFFF8F5), Color(0xFF3D0A04)),
                        primaryContainer = ColorProvider(Color(0xFFFCD9D3), Color(0xFF5D160D)),
                        onPrimaryContainer = ColorProvider(Color(0xFF2A0905), Color(0xFFFCD9D3)),
                        secondary = ColorProvider(Color(0xFF6B5A57), Color(0xFFE7BDB6)),
                        onSecondary = ColorProvider(Color(0xFFFFF8F5), Color(0xFF382B28)),
                        secondaryContainer = ColorProvider(Color(0xFFF2E2DE), Color(0xFF51413D)),
                        onSecondaryContainer = ColorProvider(Color(0xFF241816), Color(0xFFF2E2DE)),
                        tertiary = ColorProvider(Color(0xFF6A5D3F), Color(0xFFE2C48D)),
                        onTertiary = ColorProvider(Color(0xFFFFF8F5), Color(0xFF372D16)),
                        tertiaryContainer = ColorProvider(Color(0xFFF0E1BF), Color(0xFF50462B)),
                        onTertiaryContainer = ColorProvider(Color(0xFF241A04), Color(0xFFF0E1BF)),
                        error = ColorProvider(Color(0xFFBA1A1A), Color(0xFFFFB4AB)),
                        errorContainer = ColorProvider(Color(0xFFF9DEDC), Color(0xFF93000A)),
                        onError = ColorProvider(Color(0xFFFFF8F5), Color(0xFF690005)),
                        onErrorContainer = ColorProvider(Color(0xFF410002), Color(0xFFF9DEDC)),
                        background = ColorProvider(Color(0xFFFFF8F5), Color(0xFF201A19)),
                        onBackground = ColorProvider(Color(0xFF1F1B1B), Color(0xFFEDE0DD)),
                        surface = ColorProvider(Color(0xFFFFF8F5), Color(0xFF201A19)),
                        onSurface = ColorProvider(Color(0xFF1F1B1B), Color(0xFFEDE0DD)),
                        surfaceVariant = ColorProvider(Color(0xFFF2E2DE), Color(0xFF534341)),
                        onSurfaceVariant = ColorProvider(Color(0xFF514341), Color(0xFFD8C2BD)),
                        outline = ColorProvider(Color(0xFF847370), Color(0xFFA08C88)),
                        inverseOnSurface = ColorProvider(Color(0xFFF5EFED), Color(0xFF322827)),
                        inverseSurface = ColorProvider(Color(0xFF322827), Color(0xFFF5EFED)),
                        inversePrimary = ColorProvider(Color(0xFFF2B8B2), Color(0xFF7A1F16)),
                        widgetBackground = ColorProvider(Color(0xFFF2E2DE), Color(0xFF534341)),
                )

        GlanceTheme(
                colors =
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                GlanceTheme.colors // M3 on supported devices (android 12+)
                        } else {
                                fallbackColors
                        },
                content = { content.invoke() }
        )
}

@Composable
private fun runshawPayWidgetContent(context: Context, currentState: HomeWidgetGlanceState) {
        val preferences = currentState.preferences
        val balance = preferences.getString("runshawpay_balance", "Unknown") ?: "Unknown"
        val status = preferences.getString("runshawpay_status", "loading") ?: "loading"
        val updatedAtMillis = preferences.getLong("runshawpay_updated_at", 0L)

        Column(
                modifier =
                        GlanceModifier.fillMaxSize()
                                .background(GlanceTheme.colors.surface)
                                .clickable(
                                        onClick =
                                                actionStartActivity<MainActivity>(
                                                        context,
                                                        widgetRefreshUri.toUri()
                                                )
                                )
                                .padding(16.dp),
                horizontalAlignment = Alignment.Horizontal.Start,
                verticalAlignment = Alignment.Vertical.Top,
        ) {
                Text(
                        text = "RunshawPay",
                        style =
                                TextStyle(
                                        color = GlanceTheme.colors.onSurface,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.Medium,
                                )
                )

                Spacer(modifier = GlanceModifier.height(4.dp))

                // Text(
                //         text = balance,
                //         style =
                //                 TextStyle(
                //                         color = GlanceTheme.colors.primary,
                //                         fontSize = 26.sp,
                //                         fontWeight = FontWeight.Bold,
                //                         fontFamily = FontFamily.Monospace,
                //                 )
                // )
                CustomText(
                        text = balance,
                        font = R.font.rubik_bold,
                        fontSize = 36.sp,
                        modifier = GlanceModifier.padding(bottom = 4.dp),
                        color = GlanceTheme.colors.primary.getColor(context),
                )

                Spacer(modifier = GlanceModifier.height(22.dp))

                Text(
                        text = statusLabel(status, updatedAtMillis),
                        style =
                                TextStyle(
                                        color = GlanceTheme.colors.onSurface,
                                        fontSize = 11.sp,
                                )
                )

                Spacer(modifier = GlanceModifier.height(2.dp))

                Text(
                        text = "Tap to refresh",
                        style =
                                TextStyle(
                                        color = GlanceTheme.colors.onSurface,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Medium,
                                )
                )
        }
}

private fun statusLabel(status: String, updatedAtMillis: Long): String {
        return when (status) {
                "ok" -> {
                        if (updatedAtMillis > 0L) {
                                val updatedAt = Date(updatedAtMillis)
                                "Updated ${DateFormat.getTimeInstance(DateFormat.SHORT).format(updatedAt)}"
                        } else {
                                "Updated"
                        }
                }
                "error" -> "Could not update"
                else -> "Waiting for first sync"
        }
}

class RunshawPayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<RunshawPayWidget>() {
        override val glanceAppWidget: RunshawPayWidget = RunshawPayWidget()
}
