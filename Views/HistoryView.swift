import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: RecipeStore
    var onGoHome: (() -> Void)? = nil
    @State private var selectedPizza: PizzaEntry? = nil
    @State private var shareContext: ShareLogContext? = nil

    /// Identifiable wrapper for fullScreenCover(item:) — pairs the log + recipe
    /// the user wants to share.
    struct ShareLogContext: Identifiable {
        let id: UUID    // = log.id
        let log: BakeLog
        let recipe: Recipe
    }

    var allLogs: [(BakeLog, Recipe)] {
        store.recipes
            .flatMap { recipe in recipe.bakeLogs.map { ($0, recipe) } }
            .sorted { $0.0.date > $1.0.date }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(allLogs, id: \.0.id) { log, recipe in
                    Section {
                        if log.pizzaEntries.isEmpty {
                            // Legacy / no per-pizza data — show session-level bake row
                            legacyBakeRow(log: log)
                        } else {
                            ForEach(log.pizzaEntries) { entry in
                                Button { selectedPizza = entry } label: {
                                    pizzaRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        NavigationLink(destination: BakeLogDetailView(log: log, recipe: recipe).environmentObject(store)) {
                            Text("View session log")
                                .font(.jakarta(.regular, size: 12))
                                .foregroundColor(Color(hex: "D2B96A"))
                        }

                        Button {
                            shareContext = ShareLogContext(id: log.id, log: log, recipe: recipe)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share this session →")
                            }
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(Color(hex: "D2B96A"))
                        }
                        .buttonStyle(.plain)
                    } header: {
                        sessionHeader(log: log, recipe: recipe)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let goHome = onGoHome {
                        Button { goHome() } label: {
                            Image(systemName: "house")
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if allLogs.isEmpty {
                    ContentUnavailableView(
                        "No bakes yet",
                        systemImage: "clock",
                        description: Text("Complete a session to see your history.")
                    )
                }
            }
        }
        .sheet(item: $selectedPizza) { pizza in
            // Look up the live entry by id across all recipes' bake logs;
            // write back through the store so Make main / reorder persists.
            PizzaDetailView(entry: Binding(
                get: {
                    for (log, _) in allLogs {
                        if let found = log.pizzaEntries.first(where: { $0.id == pizza.id }) {
                            return found
                        }
                    }
                    return pizza
                },
                set: { store.updatePizzaEntry($0) }
            ))
        }
        .fullScreenCover(item: $shareContext) { ctx in
            PhotoShareView(log: ctx.log, recipe: ctx.recipe, scope: .wholeSession)
        }
    }

    // MARK: - Section header

    func sessionHeader(log: BakeLog, recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(recipe.name)
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 2) {
                    let displayRating = log.annotatedRating ?? log.rating
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= displayRating ? "star.fill" : "star")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(log.annotatedRating != nil
                                ? Color(hex: "D2B96A").opacity(0.7)
                                : Color(hex: "D2B96A"))
                    }
                }
            }
            Text(log.date.formatted(date: .abbreviated, time: .omitted)
                 + "  ·  \(log.ballCount) balls  ·  \(Int(log.finalHydration * 100))%")
                .font(.jakarta(.regular, size: 11))
                .foregroundColor(.secondary)
        }
        .textCase(nil)
        .padding(.vertical, 2)
    }

    // MARK: - Pizza row (one per PizzaEntry)

    func pizzaRow(entry: PizzaEntry) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            Group {
                if let data = entry.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: "ECEAE3")
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary).font(.jakarta(.regular, size: 12)))
                }
            }
            .frame(width: 48, height: 48)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.loggedAt.formatted(date: .omitted, time: .shortened))
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.primary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(shortTime(entry.bakeTimeSeconds))
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.secondary)
                }
                Text(bakeSummary(entry))
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Bake #\(entry.pizzaNumber)")
                .font(.jakarta(.regular, size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Legacy row (sessions without per-pizza data)

    func legacyBakeRow(log: BakeLog) -> some View {
        HStack(spacing: 12) {
            Group {
                if let data = log.photoData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(hex: "ECEAE3")
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary).font(.jakarta(.regular, size: 12)))
                }
            }
            .frame(width: 48, height: 48)
            .clipped()
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(log.date.formatted(date: .omitted, time: .shortened))
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.primary)
                    if log.bakeTimeSeconds > 0 {
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(shortTime(log.bakeTimeSeconds))
                            .font(.jakarta(.regular, size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                Text("\(log.crustColor.rawValue) · \(log.bottomResult.rawValue) · \(log.topResult.rawValue)")
                    .font(.jakarta(.regular, size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    func bakeSummary(_ entry: PizzaEntry) -> String {
        "\(entry.crustColor.rawValue) · \(entry.bottomResult.rawValue) · \(entry.topResult.rawValue)"
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }
}
