import SwiftUI

struct ExercisePictogram: View {
    let exerciseName: String

    var body: some View {
        Canvas { context, size in
            let definition = ExercisePictograms.definition(for: exerciseName)
            let scale = min(size.width, size.height) / 64
            context.scaleBy(x: scale, y: scale)

            if let thin = definition.thin {
                context.stroke(
                    SVGPathParser.path(thin),
                    with: .foreground,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
            }
            context.stroke(
                SVGPathParser.path(definition.strokes),
                with: .foreground,
                style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
            )
            for circle in definition.outlinedCircles {
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: circle.x - circle.radius,
                        y: circle.y - circle.radius,
                        width: circle.radius * 2,
                        height: circle.radius * 2
                    )),
                    with: .foreground,
                    lineWidth: 3
                )
            }
            for rectangle in definition.rectangles {
                context.stroke(
                    Path(roundedRect: rectangle.rect, cornerRadius: 2),
                    with: .foreground,
                    lineWidth: 3.5
                )
            }
            for circle in definition.filledCircles + [definition.head] {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: circle.x - circle.radius,
                        y: circle.y - circle.radius,
                        width: circle.radius * 2,
                        height: circle.radius * 2
                    )),
                    with: .foreground
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PictoCircle {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
}

private struct PictoRectangle {
    let rect: CGRect
}

private struct PictoDefinition {
    let head: PictoCircle
    let strokes: String
    var thin: String? = nil
    var filledCircles: [PictoCircle] = []
    var outlinedCircles: [PictoCircle] = []
    var rectangles: [PictoRectangle] = []
}

