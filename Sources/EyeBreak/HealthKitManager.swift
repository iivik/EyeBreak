import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private let mindfulType = HKCategoryType(.mindfulSession)
    private init() {}

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [mindfulType], read: [])
    }

    func logMindfulSession(start: Date, end: Date) {
        guard HKHealthStore.isHealthDataAvailable(),
              AppSettings.shared.healthKitEnabled,
              TrialManager.shared.isPurchased else { return }

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        store.save(sample) { _, _ in }
    }
}
