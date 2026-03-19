import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ActivityEntry.startTime, ascending: false)]
    ) var allEntries: FetchedResults<ActivityEntry>

    // Group entries by day
    var groupedDays: [(String, [ActivityEntry])] {
        var groups: [String: [ActivityEntry]] = [:]
        for entry in allEntries {
            let key = entry.startTime?.dayString ?? "unknown"
            groups[key, default: []].append(entry)
        }
        return groups.sorted { $0.key > $1.key }
    }

    var body: some View {
        Group {
            if groupedDays.isEmpty {
                Text("No history yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedDays, id: \.0) { day, entries in
                        Section {
                            ForEach(entries.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) { entry in
                                EntryRow(entry: entry)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewContext.delete(entry)
                                            try? viewContext.save()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text(formatDayHeader(day))
                                Spacer()
                                let total = entries.reduce(0) { $0 + minutesBetween($1.startTime ?? Date(), $1.endTime ?? Date()) }
                                Text(total.durationString)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    func formatDayHeader(_ dayString: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dayString) else { return dayString }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let out = DateFormatter()
        out.dateFormat = "EEEE, MMM d"
        return out.string(from: date)
    }
}
