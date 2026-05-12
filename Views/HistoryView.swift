import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: RecipeStore
    var onGoHome: (() -> Void)? = nil

    var allLogs: [(BakeLog, Recipe)] {
        store.recipes
            .flatMap { recipe in recipe.bakeLogs.map { ($0, recipe) } }
            .sorted { $0.0.date > $1.0.date }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(allLogs, id: \.0.id) { log, recipe in
                    NavigationLink(destination: BakeLogDetailView(log: log, recipe: recipe).environmentObject(store)) {
                        logRow(log: log, recipe: recipe)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let goHome = onGoHome {
                        Button("⌂ Home") { goHome() }
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if allLogs.isEmpty {
                    ContentUnavailableView("No bakes yet", systemImage: "clock", description: Text("Complete a session to see your history."))
                }
            }
        }
    }

    func logRow(log: BakeLog, recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(recipe.name).font(.headline)
                Spacer()
                HStack(spacing: 2) {
                    let displayRating = log.annotatedRating ?? log.rating
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= displayRating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(log.annotatedRating != nil ? Color(hex: "D2B96A").opacity(0.7) : Color(hex: "D2B96A"))
                    }
                    if log.annotatedRating != nil {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Text(log.date.formatted(date: .abbreviated, time: .omitted)
                 + " · \(log.ballCount) balls · \(Int(log.finalHydration * 100))% hydration")
                .font(.caption)
                .foregroundColor(.secondary)
            if !log.crustTags.isEmpty || !log.crumbTags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(log.crustTags, id: \.self) { tag in
                        Text(tag.rawValue).font(.caption2).foregroundColor(.secondary)
                    }
                    ForEach(log.crumbTags, id: \.self) { tag in
                        Text(tag.rawValue).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
