import SwiftUI
import CoreData

struct DayView: View {
    let date: Date
    @Binding var showingAddEntry: Bool
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest var entries: FetchedResults<ActivityEntry>

    init(date: Date, showingAddEntry: Binding<Bool>) {
        self.date = date
        self._showingAddEntry = showingAddEntry
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        self._entries = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \ActivityEntry.startTime, ascending: true)],
            predicate: NSPredicate(format: "startTime >= %@ AND startTime < %@", start as NSDate, end as NSDate)
        )
    }

    var totalMinutes: Int {
        entries.reduce(0) { sum, e in
            sum + minutesBetween(e.startTime ?? Date(), e.endTime ?? Date())
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No entries yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap + to log your first activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Add Entry") { showingAddEntry = true }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        HStack {
                            Text("\(entries.count) activities")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(totalMinutes.durationString + " logged")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        ForEach(entries) { entry in
                            EntryRow(entry: entry)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    func deleteEntry(_ entry: ActivityEntry) {
        viewContext.delete(entry)
        try? viewContext.save()
    }
}

struct EntryRow: View {
    @ObservedObject var entry: ActivityEntry
    @State private var showingEdit = false

    var cat: Category { Category.from(entry.category ?? "other") }
    var duration: Int { minutesBetween(entry.startTime ?? Date(), entry.endTime ?? Date()) }

    var body: some View {
        Button(action: { showingEdit = true }) {
            HStack(alignment: .top, spacing: 12) {
                // Time column
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.startTime?.timeString ?? "")
                    Text(entry.endTime?.timeString ?? "")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 44)

                // Color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(cat.color)
                    .frame(width: 3)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.activity ?? "")
                        .font(.body)
                        .foregroundColor(.primary)
                    HStack(spacing: 8) {
                        Label(cat.label, systemImage: cat.icon)
                            .font(.caption)
                            .foregroundColor(cat.color)
                        Text(duration.durationString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEdit) {
            EditEntryView(entry: entry)
        }
    }
}
