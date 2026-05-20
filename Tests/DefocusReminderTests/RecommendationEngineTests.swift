import XCTest
@testable import DefocusReminderCore

final class RecommendationEngineTests: XCTestCase {
    func testDryEyesPrefersEyeRecommendation() {
        let profile = HealthProfile(profession: .programmer, symptoms: [.dryEyes])
        let recommendation = RecommendationEngine.recommendation(
            for: profile,
            durationSeconds: 300,
            language: .zh
        )

        XCTAssertEqual(recommendation.category, .eyes)
    }

    func testLowerBackSedentaryPrefersBackRecommendation() {
        let profile = HealthProfile(profession: .researcher, symptoms: [.lowerBack, .sedentary])
        let recommendation = RecommendationEngine.recommendation(
            for: profile,
            durationSeconds: 300,
            language: .en
        )

        XCTAssertEqual(recommendation.id, "back-extension")
    }

    func testEmptyProfileReturnsGeneralSuggestion() {
        let recommendation = RecommendationEngine.recommendation(
            for: HealthProfile(),
            durationSeconds: 60,
            language: .en
        )

        XCTAssertEqual(recommendation.id, "general-stand")
    }

    func testRecommendationAvoidsImmediateRepeatWhenPossible() {
        let profile = HealthProfile(profession: .designer, symptoms: [.wrist])
        let first = RecommendationEngine.recommendation(
            for: profile,
            durationSeconds: 300,
            language: .en,
            seed: 0
        )
        let second = RecommendationEngine.recommendation(
            for: profile,
            durationSeconds: 300,
            language: .en,
            seed: 0,
            avoiding: first.id
        )

        XCTAssertNotEqual(first.id, second.id)
    }

    func testEachRecommendationCategoryHasMultipleTips() {
        let counts = Dictionary(grouping: RecommendationEngine.rules, by: \.category)
            .mapValues(\.count)

        for category in RecommendationCategory.allCases {
            XCTAssertGreaterThanOrEqual(counts[category] ?? 0, 4, "\(category)")
        }
    }
}
