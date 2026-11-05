import SwiftUI

struct SetupView: View {
    @Bindable var store: WorkoutStore
    let start: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Spacer()
                    Button(store.appearance == .dark ? "☀️" : "🌙") {
                        store.appearance = store.appearance == .dark ? .light : .dark
                    }
                    .font(.title2)
                    .accessibilityLabel("Mode sombre")
                }

                Text("Compteur HiiT")
                    .font(HIITTypography.display(.largeTitle, weight: .heavy))
                VStack(spacing: 2) {
                    Text("DURÉE TOTALE").font(.caption.weight(.semibold))
                    Text(WorkoutDurationFormatter.short(
                        WorkoutPlanBuilder.totalDuration(for: store.configuration)
                    ))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(HIITTheme.red)
                }

                Picker("Type de séance", selection: $store.configuration.mode) {
                    Text("EMOM").tag(WorkoutMode.emom)
                    Text("AMRAP").tag(WorkoutMode.amrap)
                }
                .pickerStyle(.segmented)

                PhaseEditor(
                    title: "Échauffement",
                    color: HIITTheme.green,
                    enabled: $store.configuration.warmup.isEnabled,
                    minutes: $store.configuration.warmup.minutes,
                    range: 1...15,
                    exercises: $store.configuration.warmup.exercises,
                    store: store
                )

                if store.configuration.mode == .emom {
                    EMOMEditor(store: store)
                } else {
                    PhaseEditor(
                        title: "AMRAP · max de tours",
                        color: HIITTheme.red,
                        enabled: .constant(true),
                        minutes: $store.configuration.amrap.minutes,
                        range: 1...60,
                        exercises: $store.configuration.amrap.exercises,
                        store: store,
                        canDisable: false
                    )
                }

                PhaseEditor(
                    title: "Finisher",
                    color: HIITTheme.violet,
                    enabled: $store.configuration.finisher.isEnabled,
                    minutes: $store.configuration.finisher.repetitionExerciseMinutes,
                    range: 1...5,
                    exercises: $store.configuration.finisher.exercises,
                    store: store,
                    addedExerciseRepetitions: nil
                )

                SectionCard {
                    Toggle(
                        "Annonces vocales (exercice + répétitions)",
                        isOn: $store.configuration.voiceAnnouncementsEnabled
                    )
                    Text("Garde l’écran allumé pendant la séance. Le mode silencieux peut couper les bips.")
                        .font(.caption)
                        .foregroundStyle(HIITTheme.muted)
                }

                Button("DÉMARRER", action: start)
                    .buttonStyle(PrimaryButtonStyle(color: HIITTheme.red))

                Button("Remettre la séance d’origine") {
                    store.resetConfiguration()
                }
                .foregroundStyle(HIITTheme.muted)
                .font(.footnote)
            }
            .frame(maxWidth: 560)
            .padding()
        }
        .background(HIITTheme.background)
    }
}

struct EMOMEditor: View {
    @Bindable var store: WorkoutStore

    var body: some View {
        SectionCard {
            Text("EMOM · 1 exercice par minute")
                .font(.title2.bold())
            Stepper(
                "Nombre de rounds : \(store.configuration.emomRounds)",
                value: $store.configuration.emomRounds,
                in: 1...20
            )
            ExerciseListEditor(
                exercises: $store.configuration.emomExercises,
                store: store
            )
        }
    }
}

struct PhaseEditor: View {
    let title: String
    let color: Color
    @Binding var enabled: Bool
    @Binding var minutes: Int
    let range: ClosedRange<Int>
    @Binding var exercises: [Exercise]
    let store: WorkoutStore
    var canDisable = true
    var addedExerciseRepetitions: Int? = 10

    var body: some View {
        SectionCard {
            HStack {
                Text(title).font(.title2.bold())
                Spacer()
                if canDisable {
                    Toggle("Activé", isOn: $enabled).labelsHidden()
                }
            }
            if enabled {
                Stepper("Durée : \(minutes) min", value: $minutes, in: range)
                ExerciseListEditor(
                    exercises: $exercises,
                    store: store,
                    addedExerciseRepetitions: addedExerciseRepetitions
                )
            }
        }
    }
}

struct ExerciseListEditor: View {
    @Binding var exercises: [Exercise]
    let store: WorkoutStore
    var addedExerciseRepetitions: Int? = 10

    var body: some View {
        ForEach($exercises) { $exercise in
            ExerciseEditorRow(
                exercise: $exercise,
                customNames: store.customExerciseNames,
                remember: store.rememberExercise,
                forget: store.forgetExercise,
                delete: {
                    guard exercises.count > 1,
                          let index = exercises.firstIndex(where: { $0.id == exercise.id })
                    else { return }
                    exercises.remove(at: index)
                }
            )
        }
        Button("Ajouter un exercice") {
            exercises.append(
                Exercise(name: "", repetitions: addedExerciseRepetitions)
            )
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseEditorRow: View {
    @Binding var exercise: Exercise
    let customNames: [String]
    let remember: (String) -> Void
    let forget: (String) -> Void
    let delete: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                ExercisePictogram(exerciseName: exercise.name)
                    .foregroundStyle(HIITTheme.red)
                    .frame(width: 32, height: 32)
                TextField("Exercice", text: $exercise.name)
                    .focused($isFocused)
                    .onSubmit { remember(exercise.name) }
                TextField(
                    exercise.unit == .repetitions ? "–" : "60",
                    value: $exercise.value,
                    format: .number
                )
                .frame(width: 48)
                .multilineTextAlignment(.center)
                Button(unitLabel) { exercise.cycleUnit() }
                    .buttonStyle(.bordered)
                Button(role: .destructive, action: delete) {
                    Image(systemName: "xmark")
                }
            }
            if isFocused {
                let results = ExerciseSearch.suggestions(
                    for: exercise.name,
                    customNames: customNames
                )
                ForEach(results, id: \.name) { result in
                    HStack {
                        Button {
                            exercise.name = result.name
                            isFocused = false
                        } label: {
                            HStack {
                                Text(result.name)
                                Spacer()
                                Text(result.category).font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        if result.isCustom {
                            Button {
                                forget(result.name)
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("Oublier \(result.name)")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { remember(exercise.name) }
        }
    }

    private var unitLabel: String {
        switch exercise.unit {
        case .repetitions: "rép"
        case .seconds: "sec"
        case .minutes: "min"
        }
    }
}

struct SectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .background(HIITTheme.board)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(HIITTheme.line)
            }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HIITTypography.display(.title, weight: .heavy))
            .frame(maxWidth: .infinity, minHeight: 68)
            .foregroundStyle(.white)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
