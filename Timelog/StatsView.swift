import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) var allEntries: FetchedResults<ActivityEntry>

    @State private var rangeStart = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var rangeEnd = Date()

    var filteredEntries: [ActivityEntry] {
        let start = Calendar.current.startOfDay(for: rangeStart)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: rangeEnd)) ?? rangeEnd
        return allEntries.filter {
            guard let t = $0.startTime else { return false }
            return t >= start && t < end
        }
    }

    var totalMinutes: Int {
        filteredEntries.reduce(0) { $0 + minutesBetween($1.startTime ?? Date(), $1.endTime ?? Date()) }
    }

    var categoryBreakdown: [(Category, Int)] {
        Category.allCases.compactMap { cat in
            let mins = filteredEntries
                .filter { $0.category == cat.rawValue }
                .reduce(0) { $0 + minutesBetween($1.startTime ?? Date(), $1.endTime ?? Date()) }
            return mins > 0 ? (cat, mins) : nil
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        List {
            Section("Date Range") {
                DatePicker("From", selection: $rangeStart, displayedComponents: .date)
                DatePicker("To", selection: $rangeEnd, displayedComponents: .date)
            }

            if filteredEntries.isEmpty {
                Section {
                    Text("No entries in this range")
                        .foregroundColor(.secondary)
                }
            } else {
                Section {
                    HStack {
                        Text("Total logged")
                        Spacer()
                        Text(totalMinutes.durationString)
                            .bold()
                    }
                    HStack {
                        Text("Activities")
                        Spacer()
                        Text("\(filteredEntries.count)")
                            .bold()
                    }
                } header: { Text("Summary") }

                Section {
                    ForEach(categoryBreakdown, id: \.0.id) { cat, mins in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(cat.label, systemImage: cat.icon)
                                    .foregroundColor(cat.color)
                                Spacer()
                                Text(mins.durationString)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.secondary)
                                let pct = totalMinutes > 0 ? Int(Double(mins) / Double(totalMinutes) * 100) : 0
                                Text("\(pct)%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 36, alignment: .trailing)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(.systemFill))
                                        .frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(cat.color)
                                        .frame(width: totalMinutes > 0 ? geo.size.width * CGFloat(mins) / CGFloat(totalMinutes) : 0, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.vertical, 4)
                    }
                } header: { Text("By Category") }
            }
        }
        .listStyle(.sidebar)
    }
}
