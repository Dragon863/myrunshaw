import SwiftUI
import WidgetKit

private enum WidgetConstants {
    static let kind = "RunshawPayWidget"
    static let appGroup = "group.uk.danieldb.myrunshaw"
    static let balanceKey = "runshawpay_balance"
    static let statusKey = "runshawpay_status"
    static let updatedAtKey = "runshawpay_updated_at"
    static let refreshUrl = URL(string: "runshaw://uk.danieldb.myrunshaw/refresh-balance")!
    static let backgroundGradient = LinearGradient(
        colors: [Color(red: 244/255, green: 67/255, blue: 54/255), Color(red: 138/255, green: 49/255, blue: 43/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}


struct RunshawPayEntry: TimelineEntry {
    let date: Date
    let balance: String
    let status: String
    let lastUpdated: Date?
}

struct RunshawPayProvider: TimelineProvider {
    func placeholder(in context: Context) -> RunshawPayEntry {
        RunshawPayEntry(
            date: Date(),
            balance: "--",
            status: "loading",
            lastUpdated: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RunshawPayEntry) -> Void) {
        if context.isPreview {
            completion(
                RunshawPayEntry(
                    date: Date(),
                    balance: "--",
                    status: "loading",
                    lastUpdated: nil
                )
            )
            return
        }

        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RunshawPayEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> RunshawPayEntry {
        let defaults = UserDefaults(suiteName: WidgetConstants.appGroup)

        let balance = defaults?.string(forKey: WidgetConstants.balanceKey) ?? "Unknown"
        let status = defaults?.string(forKey: WidgetConstants.statusKey) ?? "loading"
        let updatedAtMillis = defaults?.double(forKey: WidgetConstants.updatedAtKey) ?? 0

        let updatedAtDate: Date?
        if updatedAtMillis > 0 {
            updatedAtDate = Date(timeIntervalSince1970: updatedAtMillis / 1000)
        } else {
            updatedAtDate = nil
        }

        return RunshawPayEntry(
            date: Date(),
            balance: balance,
            status: status,
            lastUpdated: updatedAtDate
        )
    }
}

struct RunshawPayWidgetEntryView: View {
    var entry: RunshawPayProvider.Entry

    var body: some View {
        widgetSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text("RunshawPay")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))

                Text(entry.balance)
                    .font(.system(size: 30, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Spacer()

                HStack {
                    Text(statusLabel)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Link("Refresh", destination: WidgetConstants.refreshUrl)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
        }
        .widgetURL(WidgetConstants.refreshUrl)
    }

    private func widgetSurface<Content: View>(@ViewBuilder _ content: () -> Content) -> AnyView {
        if #available(iOS 17.0, *) {
            return AnyView(
                content()
                    .containerBackground(WidgetConstants.backgroundGradient, for: .widget)
            )
        } else {
            return AnyView(
                content()
                    .background(
                        ContainerRelativeShape()
                            .fill(WidgetConstants.backgroundGradient)
                    )
            )
        }
    }

    private var statusLabel: String {
        switch entry.status {
        case "ok":
            if let lastUpdated = entry.lastUpdated {
                return "Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))"
            }
            return "Updated"
        case "error":
            return "Could not update"
        default:
            return "Waiting for first sync"
        }
    }
}

struct RunshawPayWidget: Widget {
    let kind: String = WidgetConstants.kind

    var body: some WidgetConfiguration {
        let configuration = StaticConfiguration(kind: kind, provider: RunshawPayProvider()) { entry in
            RunshawPayWidgetEntryView(entry: entry)
        }

        if #available(iOS 17.0, *) {
            return configuration
                .contentMarginsDisabled()
                .configurationDisplayName("RunshawPay Balance")
                .description("Shows your latest RunshawPay balance.")
                .supportedFamilies([.systemSmall, .systemMedium])
        } else {
            return configuration
                .configurationDisplayName("RunshawPay Balance")
                .description("Shows your latest RunshawPay balance.")
                .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
}

@main
struct RunshawPayWidgetBundle: WidgetBundle {
    var body: some Widget {
        RunshawPayWidget()
    }
}

// iOS 17+ live preview
@available(iOS 17.0, *)
#Preview(as: .systemSmall, widget: {
    RunshawPayWidget()
}, timeline: {
    RunshawPayEntry(
        date: Date(),
        balance: "£12.34",
        status: "ok",
        lastUpdated: Date()
    )
})