private enum ExercisePictograms {
    static let definitions: [String: PictoDefinition] = [
        "burpee": .init(head: c(45,10,5.5), strokes:"M45 16 L45 34 M45 21 L34 9 M45 21 L56 9 M45 34 L40 50 M45 34 L50 50 M5 55 L19 49 L20 56", thin:"M38 55 L52 55 M2 59 L62 59", filledCircles:[c(23,46,3.5)]),
        "muscleup": .init(head:c(32,8,5.5), strokes:"M32 14 L32 30 M32 18 L22 22 L22 30 M32 18 L42 22 L42 30 M32 30 L29 44 L32 56", thin:"M8 30 L56 30"),
        "traction": .init(head:c(32,8,5.5), strokes:"M32 15 L32 35 M32 19 L22 23 L21 14 M32 19 L42 23 L43 14 M32 35 L29 48 L33 58", thin:"M8 14 L56 14"),
        "suspension": .init(head:c(32,19,5.5), strokes:"M27 8 L29 24 M37 8 L35 24 M32 25 L32 42 L54 42", thin:"M10 8 L54 8"),
        "box": .init(head:c(20,10,5.5), strokes:"M21 16 L25 33 M22 20 L11 27 M25 33 L35 28 L41 39 M25 33 L31 38 L37 40", rectangles:[r(36,41,24,17)]),
        "corde": .init(head:c(32,10,5.5), strokes:"M32 16 L32 36 M32 20 L22 30 L18 33 M32 20 L42 30 L46 33 M32 36 L29 53 M32 36 L35 53", thin:"M18 33 C10 70 54 70 46 33"),
        "battlerope": .init(head:c(14,14,5.5), strokes:"M15 20 L13 36 M15 24 L28 30 M13 36 L22 44 L20 57 M13 36 L8 46 L9 57", thin:"M28 30 C32 20 36 40 41 30 C45 20 49 40 54 30 C56 26 58 28 60 30 M4 59 L60 59"),
        "swing": .init(head:c(21,11,5.5), strokes:"M22 18 L25 37 L27 47 L25 57 M23 23 L43 27", thin:"M44 20 C38 30 40 40 47 45 M8 60 L56 60", filledCircles:[c(49,30,6.5)], outlinedCircles:[c(49,23,3.5)]),
        "thruster": .init(head:c(32,16,5.5), strokes:"M32 22 L32 40 M32 25 L23 17 L23 7 M32 25 L41 17 L41 7 M32 40 L22 46 L24 58 M32 40 L42 46 L40 58 M12 7 L52 7", filledCircles:[c(11,7,5),c(53,7,5)]),
        "epaule": .init(head:c(32,9,5.5), strokes:"M32 15 L32 35 M32 19 L22 26 L22 20 M32 19 L42 26 L42 20 M32 35 L26 46 L27 58 M32 35 L38 46 L37 58 M10 20 L54 20", thin:"M58 42 L58 30 M54 34 L58 30 L62 34", filledCircles:[c(9,20,5),c(55,20,5)]),
        "deadlift": .init(head:c(44,21,5.5), strokes:"M38 26 L20 32 M36 28 L36 48 M20 32 L28 43 L24 57", thin:"M6 59 L58 59", filledCircles:[c(36,51,7)]),
        "pompe": .init(head:c(51,27,5.5), strokes:"M7 50 L44 32 M43 33 L44 51", thin:"M4 55 L60 55"),
        "developpe": .init(head:c(32,17,5.5), strokes:"M32 23 L32 42 M32 26 L22 19 L22 7 M32 26 L42 19 L42 7 M32 42 L28 58 M32 42 L36 58 M16 7 L28 7 M36 7 L48 7"),
        "tirage": .init(head:c(45,20,5.5), strokes:"M39 25 L19 31 M37 27 L29 30 L32 39 M19 31 L25 43 L21 57 M27 39 L37 39", thin:"M6 59 L58 59"),
        "curl": .init(head:c(32,10,5.5), strokes:"M32 16 L32 36 M32 20 L23 33 L18 24 M32 20 L41 33 L46 24 M32 36 L28 57 M32 36 L36 57 M13 23 L23 25 M41 25 L51 23"),
        "fente": .init(head:c(30,10,5.5), strokes:"M30 16 L30 34 M30 20 L37 27 L31 31 M30 34 L44 40 L44 56 M30 34 L21 50 L9 53", thin:"M4 58 L58 58"),
        "squat": .init(head:c(29,12,5.5), strokes:"M27 19 L22 37 L38 39 L35 55 L43 55 M26 24 L46 26", thin:"M10 59 L54 59"),
        "pont": .init(head:c(9,48,5.5), strokes:"M15 51 L32 39 L44 33 L50 52 M15 52 L28 55", thin:"M2 57 L60 57"),
        "mollets": .init(head:c(28,10,5.5), strokes:"M28 16 L28 37 M28 20 L22 34 M28 20 L34 34 M28 37 L26 53 M28 37 L30 53 M24 54 L33 56", thin:"M48 48 L48 26 M42 32 L48 26 L54 32 M14 59 L44 59"),
        "planche": .init(head:c(50,31,5.5), strokes:"M6 51 L42 36 L42 52 L54 52", thin:"M2 56 L62 56"),
        "mountain": .init(head:c(51,25,5.5), strokes:"M44 30 L24 38 L6 51 M24 38 L37 42 L33 52 M44 30 L46 52", thin:"M2 56 L62 56"),
        "jack": .init(head:c(32,10,5.5), strokes:"M32 16 L32 36 M32 20 L18 7 M32 20 L46 7 M32 36 L19 57 M32 36 L45 57"),
        "saut": .init(head:c(30,10,5.5), strokes:"M31 16 L32 32 M31 20 L21 27 M31 20 L42 22 M32 32 L44 30 L40 42 M32 32 L42 37 L36 46", thin:"M18 54 C26 60 40 60 48 54 M8 59 L56 59"),
        "course": .init(head:c(38,10,5.5), strokes:"M35 17 L28 34 M35 20 L43 27 L49 21 M35 20 L26 25 L21 32 M28 34 L40 40 L38 52 M28 34 L22 46 L10 48", thin:"M4 57 L60 57"),
        "abdos": .init(head:c(30,22,5.5), strokes:"M21 52 L28 30 M27 33 L39 37 M21 52 L37 38 L50 53", thin:"M4 57 L60 57"),
        "velo": .init(head:c(42,12,5.5), strokes:"M38 18 L26 30 M37 20 L45 29 M26 30 L36 38 L30 47", thin:"M15 48 L28 48 L42 31 L24 31 L28 48 M42 31 L49 48 M42 31 L45 28", outlinedCircles:[c(15,48,9),c(49,48,9)]),
        "rameur": .init(head:c(15,24,5.5), strokes:"M17 30 L24 48 M18 33 L31 38 M24 48 L44 49", thin:"M31 38 L48 42 M4 55 L60 55", outlinedCircles:[c(54,44,6)]),
        "traineau": .init(head:c(37,17,5.5), strokes:"M32 23 L18 34 M31 25 L44 28 M18 34 L24 46 L18 57 M18 34 L10 44 L4 53 M44 28 L46 40", thin:"M2 59 L62 59", rectangles:[r(42,42,18,12)]),
        "porte": .init(head:c(32,10,5.5), strokes:"M32 16 L32 36 M32 20 L21 39 M32 20 L43 39 M32 36 L28 57 M32 36 L36 57", filledCircles:[c(20,45,5),c(44,45,5)], outlinedCircles:[c(20,39,3),c(44,39,3)]),
        "boxe": .init(head:c(28,12,5.5), strokes:"M28 18 L26 36 M28 22 L41 22 L51 20 M28 22 L31 30 L36 23 M26 36 L37 56 M26 36 L15 56", thin:"M4 59 L60 59", filledCircles:[c(54,20,4),c(38,22,4)]),
        "defaut": .init(head:c(32,12,5.5), strokes:"M32 18 L32 38 M32 22 L21 32 M32 22 L43 32 M32 38 L25 56 M32 38 L39 56")
    ]

