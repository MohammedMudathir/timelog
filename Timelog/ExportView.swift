import SwiftUI
import CoreData

struct ExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ActivityEntry.startTime, ascending: true)]) var allEntries: FetchedResults<ActivityEntry>

    @State private var exportMode: ExportMode = .singleDay
    @State private var selectedDate = Date()
    @State private var rangeStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var copied = false

    enum ExportMode: String, CaseIterable {
        case singleDay = "Single Day"
        case dateRange = "Date Range"
    }

    var filteredEntries: [ActivityEntry] {
        switch exportMode {
        case .singleDay:
            let start = Calendar.current.startOfDay(for: selectedDate)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            return allEntries.filter {
                guard let t = $0.startTime else { return false }
                return t >= start && t < end
            }
        case .dateRange:
            let start = Calendar.current.startOfDay(for: rangeStart)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: rangeEnd))!
            return allEntries.filter {
                guard let t = $0.startTime else { return false }
                return t >= start && t < end
            }
        }
    }

    var exportText: String {
        guard !filteredEntries.isEmpty else { return "No entries found for the selected period." }

        var lines: [String] = []

        // Header
        switch exportMode {
        case .singleDay:
            lines.append("📅 \(selectedDate.displayDate)")
        case .dateRange:
            lines.append("📅 \(rangeStart.displayDate) – \(rangeEnd.displayDate)")
        }
        lines.append(String(repeating: "─", count: 40))
        lines.append("")

        // Group by day
        var dayGroups: [String: [ActivityEntry]] = [:]
        for entry in filteredEntries {
            let key = entry.startTime?.dayString ?? "unknown"
            dayGroups[key, default: []].append(entry)
        }

        let sortedDays = dayGroups.keys.sorted()

        for day in sortedDays {
            let dayEntries = (dayGroups[day] ?? []).sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }

            if exportMode == .dateRange {
                // Day header for range export
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                if let date = f.date(from: day) {
                    let out = DateFormatter()
                    out.dateFormat = "EEEE, MMM d"
                    lines.append("▸ \(out.string(from: date))")
                }
            }

            for entry in dayEntries {
                let start = entry.startTime?.timeString ?? "?"
                let end = entry.endTime?.timeString ?? "?"
                let dur = minutesBetween(entry.startTime ?? Date(), entry.endTime ?? Date())
                let cat = Category.from(entry.category ?? "other").label
                var line = "\(start)–\(end)  [\(cat)]  \(entry.activity ?? "")  (\(dur.durationString))"
                if let notes = entry.notes, !notes.isEmpty {
                    line += "\n  ↳ \(notes)"
                }
                lines.append(line)
            }

            if exportMode == .dateRange { lines.append("") }
        }

        // Summary
        lines.append("")
        lines.append(String(repeating: "─", count: 40))
        lines.append("SUMMARY")
        lines.append("")

        let totalMins = filteredEntries.reduce(0) { $0 + minutesBetween($1.startTime ?? Date(), $1.endTime ?? Date()) }
        lines.append("Total logged: \(totalMins.durationString)")
        lines.append("Activities: \(filteredEntries.count)")
        lines.append("")

        // Category breakdown
        let catBreakdown = Category.allCases.compactMap { cat -> String? in
            let mins = filteredEntries
                .filter { $0.category == cat.rawValue }
                .reduce(0) { $0 + minutesBetween($1.startTime ?? Date(), $1.endTime ?? Date()) }
            guard mins > 0 else { return nil }
            let pct = totalMins > 0 ? Int(Double(mins) / Double(totalMins) * 100) : 0
            return "  \(cat.label): \(mins.durationString) (\(pct)%)"
        }
        lines.append(contentsOf: catBreakdown)

        return lines.joined(separator: "\n")
    }

    var body: some View {
        List {
            Section {
                Picker("Export", selection: $exportMode) {
                    ForEach(ExportMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if exportMode == .singleDay {
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                }
            } else {
                Section {
                    DatePicker("From", selection: $rangeStart, displayedComponents: .date)
                    DatePicker("To", selection: $rangeEnd, displayedComponents: .date)
                }
            }

            Section {
                Button(action: copyToClipboard) {
                    HStack {
                        Spacer()
                        Label(copied ? "Copied!" : "Copy to Clipboard", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .font(.headline)
                            .foregroundColor(copied ? .green : .accentColor)
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Preview") {
                Text(exportText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
        .listStyle(.sidebar)
    }

    func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = exportText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(exportText, forType: .string)
        #endif
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
