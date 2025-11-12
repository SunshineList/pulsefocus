import Foundation
import HealthKit
import Combine

final class HealthManager: ObservableObject {
    static let shared = HealthManager()
    private let store = HKHealthStore()
    @Published var heartRate: Double = 0
    @Published var hrv: Double = 0
    @Published var restingHeartRate: Double = 0
    private var hrQuery: HKAnchoredObjectQuery?
    private var hrvQuery: HKAnchoredObjectQuery?
    private var cancellables: Set<AnyCancellable> = []
    var simulated: Bool = true

    func requestAuthorization() async throws {
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        ]
        try await store.requestAuthorization(toShare: [], read: types)
    }

    func start() {
        if simulated { startSimulated() } else { startQueries() }
    }

    func stop() { hrQuery = nil; hrvQuery = nil }

    private func startSimulated() {
        Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            let base = 65.0
            let jitter = Double(Int.random(in: -6...12))
            self.heartRate = base + jitter
            self.hrv = Double(Int.random(in: 40...80))
            self.restingHeartRate = 64.0
        }.store(in: &cancellables)
    }

    private func startQueries() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .hour, value: -12, to: .now), end: .now)
        hrQuery = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            self.updateHR(samples)
        }
        hrQuery?.updateHandler = { _, samples, _, _, _ in self.updateHR(samples) }
        hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { _, samples, _, _, _ in
            self.updateHRV(samples)
        }
        hrvQuery?.updateHandler = { _, samples, _, _, _ in self.updateHRV(samples) }
        store.execute(hrQuery!)
        store.execute(hrvQuery!)
        fetchRHR(rhrType)
    }

    private func updateHR(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let last = samples.last else { return }
        let bpm = last.quantity.doubleValue(for: HKUnit(from: "count/min"))
        heartRate = bpm
    }

    private func updateHRV(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let last = samples.last else { return }
        let sdnn = last.quantity.doubleValue(for: HKUnit(from: "ms"))
        hrv = sdnn
    }

    private func fetchRHR(_ type: HKQuantityType) {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .day, value: -14, to: .now), end: .now)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: sort) { _, samples, _ in
            guard let s = samples?.first as? HKQuantitySample else { return }
            self.restingHeartRate = s.quantity.doubleValue(for: HKUnit(from: "count/min"))
        }
        store.execute(query)
    }
}

