import Foundation

enum RecommendationCategory: String, Codable, CaseIterable, Equatable, Hashable {
    case eyes
    case neckShoulder
    case lowerBack
    case wrist
    case sedentary
    case stress
    case fatigue
    case general
}

struct RestRecommendation: Identifiable, Equatable {
    let id: String
    let category: RecommendationCategory
    let icon: String
    let titleZh: String
    let titleEn: String
    let detailZh: String
    let detailEn: String
    let professions: Set<ProfessionTag>
    let symptoms: Set<SymptomTag>
    let minimumSeconds: Int

    func title(language: AppLanguage) -> String {
        L.s(titleZh, titleEn, language)
    }

    func detail(language: AppLanguage) -> String {
        L.s(detailZh, detailEn, language)
    }
}

enum RecommendationEngine {
    static let rules: [RestRecommendation] = [
        item("eyes-20-20-20", .eyes, "eye", "20-20-20 远眺", "20-20-20 eye reset", "看向 6 米外的物体，缓慢眨眼，放松眼周。", "Look at something 20 feet away, blink slowly, and relax your eyes.", [.programmer, .designer, .student, .writer, .researcher], [.dryEyes, .fatigue], 20),
        item("eyes-palming", .eyes, "eye.fill", "掌心覆眼", "Palm your eyes", "搓热双手，轻轻覆在眼睛上，保持自然呼吸。", "Warm your palms, cover your eyes gently, and breathe naturally.", [.programmer, .designer, .student, .writer], [.dryEyes, .fatigue], 45),
        item("eyes-soft-focus", .eyes, "viewfinder", "软焦环顾", "Soft-focus scan", "把视线从屏幕移开，慢慢扫过远处三个物体。", "Move your gaze off-screen and slowly scan three distant objects.", [.general, .programmer, .designer, .researcher], [.dryEyes], 30),
        item("eyes-blink-reset", .eyes, "sparkle.magnifyingglass", "眨眼重置", "Blink reset", "连续轻眨 10 次，再闭眼放松 10 秒。", "Blink lightly 10 times, then close your eyes for 10 seconds.", [.programmer, .student, .writer], [.dryEyes], 20),

        item("neck-shoulder-release", .neckShoulder, "figure.cooldown", "颈肩放松", "Neck and shoulder release", "肩膀向后绕圈 10 次，再左右轻轻转头。", "Roll your shoulders backward 10 times, then gently turn your head side to side.", [.programmer, .designer, .writer, .manager], [.neckShoulder, .stress], 60),
        item("neck-chin-tuck", .neckShoulder, "figure.mind.and.body", "下巴回收", "Chin tuck", "坐直，下巴轻轻向后收，保持 5 秒后放松。", "Sit tall, gently tuck your chin back, hold for 5 seconds, then release.", [.programmer, .writer, .researcher], [.neckShoulder], 45),
        item("neck-side-stretch", .neckShoulder, "figure.flexibility", "侧颈伸展", "Side neck stretch", "右耳靠向右肩停留 10 秒，换边重复。", "Drop one ear toward the shoulder for 10 seconds, then switch sides.", [.general, .designer, .manager], [.neckShoulder], 45),
        item("shoulder-blade-squeeze", .neckShoulder, "arrow.left.and.right", "肩胛夹紧", "Shoulder blade squeeze", "双肩向后下方夹紧 5 秒，重复 6 次。", "Squeeze shoulder blades down and back for 5 seconds, repeat 6 times.", [.programmer, .writer, .manager], [.neckShoulder, .stress], 60),

        item("back-extension", .lowerBack, "figure.strengthtraining.traditional", "腰背伸展", "Back extension", "站起来，双手扶腰，轻轻后伸 5 次，不要憋气。", "Stand up, place your hands on your lower back, and gently extend 5 times.", [.programmer, .student, .researcher, .manager], [.lowerBack, .sedentary], 90),
        item("back-standing-fold", .lowerBack, "figure.roll", "站姿前屈", "Standing fold", "膝盖微弯，身体前倾放松腰背 15 秒。", "Soften your knees and fold forward for 15 seconds to release your back.", [.general, .student, .researcher], [.lowerBack], 60),
        item("back-hip-shift", .lowerBack, "figure.core.training", "骨盆轻摆", "Hip shift", "站立时左右轻移重心，各停留 5 秒。", "Stand and shift your weight side to side, holding 5 seconds each.", [.programmer, .manager], [.lowerBack, .sedentary], 45),
        item("back-seated-twist", .lowerBack, "figure.seated.side", "坐姿转体", "Seated twist", "坐稳后轻轻向左右转体，保持肩膀放松。", "Sit tall and gently rotate left and right with relaxed shoulders.", [.writer, .researcher, .student], [.lowerBack], 45),

        item("wrist-reset", .wrist, "hand.raised", "手腕重置", "Wrist reset", "伸直手臂，手掌向下和向上各保持 10 秒。", "Extend your arms and hold palm-down and palm-up stretches for 10 seconds each.", [.programmer, .designer, .writer], [.wrist], 45),
        item("wrist-circles", .wrist, "hand.draw", "手腕绕圈", "Wrist circles", "双手放松，顺逆时针各绕 10 圈。", "Relax both hands and circle wrists 10 times each direction.", [.programmer, .designer, .writer], [.wrist], 30),
        item("finger-fan", .wrist, "hand.point.up.left", "手指张合", "Finger fan", "用力张开手指 3 秒再放松，重复 8 次。", "Spread your fingers for 3 seconds, relax, and repeat 8 times.", [.programmer, .designer], [.wrist], 30),
        item("forearm-release", .wrist, "hand.tap", "前臂放松", "Forearm release", "轻揉前臂内外侧，从手腕到手肘慢慢移动。", "Gently massage both sides of your forearm from wrist to elbow.", [.designer, .writer], [.wrist], 60),

        item("walk-and-water", .sedentary, "figure.walk", "走动喝水", "Walk and hydrate", "离开座位走一小圈，顺手喝几口水。", "Leave your seat, take a short walk, and drink some water.", [.general, .student, .researcher, .manager], [.sedentary, .fatigue], 120),
        item("stand-calf-raise", .sedentary, "figure.stairs", "小腿唤醒", "Calf raises", "扶住桌沿，脚跟抬起放下 12 次。", "Hold the desk edge and raise/lower your heels 12 times.", [.general, .programmer, .manager], [.sedentary], 60),
        item("desk-lap", .sedentary, "figure.walk.motion", "绕桌一圈", "Desk lap", "绕工位走一圈，让呼吸和步伐慢下来。", "Take one lap around your workspace and slow your breathing.", [.general, .student, .researcher], [.sedentary, .fatigue], 90),
        item("stand-posture-check", .sedentary, "figure.stand.line.dotted.figure.stand", "站姿检查", "Standing posture check", "站起来，脚踩稳，肩膀放松，保持 20 秒。", "Stand with grounded feet and relaxed shoulders for 20 seconds.", [.general, .programmer, .writer], [.sedentary], 30),

        item("breathing", .stress, "wind", "慢呼吸", "Slow breathing", "吸气 4 秒，呼气 6 秒，重复 5 轮。", "Inhale for 4 seconds, exhale for 6 seconds, repeat 5 rounds.", [.general, .manager, .student], [.stress, .fatigue], 60),
        item("box-breath", .stress, "square.dashed", "方块呼吸", "Box breathing", "吸气、停留、呼气、停留各 4 秒，做 3 轮。", "Inhale, hold, exhale, and hold for 4 seconds each, 3 rounds.", [.manager, .student, .researcher], [.stress], 60),
        item("jaw-release", .stress, "face.smiling", "放松下颌", "Jaw release", "让舌尖轻触上颚，松开牙关，慢呼吸。", "Rest your tongue on the roof of your mouth, unclench, and breathe.", [.manager, .writer, .student], [.stress], 30),
        item("name-three-things", .stress, "circle.grid.3x3", "三件事落地", "Name three things", "说出你看到的三件物品，把注意力拉回当下。", "Name three things you can see to bring attention back to now.", [.general, .manager, .student], [.stress, .fatigue], 30),

        item("fatigue-brighten", .fatigue, "sun.max", "提亮精神", "Brighten up", "起身看向窗外，深呼吸，给身体一点光线。", "Stand up, look outside, breathe deeply, and get a little light.", [.general, .writer, .researcher], [.fatigue], 60),
        item("fatigue-water", .fatigue, "drop", "补水提醒", "Hydration reset", "喝几口水，顺便离开屏幕 30 秒。", "Drink some water and step away from the screen for 30 seconds.", [.general, .programmer, .student], [.fatigue], 30),
        item("fatigue-face-refresh", .fatigue, "hands.sparkles", "面部唤醒", "Face refresh", "轻拍脸颊和太阳穴，让注意力重新聚焦。", "Lightly tap cheeks and temples to refresh your focus.", [.designer, .writer, .manager], [.fatigue], 30),
        item("fatigue-posture-reset", .fatigue, "figure.arms.open", "打开胸腔", "Open your chest", "双手向后打开胸口，停留 10 秒再放松。", "Open your chest with arms back, hold 10 seconds, then release.", [.programmer, .researcher, .student], [.fatigue, .neckShoulder], 45),

        item("general-stand", .general, "figure.stand", "站起来换焦点", "Stand and defocus", "站起来，把视线从屏幕移开，活动一下身体。", "Stand up, move your gaze away from the screen, and loosen your body.", [.general], [], 20),
        item("general-window", .general, "window.vertical.open", "看向窗外", "Look outside", "看向窗外 20 秒，让眼睛和脑子换个距离。", "Look outside for 20 seconds and change your visual distance.", [.general], [], 20),
        item("general-posture", .general, "figure.stand.line.dotted.figure.stand", "姿势归位", "Posture reset", "脚踩地、肩放松、屏幕离远一点。", "Feet on the floor, shoulders relaxed, screen a bit farther away.", [.general], [], 20),
        item("general-breathe", .general, "leaf", "轻呼吸", "Easy breath", "慢慢吸气，再更慢地呼出去，重复 3 次。", "Inhale slowly, exhale even slower, repeat 3 times.", [.general], [], 20),
    ]

