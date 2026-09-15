import Foundation

struct RideRecords: Codable {
  private(set) var bestScore = 0
  private(set) var bestDistance = 0
  private(set) var totalCoins = 0
  private(set) var rides = 0
  private(set) var totalFlips = 0
  private(set) var practiceDistance = 0

  mutating func save(_ ride: RideSummary) {
    if ride.mode == .practice {
      practiceDistance = max(practiceDistance, ride.distance)
      return
    }
    bestScore = max(bestScore, ride.score)
    bestDistance = max(bestDistance, ride.distance)
    totalCoins += ride.coins
    totalFlips += ride.flips
    rides += 1
  }
}
