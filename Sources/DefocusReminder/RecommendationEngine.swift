import Foundation

struct RestRecommendation: Identifiable, Equatable {
    let id: String
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
        RestRecommendation(
            id: "eyes-20-20-20",
            icon: "eye",
            titleZh: "20-20-20 远眺",
            titleEn: "20-20-20 eye reset",
            detailZh: "看向 6 米外的物体，缓慢眨眼，放松眼周。",
            detailEn: "Look at something 20 feet away, blink slowly, and relax your eyes.",
            professions: [.programmer, .designer, .student, .writer, .researcher],
            symptoms: [.dryEyes, .fatigue],
            minimumSeconds: 20
        ),
        RestRecommendation(
            id: "neck-shoulder-release",
            icon: "figure.cooldown",
            titleZh: "颈肩放松",
            titleEn: "Neck and shoulder release",
            detailZh: "肩膀向后绕圈 10 次，再左右轻轻转头。",
            detailEn: "Roll your shoulders backward 10 times, then gently turn your head side to side.",
            professions: [.programmer, .designer, .writer, .manager],
            symptoms: [.neckShoulder, .stress],
            minimumSeconds: 60
        ),
        RestRecommendation(
            id: "back-extension",
            icon: "figure.strengthtraining.traditional",
            titleZh: "腰背伸展",
            titleEn: "Back extension",
            detailZh: "站起来，双手扶腰，轻轻后伸 5 次，不要憋气。",
            detailEn: "Stand up, place your hands on your lower back, and gently extend 5 times.",
            professions: [.programmer, .student, .researcher, .manager],
            symptoms: [.lowerBack, .sedentary],
            minimumSeconds: 90
        ),
        RestRecommendation(
            id: "wrist-reset",
            icon: "hand.raised",
            titleZh: "手腕重置",
            titleEn: "Wrist reset",
            detailZh: "伸直手臂，手掌向下和向上各保持 10 秒。",
            detailEn: "Extend your arms and hold palm-down and palm-up stretches for 10 seconds each.",
            professions: [.programmer, .designer, .writer],
            symptoms: [.wrist],
            minimumSeconds: 45
        ),
        RestRecommendation(
            id: "walk-and-water",
            icon: "figure.walk",
            titleZh: "走动喝水",
            titleEn: "Walk and hydrate",
            detailZh: "离开座位走一小圈，顺手喝几口水。",
            detailEn: "Leave your seat, take a short walk, and drink some water.",
            professions: [.general, .student, .researcher, .manager],
            symptoms: [.sedentary, .fatigue],
            minimumSeconds: 120
        ),
        RestRecommendation(
            id: "breathing",
            icon: "wind",
            titleZh: "慢呼吸",
            titleEn: "Slow breathing",
            detailZh: "吸气 4 秒，呼气 6 秒，重复 5 轮。",
            detailEn: "Inhale for 4 seconds, exhale for 6 seconds, repeat 5 rounds.",
            professions: [.general, .manager, .student],
            symptoms: [.stress, .fatigue],
            minimumSeconds: 60
        ),
        RestRecommendation(
            id: "general-stand",
            icon: "figure.stand",
            titleZh: "站起来换焦点",
            titleEn: "Stand and defocus",
            detailZh: "站起来，把视线从屏幕移开，活动一下身体。",
            detailEn: "Stand up, move your gaze away from the screen, and loosen your body.",
            professions: [.general],
            symptoms: [],
            minimumSeconds: 20
        ),
    ]

    static func recommendation(
        for profile: HealthProfile,
        durationSeconds: Int,
        language: AppLanguage,
        seed: Int = 0
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
        return best[abs(seed) % best.count]
    }
}