    static func recommendation(
        for profile: HealthProfile,
        durationSeconds: Int,
        language: AppLanguage,
        seed: Int = 0,
        avoiding previousID: String? = nil
    ) -> RestRecommendation {
        let candidates = rules.filter { durationSeconds >= $0.minimumSeconds }
        let available = candidates.isEmpty ? rules : candidates

        func score(_ rule: RestRecommendation) -> Int {
            var value = 0
            if rule.professions.contains(profile.profession) { value += 4 }
            if rule.professions.contains(.general) { value += 1 }
            value += rule.symptoms.intersection(profile.symptoms).count * 5
            if rule.symptoms.isEmpty, profile.symptoms.isEmpty { value += 2 }
            return value
        }

        let bestScore = available.map(score).max() ?? 0
        let best = available.filter { score($0) == bestScore }
        guard let fallback = rules.last else {
            return RestRecommendation(
                id: "empty",
                category: .general,
                icon: "figure.stand",
                titleZh: "站起来换焦点",
                titleEn: "Stand and defocus",
                detailZh: "离开屏幕一会儿。",
                detailEn: "Step away from the screen for a moment.",
                professions: [.general],
                symptoms: [],
                minimumSeconds: 0
            )
        }
        guard !best.isEmpty else { return fallback }

        var selected = best[abs(seed) % best.count]
        if best.count > 1, selected.id == previousID {
            selected = best[(abs(seed) + 1) % best.count]
        }
        return selected
    }

    private static func item(
        _ id: String,
        _ category: RecommendationCategory,
        _ icon: String,
        _ titleZh: String,
        _ titleEn: String,
        _ detailZh: String,
        _ detailEn: String,
        _ professions: Set<ProfessionTag>,
        _ symptoms: Set<SymptomTag>,
        _ minimumSeconds: Int
    ) -> RestRecommendation {
        RestRecommendation(
            id: id,
            category: category,
            icon: icon,
            titleZh: titleZh,
            titleEn: titleEn,
            detailZh: detailZh,
            detailEn: detailEn,
            professions: professions,
            symptoms: symptoms,
            minimumSeconds: minimumSeconds
        )
    }
}
