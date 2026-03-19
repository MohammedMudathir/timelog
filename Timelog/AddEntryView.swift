import SwiftUI
import CoreData

struct CategoryPicker: View {
    @Binding var selected: Category
    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
            ForEach(Category.allCases) { cat in
                Button(action: { selected = cat }) {
                    Label(cat.label, systemImage: cat.icon)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected == cat ? cat.color.opacity(0.2) : Color.secondary.opacity(0.1))
                        .foregroundColor(selected == cat ? cat.color : .secondary)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected == cat ? cat.color : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TimeSection: View {
    @Binding var date: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    var duration: Int
    var color: Color
    var body: some View {
        VStack(spacing: 8) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
            if duration > 0 {
                HStack {
                    Text("Duration").foregroundColor(.secondary)
                    Spacer()
                    Text(duration.durationString).foregroundColor(color).bold()
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddEntryView: View {
    let defaultDate: Date
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var activity = ""
    @State private var category: Category = .work
    @State private var notes = ""

    init(defaultDate: Date) {
        self.defaultDate = defaultDate
        let now = Date()
        _date = State(initialValue: defaultDate)
        _startTime = State(initialValue: now)
        _endTime = State(initialValue: Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now)
    }

    var duration: Int { minutesBetween(startTime, endTime) }
    var isValid: Bool { !activity.trimmingCharacters(in: .whitespaces).isEmpty && endTime > startTime }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity").font(.caption).foregroundColor(.secondary)
                        TextField("What were you doing?", text: $activity)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(.caption).foregroundColor(.secondary)
                        CategoryPicker(selected: $category)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date & Time").font(.caption).foregroundColor(.secondary)
                        TimeSection(date: $date, startTime: $startTime, endTime: $endTime, duration: duration, color: category.color)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)").font(.caption).foregroundColor(.secondary)
                        TextField("Any notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3, reservesSpace: true)
                    }
                    Button(action: save) {
                        Text("Save Entry").frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                }
                .padding(20)
            }
            .navigationTitle("Log Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    func save() {
        let entry = ActivityEntry(context: viewContext)
        entry.id = UUID()
        entry.createdAt = Date()
        entry.activity = activity.trimmingCharacters(in: .whitespaces)
        entry.category = category.rawValue
        entry.notes = notes.trimmingCharacters(in: .whitespaces)
        let cal = Calendar.current
        let dc = cal.dateComponents([.year, .month, .day], from: date)
        let sc = cal.dateComponents([.hour, .minute], from: startTime)
        let ec = cal.dateComponents([.hour, .minute], from: endTime)
        var s = DateComponents(); s.year = dc.year; s.month = dc.month; s.day = dc.day; s.hour = sc.hour; s.minute = sc.minute
        var e = DateComponents(); e.year = dc.year; e.month = dc.month; e.day = dc.day; e.hour = ec.hour; e.minute = ec.minute
        entry.startTime = cal.date(from: s) ?? startTime
        entry.endTime = cal.date(from: e) ?? endTime
        entry.date = cal.startOfDay(for: date)
        try? viewContext.save()
        dismiss()
    }
}

struct EditEntryView: View {
    @ObservedObject var entry: ActivityEntry
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var activity: String
    @State private var category: Category
    @State private var notes: String

    init(entry: ActivityEntry) {
        self.entry = entry
        _date = State(initialValue: entry.date ?? Date())
        _startTime = State(initialValue: entry.startTime ?? Date())
        _endTime = State(initialValue: entry.endTime ?? Date())
        _activity = State(initialValue: entry.activity ?? "")
        _category = State(initialValue: Category.from(entry.category ?? "other"))
        _notes = State(initialValue: entry.notes ?? "")
    }

    var duration: Int { minutesBetween(startTime, endTime) }
    var isValid: Bool { !activity.trimmingCharacters(in: .whitespaces).isEmpty && endTime > startTime }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity").font(.caption).foregroundColor(.secondary)
                        TextField("What were you doing?", text: $activity)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category").font(.caption).foregroundColor(.secondary)
                        CategoryPicker(selected: $category)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date & Time").font(.caption).foregroundColor(.secondary)
                        TimeSection(date: $date, startTime: $startTime, endTime: $endTime, duration: duration, color: category.color)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes (optional)").font(.caption).foregroundColor(.secondary)
                        TextField("Any notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3, reservesSpace: true)
                    }
                    Button(action: save) {
                        Text("Save Changes").frame(maxWidth: .infinity).padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValid)
                }
                .padding(20)
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    func save() {
        let cal = Calendar.current
        let dc = cal.dateComponents([.year, .month, .day], from: date)
        let sc = cal.dateComponents([.hour, .minute], from: startTime)
        let ec = cal.dateComponents([.hour, .minute], from: endTime)
        var s = DateComponents(); s.year = dc.year; s.month = dc.month; s.day = dc.day; s.hour = sc.hour; s.minute = sc.minute
        var e = DateComponents(); e.year = dc.year; e.month = dc.month; e.day = dc.day; e.hour = ec.hour; e.minute = ec.minute
        entry.startTime = cal.date(from: s) ?? startTime
        entry.endTime = cal.date(from: e) ?? endTime
        entry.date = cal.startOfDay(for: date)
        entry.activity = activity.trimmingCharacters(in: .whitespaces)
        entry.category = category.rawValue
        entry.notes = notes.trimmingCharacters(in: .whitespaces)
        try? viewContext.save()
        dismiss()
    }
}
