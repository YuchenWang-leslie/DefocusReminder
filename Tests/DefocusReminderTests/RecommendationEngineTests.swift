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

        XCTAssertEqual(recommendation.id, "eyes-20-20-20")
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
}
