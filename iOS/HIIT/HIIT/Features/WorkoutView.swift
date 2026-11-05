import SwiftUI

struct WorkoutView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 12) {
            WorkoutHeader(session: session)
            WorkoutProgressStrip(session: session)
            Spacer()
            WorkoutStage(session: session)
            Spacer()
            WorkoutControls(session: session)
        }
        .padding()
        .background(HIITTheme.background)
    }
}

struct WorkoutHeader: View {
    let session: WorkoutSession

    var body: some View {
        HStack {
            Text(phaseTitle).font(.title2.bold())
            Spacer()
            Text(
                "\(WorkoutDurationFormatter.clock(Int(session.elapsedSeconds))) / \(WorkoutDurationFormatter.clock(session.plan.totalDuration))"
            )
            .foregroundStyle(HIITTheme.muted)
            .monospacedDigit()
        }
    }

    private var phaseTitle: String {
        let segment = session.currentSegment
        return switch segment.kind {
        case .warmup: "Échauffement"
        case .amrap: "AMRAP \(session.configuration.amrap.minutes) min"
        case .emom: "Tour \(segment.round ?? 1) sur \(session.configuration.emomRounds)"
        case .finisher:
            "Finisher \((segment.exerciseIndex ?? 0) + 1) sur \(session.configuration.finisher.exercises.count)"
        }
    }
}

struct WorkoutProgressStrip: View {
    let session: WorkoutSession

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 3) {
                ForEach(session.plan.segments) { segment in
                    Capsule()
                        .fill(color(for: segment))
                        .frame(
                            width: max(
                                2,
                                proxy.size.width
                                    * CGFloat(segment.duration)
                                    / CGFloat(session.plan.totalDuration)
                            )
                        )
                }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private func color(for segment: WorkoutSegment) -> Color {
        if segment.id < session.currentSegmentIndex { return HIITTheme.ink }
        if segment.id > session.currentSegmentIndex { return HIITTheme.line }
        switch segment.kind {
        case .warmup: return HIITTheme.green
        case .finisher: return HIITTheme.violet
        case .amrap: return HIITTheme.red
        case .emom: return HIITTheme.exerciseColor(segment.exerciseIndex ?? 0)
        }
    }
}

struct WorkoutStage: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if session.currentSegment.kind == .warmup {
                ForEach(session.configuration.warmup.exercises) { exercise in
                    ExerciseLine(exercise: exercise, color: HIITTheme.green)
                }
            } else if session.currentSegment.kind == .amrap {
                ForEach(session.configuration.amrap.exercises.enumerated(), id: \.element.id) { index, exercise in
                    ExerciseLine(exercise: exercise, color: HIITTheme.exerciseColor(index))
                }
                HStack {
                    Button("−") { session.removeAMRAPRound() }
                    Spacer()
                    VStack {
                        Text("\(session.amrapRounds)").font(.system(size: 52, weight: .heavy))
                        Text("tours").font(.caption)
                    }
                    Spacer()
                    Button("+1 TOUR") { session.addAMRAPRound() }
                        .buttonStyle(.borderedProminent)
                        .tint(HIITTheme.red)
                }
                .font(.title)
            } else if let exercise = session.currentSegment.exercise {
                ExercisePictogram(exerciseName: exercise.name)
                    .foregroundStyle(stageColor)
                    .frame(width: 112, height: 112)
                Text(exercise.name.isEmpty ? "Exercice" : exercise.name)
                    .font(HIITTypography.display(size: 64, weight: .heavy))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(stageColor)
                Text(exercise.repetitions.map { "× \($0) répétitions" }
                     ?? WorkoutDurationFormatter.short(session.currentSegment.duration))
                    .font(.title.bold())
            }

            Text(WorkoutDurationFormatter.clock(session.remainingSeconds))
                .font(HIITTypography.display(size: 104, weight: .heavy))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
            GeometryReader { proxy in
                Capsule().fill(HIITTheme.line)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(stageColor)
                            .frame(width: proxy.size.width * session.progress)
                    }
                    .clipShape(Capsule())
            }
            .frame(height: 10)
            Text(session.nextDescription)
                .font(HIITTypography.text(.body))
                .foregroundStyle(HIITTheme.muted)
                .frame(minHeight: 26)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stageColor: Color {
        switch session.currentSegment.kind {
        case .warmup: HIITTheme.green
        case .finisher: HIITTheme.violet
        case .amrap: HIITTheme.red
        case .emom: HIITTheme.exerciseColor(session.currentSegment.exerciseIndex ?? 0)
        }
    }
}

struct ExerciseLine: View {
    let exercise: Exercise
    let color: Color

    var body: some View {
        HStack {
            Text(exercise.name.isEmpty ? "Exercice" : exercise.name)
            Spacer()
            Text(exercise.repetitions.map(String.init) ?? WorkoutDurationFormatter.short(exercise.duration(fallbackForRepetitions: 60)))
                .foregroundStyle(HIITTheme.ink)
        }
        .font(.title.bold())
        .foregroundStyle(color)
    }
}

struct WorkoutControls: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 10) {
            WorkoutTransportControls(session: session)
            StopWorkoutButton(
                isArmed: session.isStopArmed,
                action: session.requestStop
            )
        }
    }
}

struct WorkoutTransportControls: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 10) {
            Button(action: session.goBack) {
                Text("◀ Retour")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(HIITTheme.ink)
                    .background(HIITTheme.line)
                    .clipShape(Capsule())
            }

            Button(action: session.togglePause) {
                Text(session.isPaused ? "REPRENDRE" : "PAUSE")
                    .font(HIITTypography.display(.title3, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(Color.white)
                    .background(HIITTheme.ink)
                    .clipShape(Capsule())
            }

            Button(action: session.skip) {
                Text("Passer ▶")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(HIITTheme.ink)
                    .background(HIITTheme.line)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

struct StopWorkoutButton: View {
    let isArmed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isArmed ? HIITTheme.red : HIITTheme.background)
                RoundedRectangle(cornerRadius: 14)
                    .stroke(HIITTheme.red, lineWidth: 2)
                Text(isArmed ? "CONFIRMER L’ARRÊT ?" : "■ ARRÊTER LA SÉANCE")
                    .font(HIITTypography.display(.title2, weight: .heavy))
                    .foregroundStyle(isArmed ? Color.white : HIITTheme.red)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.plain)
    }
}

struct CompletionView: View {
    let session: WorkoutSession
    let back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Séance terminée")
                .font(HIITTypography.display(size: 72, weight: .heavy))
                .foregroundStyle(HIITTheme.green)
            Text(summary)
                .foregroundStyle(HIITTheme.muted)
            Button("RETOUR", action: back)
                .buttonStyle(PrimaryButtonStyle(color: HIITTheme.ink))
        }
        .padding()
        .background(HIITTheme.background)
    }

    private var summary: String {
        let tours = "\(session.amrapRounds) \(session.amrapRounds > 1 ? "tours" : "tour")"
        let main = session.configuration.mode == .amrap
            ? "AMRAP \(session.configuration.amrap.minutes) min : \(tours)"
            : "\(session.configuration.emomRounds) tours d’EMOM"
        return "Durée : \(WorkoutDurationFormatter.clock(session.plan.totalDuration)) · \(main)"
            + (session.configuration.finisher.isEnabled ? " + finisher." : ".")
    }
}