    static let rules: [(String, String)] = [
        ("burpee","burpee|down up|sprawl|man maker|devil press"),("muscleup","muscle up"),
        ("suspension","toes to bar|knees to elbow|hanging|dead hang"),("traction","pull up|chin up|ring row|trx row|pulldown|traction"),
        ("corde","jump rope|unders|corde a sauter"),("battlerope","battle rope"),("box","\\bbox\\b"),("swing","swing"),
        ("thruster","thruster|wall ball"),("epaule","clean|snatch|jerk|high pull|ground to overhead|over shoulder"),
        ("deadlift","deadlift|good morning"),("porte","carry"),("mountain","mountain climber"),
        ("planche","plank|bear|crab|inchworm|wall walk|ab wheel|planche|gainage"),
        ("pompe","push up|pompe|chest press|bench press|floor press|\\bfly\\b|\\bdips\\b|chest pass"),
        ("mollets","calf"),("abdos","sit up|crunch|twist|v ups|tuck ups|leg raises|flutter|scissor|hollow|toe touch|heel tap|dead bug|woodchopper|superman|bird dog|rotational throw|abdo|releve de buste"),
        ("fente","lunge|fente|split squat|step up|step over|curtsy"),("squat","squat|wall sit|leg press"),
        ("pont","glute bridge|hip thrust|pont fessier"),("curl","curl|tricep|leg extension"),
        ("tirage","\\brow\\b|face pull|pull apart|pullover"),("developpe","press|raise|halo|around the world|figure 8|windmill|get up|slam"),
        ("jack","\\bjack|star jump"),("saut","jump|skater|broad|frog|saut"),("velo","bike|elliptical|versaclimber|velo"),
        ("rameur","rower|ski erg|rameur"),("traineau","sled|plate push|tire flip"),
        ("course","\\brun\\b|sprint|knees|butt kick|fast feet|shuffle|ladder|treadmill|stair|walk|course|genoux|talons fesses"),
        ("boxe","boxing|boxe")
    ]

    static func definition(for name: String) -> PictoDefinition {
        let normalized = ExerciseSearch.normalize(name)
        let key = rules.first { _, pattern in
            normalized.range(of: pattern, options: .regularExpression) != nil
        }?.0 ?? "defaut"
        return definitions[key] ?? definitions["defaut"]!
    }

    private static func c(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) -> PictoCircle {
        PictoCircle(x: x, y: y, radius: radius)
    }

    private static func r(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> PictoRectangle {
        PictoRectangle(rect: CGRect(x: x, y: y, width: width, height: height))
    }
}

private enum SVGPathParser {
    static func path(_ source: String) -> Path {
        let expression = try! NSRegularExpression(
            pattern: "[MLC]|-?[0-9]+(?:\\.[0-9]+)?"
        )
        let range = NSRange(source.startIndex..., in: source)
        let tokens = expression.matches(in: source, range: range).compactMap {
            Range($0.range, in: source).map { String(source[$0]) }
        }
        var path = Path()
        var index = 0
        var command = ""

        func number(at offset: Int) -> CGFloat {
            CGFloat(Double(tokens[index + offset]) ?? 0)
        }

        while index < tokens.count {
            if ["M", "L", "C"].contains(tokens[index]) {
                command = tokens[index]
                index += 1
            }
            switch command {
            case "M":
                guard index + 1 < tokens.count else { return path }
                path.move(to: CGPoint(x: number(at: 0), y: number(at: 1)))
                index += 2
            case "L":
                guard index + 1 < tokens.count else { return path }
                path.addLine(to: CGPoint(x: number(at: 0), y: number(at: 1)))
                index += 2
            case "C":
                guard index + 5 < tokens.count else { return path }
                path.addCurve(
                    to: CGPoint(x: number(at: 4), y: number(at: 5)),
                    control1: CGPoint(x: number(at: 0), y: number(at: 1)),
                    control2: CGPoint(x: number(at: 2), y: number(at: 3))
                )
                index += 6
            default:
                index += 1
            }
        }
        return path
    }
}
