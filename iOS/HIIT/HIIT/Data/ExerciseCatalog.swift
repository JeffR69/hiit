import Foundation

struct ExerciseCatalogEntry: Equatable, Sendable {
    let name: String
    let category: String
    let isCustom: Bool
}

enum ExerciseCatalog {
    static let categories: [(name: String, exercises: String)] = [
        ("Poids du corps", "Squat|Air squat|Squat jump|Sumo squat|Pistol squat|Wall sit|Lunges|Walking lunges|Reverse lunges|Jumping lunges|Lateral lunges|Curtsy lunges|Bulgarian split squat|Glute bridge|Single leg glute bridge|Calf raises|Burpees|Burpee broad jump|Down up|Sprawl|Push up|Wide push up|Diamond push up|Pike push up|Hand release push up|Decline push up|Handstand push up|Bench dips|Plank|Side plank|Plank jack|Plank shoulder taps|Plank up down|Bear crawl|Bear plank|Crab walk|Inchworm|Mountain climber|Cross body mountain climber|Jumping jack|Star jump|Seal jack|Skater jumps|Tuck jumps|Broad jump|Frog jumps|High knees|Butt kicks|Fast feet|Lateral shuffle|Sit up|Crunches|Bicycle crunches|Russian twist|V ups|Tuck ups|Leg raises|Flutter kicks|Scissor kicks|Hollow hold|Hollow rocks|Superman|Dead bug|Bird dog|Toe touches|Heel taps|Shadow boxing|Sprint|Run|Shuttle run|Agility ladder"),
        ("Barre de traction", "Pull up|Chin up|Kipping pull up|Chest to bar pull up|Burpee pull up|Toes to bar|Knees to elbow|Hanging knee raises|Hanging leg raises|Dead hang|Bar muscle up"),
        ("Box", "Box jump|Box jump over|Burpee box jump over|Step up|Box step over|Lateral box jump"),
        ("Corde à sauter", "Jump rope|Single unders|Double unders|Jump rope high knees"),
        ("Kettlebell", "Kettlebell swing|American kettlebell swing|Single arm kettlebell swing|Goblet squat|Kettlebell deadlift|Kettlebell sumo deadlift high pull|Kettlebell clean|Kettlebell clean and press|Kettlebell snatch|Kettlebell press|Kettlebell push press|Kettlebell thruster|Kettlebell row|Kettlebell high pull|Turkish get up|Kettlebell windmill|Kettlebell halo|Kettlebell around the world|Kettlebell figure 8|Kettlebell farmer carry|Kettlebell lunges|Kettlebell Russian twist|Kettlebell goblet lunge"),
        ("Haltères", "Dumbbell thruster|Dumbbell snatch|Dumbbell clean|Dumbbell hang clean|Dumbbell clean and jerk|Devil press|Man maker|Renegade row|Dumbbell row|Dumbbell bench press|Dumbbell floor press|Dumbbell shoulder press|Dumbbell push press|Arnold press|Lateral raises|Front raises|Bicep curls|Hammer curls|Tricep extension|Tricep kickbacks|Dumbbell deadlift|Dumbbell Romanian deadlift|Dumbbell squat|Dumbbell lunges|Dumbbell step up|Dumbbell box step over|Dumbbell farmer carry|Dumbbell fly|Dumbbell pullover|Dumbbell burpee|Dumbbell overhead lunge"),
        ("Barre", "Deadlift|Back squat|Front squat|Overhead squat|Bench press|Overhead press|Push press|Push jerk|Thruster|Power clean|Hang power clean|Squat clean|Clean and jerk|Power snatch|Hang power snatch|Squat snatch|Bent over row|Barbell hip thrust|Romanian deadlift|Sumo deadlift high pull|Barbell lunges|Good morning|Barbell curl"),
        ("Medicine ball", "Wall ball|Medicine ball slam|Slam ball|Medicine ball chest pass|Medicine ball Russian twist|Medicine ball sit up|Medicine ball clean|Medicine ball rotational throw|Medicine ball squat"),
        ("Cardio machine", "Rower|Elliptical|Assault bike|Echo bike|Bike erg|Ski erg|Stationary bike|Spin bike|Treadmill run|Treadmill sprint|Treadmill incline walk|Curved treadmill|Stair climber|Versaclimber"),
        ("Battle rope", "Battle rope waves|Battle rope alternating waves|Battle rope slams|Battle rope circles|Battle rope jumping jacks"),
        ("Traîneau", "Sled push|Sled pull|Sled drag"),
        ("Sandbag", "Sandbag clean|Sandbag over shoulder|Sandbag carry|Sandbag squat|Sandbag lunges"),
        ("Anneaux / TRX", "Ring row|Ring dips|Ring muscle up|TRX row|TRX push up|TRX squat|TRX pistol squat"),
        ("Disque", "Plate ground to overhead|Plate front raise|Plate push"),
        ("Élastique", "Band pull apart|Band face pull|Band squat|Band lateral walk"),
        ("Machine", "Leg press|Lat pulldown|Seated cable row|Cable woodchopper|Chest press machine|Leg extension|Leg curl"),
        ("Divers", "Tire flip|Farmer carry|Bear hug carry|Wall walk|Ab wheel rollout")
    ]

    static let entries: [ExerciseCatalogEntry] = categories.flatMap { category in
        category.exercises.split(separator: "|").map {
            ExerciseCatalogEntry(
                name: String($0),
                category: category.name,
                isCustom: false
            )
        }
    }
}
