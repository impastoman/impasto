import SwiftUI
import UserNotifications

struct LiveSessionView: View {
    @ObservedObject var vm: SessionViewModel
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPostBake = false
    @State private var showRecipeSheet = false
    @State private var showPizzaLog = false
    @State private var showEndBakingAlert = false
    @State private var showLeaveAlert = false
    @State private var showBackAlert = false
    @State private var showNextStepPreview = false
    @State private var showSessionNotepad = false
    @State private var sessionNotes: [UUID: String] = [:]
    @State private var alarmScheduled = false

    var recipe: Recipe { vm.recipe }

    // Next card helper
    var nextCard: ProcessCard? {
        let next = vm.currentIndex + 1
        guard vm.cards.indices.contains(next) else { return nil }
        return vm.cards[next]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8").ignoresSafeArea()

                if vm.isInBakeStep {
                    bakeStepView
                } else {
                    processView
                }
            }
            .navigationTitle("Live Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLeaveAlert = true
                    } label: {
                        Image(systemName: "house")
                    }
                    .foregroundColor(.secondary)
                    .confirmationDialog("Leave session?", isPresented: $showLeaveAlert, titleVisibility: .visible) {
                        Button("Leave Session") {
                            vm.isHidden = true
                            sessionManager.shouldReturnHome = true
                        }
                        if vm.isRunning {
                            Button("Pause & Leave Session") {
                                vm.pause()
                                vm.isHidden = true
                                sessionManager.shouldReturnHome = true
                            }
                        }
                        Button("End and Log") {
                            vm.stopBaking()
                            showPostBake = true
                        }
                        Button("End without Logging", role: .destructive) {
                            sessionManager.shouldReturnHome = true
                            sessionManager.end(vm)
                        }
                        Button("Go Back", role: .cancel) {}
                    }
                }
                // Pause only visible when running — no Start in toolbar
                if !vm.isInBakeStep && vm.isRunning {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Pause") { vm.pause() }
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear  { UIApplication.shared.isIdleTimerDisabled = true  }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .fullScreenCover(isPresented: $showPostBake) {
            PostBakeView(vm: vm, recipe: recipe)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showPizzaLog) {
            PizzaLogView(vm: vm, recipe: recipe) {
                vm.resetBakeTimer()
                vm.startBaking()
                showPizzaLog = false
            } onEndBake: {
                vm.stopBaking()
                showPizzaLog = false
                showPostBake = true
            }
            .environmentObject(store)
            .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showRecipeSheet) {
            NavigationStack {
                RecipeDetailView(recipe: recipe, isReadOnly: true)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showRecipeSheet = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSessionNotepad) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    TextEditor(text: $vm.sessionNote)
                        .font(.jakarta(.regular, size: 14))
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color(hex: "F0EDE4"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "D2B96A").opacity(0.4), lineWidth: 1)
                        )
                        .padding(12)
                }
                .background(Color(hex: "F5F1E8").ignoresSafeArea())
                .navigationTitle("Session Notes")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showSessionNotepad = false }
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            }
            .preferredColorScheme(.light)
        }
        .sheet(isPresented: $showNextStepPreview) {
            if let next = nextCard {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(next.title)
                                .font(.system(size: 32, design: .serif))
                                .foregroundColor(Color(hex: "2C2A24"))

                            if next.duration > 0 {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text(timeString(next.duration))
                                        .font(.jakarta(.regular, size: 15))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if !next.recipeNote.isEmpty {
                                Divider()
                                Text(next.recipeNote)
                                    .font(.jakarta(.regular, size: 14))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(28)
                    }
                    .background(Color(hex: "F5F1E8").ignoresSafeArea())
                    .navigationTitle("Up Next")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color(hex: "F5F1E8"), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Got it") { showNextStepPreview = false }
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                }
                .preferredColorScheme(.light)
            }
        }
        .onChange(of: sessionManager.sessions.count) { _, _ in
            if !sessionManager.sessions.contains(where: { $0 === vm }),
               !sessionManager.shouldReturnHome {
                dismiss()
            }
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            if isTrue { dismiss() }
        }
    }

    // MARK: - Process view

    var processView: some View {
        VStack(spacing: 0) {
            cardTabs.padding(.top, 8)

            // Icon row: recipe viewer + session notepad
            HStack {
                Button {
                    showRecipeSheet = true
                } label: {
                    Image(systemName: "doc.text")
                }
                .foregroundColor(.secondary)
                .padding(.leading, 16)
                .padding(.top, 6)

                Spacer()

                Button {
                    showSessionNotepad = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .foregroundColor(vm.sessionNote.isEmpty ? .secondary : Color(hex: "D2B96A"))
                .padding(.trailing, 16)
                .padding(.top, 6)
            }

            Spacer()
            timerBlock
            Spacer()
            noteField.padding(.horizontal).padding(.top, 4)

            // Up Next preview button
            if let next = nextCard {
                Button {
                    showNextStepPreview = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Up next:")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.secondary)
                        Text(next.title)
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(Color(hex: "D2B96A"))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
                .padding(.top, 10)
            }

            Spacer()
            actionRow.padding(.horizontal).padding(.bottom, 24)
        }
    }

    // MARK: - Card tabs

    var cardTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(vm.cards.enumerated()), id: \.element.id) { index, card in
                    let isCurrent = index == vm.currentIndex
                    let isDone    = index < vm.currentIndex
                    Text(card.title)
                        .font(.jakarta(.regular, size: 12))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isCurrent ? Color(hex: "D2B96A").opacity(0.12) : Color.clear)
                        .foregroundColor(isCurrent ? Color(hex: "D2B96A") : isDone ? Color(hex: "D2B96A").opacity(0.4) : .secondary)
                }
            }
        }
    }

    // MARK: - Timer

    var isCountdown: Bool {
        (vm.currentCard?.type.isTimed == true) &&
        vm.targetDuration > 0
    }

    var displayTime: TimeInterval {
        if isCountdown {
            if vm.elapsed > vm.targetDuration {
                return vm.elapsed - vm.targetDuration
            }
            return vm.targetDuration - vm.elapsed
        }
        return vm.elapsed
    }

    var timerBlock: some View {
        VStack(spacing: 6) {
            if let card = vm.currentCard {
                Text(card.title.uppercased())
                    .font(.jakarta(.regular, size: 10)).tracking(2).foregroundColor(.secondary)

                Text(timeString(displayTime))
                    .font(.system(size: 56, design: .serif))
                    .foregroundColor(vm.isOvertime ? Color.orange : Color(hex: "2C2A24"))
                    .onLongPressGesture(minimumDuration: 0.6) {
                        let gen = UIImpactFeedbackGenerator(style: .heavy)
                        gen.impactOccurred()
                        vm.resetTimer()
                    }

                if card.type.isTimed && vm.targetDuration > 0 {
                    ProgressView(value: vm.progress)
                        .tint(vm.isOvertime ? .orange : Color(hex: "D2B96A"))
                        .padding(.horizontal, 40)
                    HStack(spacing: 12) {
                        if vm.isOvertime {
                            Text("+\(timeString(vm.elapsed - vm.targetDuration)) overtime")
                                .font(.jakarta(.regular, size: 11)).foregroundColor(.orange)
                        } else {
                            Text(isCountdown ? "of \(timeString(vm.targetDuration))" : "Target: \(timeString(vm.targetDuration))")
                                .font(.jakarta(.regular, size: 11)).foregroundColor(.secondary)
                        }
                        // Set alarm bell
                        Button {
                            if alarmScheduled {
                                cancelAlarm()
                            } else {
                                scheduleStepAlarm()
                            }
                        } label: {
                            Image(systemName: alarmScheduled ? "bell.fill" : "bell")
                                .font(.system(size: 12))
                                .foregroundColor(alarmScheduled ? Color(hex: "D2B96A") : .secondary)
                        }
                    }
                }

                // Inline Start / Resume — shown whenever the timer is not running
                if !vm.isRunning {
                    Button {
                        vm.resume()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11))
                            Text(vm.elapsed > 0 ? "RESUME" : "START")
                                .font(.jakarta(.regular, size: 10))
                                .tracking(2)
                        }
                        .foregroundColor(Color(hex: "D2B96A"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "D2B96A"), lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
            }
        }
        .onChange(of: vm.currentIndex) { _, _ in alarmScheduled = false }
    }

    // MARK: - Note field

    @ViewBuilder
    var noteField: some View {
        if let card = vm.currentCard {
            VStack(alignment: .leading, spacing: 6) {
                if !card.recipeNote.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "note.text").font(.caption).foregroundColor(.secondary).padding(.top, 2)
                        Text(card.recipeNote)
                            .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                    }
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "pencil").font(.caption).foregroundColor(.secondary).padding(.top, 2)
                    TextField("Add a session note for this step…",
                              text: Binding(
                                get: { sessionNotes[card.id] ?? "" },
                                set: { sessionNotes[card.id] = $0.isEmpty ? nil : $0 }
                              ),
                              axis: .vertical)
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.primary)
                        .lineLimit(1...3)
                        .notesBox()
                }
            }
        }
    }

    // MARK: - Action row

    var actionRow: some View {
        HStack(spacing: 12) {
            if vm.currentIndex > 0 {
                let prevTitle = vm.cards[vm.currentIndex - 1].title
                Button("← Back") {
                    showBackAlert = true
                }
                .buttonStyle(StesuraButtonStyle(filled: false))
                .confirmationDialog(
                    "Go back to \(prevTitle)?",
                    isPresented: $showBackAlert,
                    titleVisibility: .visible
                ) {
                    Button("Go Back") { vm.goBack() }
                    Button("Stay Here", role: .cancel) {}
                } message: {
                    Text("Timer will resume where it left off. Going back again from there will reset that step's time.")
                }
            }

            if vm.isLastCard {
                LongPressStepButton(label: "Proceed to Bake →", filled: true) {
                    vm.enterBakeStep()
                }
            } else {
                let isTimedAuto = vm.preFlight.sessionMode == .automatic && vm.currentCard?.type.isActionOnly == false
                LongPressStepButton(label: isTimedAuto ? "Proceed →" : "Next Step →", filled: true) {
                    vm.completeCard()
                }
            }
        }
    }

    // MARK: - Bake step view

    var bakeStepView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("BAKE")
                    .font(.jakarta(.regular, size: 10)).tracking(2).foregroundColor(.secondary)

                if vm.bakingStarted {
                    Text(timeString(vm.bakeElapsed))
                        .font(.system(size: 56, design: .serif))
                        .foregroundColor(Color(hex: "2C2A24"))
                } else {
                    Text("Ready to launch")
                        .font(.jakarta(.regular, size: 18))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let setupId = vm.preFlight.selectedBakeSetupId,
               let setup = recipe.bakeSetups.first(where: { $0.id == setupId }) {
                HStack {
                    Text(setup.method.displayName)
                        .font(.jakarta(.regular, size: 14))
                        .foregroundColor(.secondary)
                    if !setup.subMethod.isEmpty {
                        Text("· \(setup.subMethod)")
                            .font(.jakarta(.regular, size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(setup.ovenTempDisplay)
                        .font(.jakarta(.regular, size: 14))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Spacer()

            bakeActionRow
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
    }

    var bakeActionRow: some View {
        VStack(spacing: 12) {
            if vm.bakingStarted {
                Button("Log Bake") {
                    vm.stopBaking()
                    showPizzaLog = true
                }
                .buttonStyle(StesuraButtonStyle(filled: false))

                Button("End Baking") {
                    showEndBakingAlert = true
                }
                .buttonStyle(StesuraButtonStyle(filled: true))
                .confirmationDialog("End baking?", isPresented: $showEndBakingAlert, titleVisibility: .visible) {
                    Button("End Baking", role: .destructive) {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        vm.stopBaking()
                        showPostBake = true
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Button("Start Baking") {
                    vm.startBaking()
                }
                .buttonStyle(StesuraButtonStyle(filled: true))
            }
        }
    }

    // MARK: - Helpers

    func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Alarm

    func scheduleStepAlarm() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let remaining = max(1, vm.targetDuration - vm.elapsed)
            let content = UNMutableNotificationContent()
            content.title = vm.currentCard?.title ?? "Step Complete"
            content.body = "\(vm.currentCard?.title ?? "Step") is done — next step up."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remaining, repeats: false)
            let request = UNNotificationRequest(identifier: "stesura_step_alarm", content: content, trigger: trigger)
            center.add(request) { _ in }
            DispatchQueue.main.async { alarmScheduled = true }
        }
    }

    func cancelAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["stesura_step_alarm"])
        alarmScheduled = false
    }
}

// MARK: - Long-press step advance button

private struct LongPressStepButton: View {
    let label: String
    let filled: Bool
    let action: () -> Void

    @State private var progress: Double = 0

    var body: some View {
        Text(label)
            .font(.jakarta(.regular, size: 14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(filled ? Color(hex: "D2B96A") : Color.clear)
            .foregroundColor(filled ? Color(hex: "111210") : Color(hex: "9A9688"))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(filled ? Color.clear : Color(hex: "4A4840"), lineWidth: 1)
            )
            .cornerRadius(6)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Color(hex: filled ? "FFFFFF" : "D2B96A")
                        .opacity(filled ? 0.28 : 0.35)
                        .frame(width: geo.size.width * progress)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        .onLongPressGesture(minimumDuration: 0.45, pressing: { isPressing in
            withAnimation(isPressing ? .linear(duration: 0.45) : .easeOut(duration: 0.15)) {
                progress = isPressing ? 1.0 : 0.0
            }
        }, perform: {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            withAnimation(.easeOut(duration: 0.15)) { progress = 0.0 }
            action()
        })
    }
}
