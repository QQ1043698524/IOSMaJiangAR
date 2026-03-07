import Foundation

enum MahjongRule: String, CaseIterable {
    case guobiao = "国标"
    case sichuan = "四川"
    case guangdong = "广东"
}

struct MahjongAnalysisResult {
    let isTing: Bool
    let huTiles: [MahjongTile]
    let currentWinning: Bool
    let fanDescription: String
}

final class MahjongCalculator {
    func analyze(hand: [MahjongTile], rule: MahjongRule) -> MahjongAnalysisResult {
        let flowers = hand.filter { $0.suit == .flower }
        let baseHand = hand.filter { $0.suit != .flower }

        let currentWinning = baseHand.count % 3 == 2 && isWinning(baseHand)
        let huTiles: [MahjongTile]
        if baseHand.count % 3 == 1 {
            huTiles = waitingTiles(for: baseHand)
        } else if baseHand.count % 3 == 2, currentWinning {
            huTiles = []
        } else {
            huTiles = []
        }

        let fanDescription = fanText(
            hand: baseHand,
            huTiles: huTiles,
            currentWinning: currentWinning,
            flowers: flowers.count,
            rule: rule
        )
        return MahjongAnalysisResult(
            isTing: !huTiles.isEmpty,
            huTiles: huTiles,
            currentWinning: currentWinning,
            fanDescription: fanDescription
        )
    }

    private func waitingTiles(for hand: [MahjongTile]) -> [MahjongTile] {
        MahjongTile.drawableTiles.filter { tile in
            let next = hand + [tile]
            return isWinning(next)
        }
    }

    private func isWinning(_ hand: [MahjongTile]) -> Bool {
        guard hand.count % 3 == 2 else { return false }
        let counts = toCounts(hand)
        if isSevenPairs(counts) { return true }
        if isThirteenOrphans(counts) { return true }
        return isStandardWinning(counts)
    }

    private func toCounts(_ hand: [MahjongTile]) -> [Int] {
        var counts = Array(repeating: 0, count: MahjongTile.drawableTiles.count)
        for tile in hand {
            guard let idx = MahjongTile.drawableTiles.firstIndex(of: tile) else { continue }
            counts[idx] += 1
            if counts[idx] > 4 { return [] }
        }
        return counts
    }

    private func isSevenPairs(_ counts: [Int]) -> Bool {
        guard counts.count == 34 else { return false }
        var pair = 0
        for value in counts {
            if value == 2 { pair += 1 }
            if value == 4 { pair += 2 }
            if value == 1 || value == 3 { return false }
        }
        return pair == 7
    }

    private func isThirteenOrphans(_ counts: [Int]) -> Bool {
        guard counts.count == 34 else { return false }
        let required = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33]
        var pairFound = false
        for idx in required {
            if counts[idx] == 0 { return false }
            if counts[idx] >= 2 { pairFound = true }
        }
        for (idx, value) in counts.enumerated() where !required.contains(idx) {
            if value > 0 { return false }
        }
        return pairFound
    }

    private func isStandardWinning(_ counts: [Int]) -> Bool {
        guard counts.count == 34 else { return false }
        var memo: [String: Bool] = [:]
        for pairIndex in 0..<34 where counts[pairIndex] >= 2 {
            var test = counts
            test[pairIndex] -= 2
            if canMeldAll(&test, memo: &memo) { return true }
        }
        return false
    }

    private func canMeldAll(_ counts: inout [Int], memo: inout [String: Bool]) -> Bool {
        let key = counts.map(String.init).joined(separator: ",")
        if let cached = memo[key] { return cached }

        guard let first = counts.firstIndex(where: { $0 > 0 }) else {
            memo[key] = true
            return true
        }

        if counts[first] >= 3 {
            counts[first] -= 3
            if canMeldAll(&counts, memo: &memo) {
                counts[first] += 3
                memo[key] = true
                return true
            }
            counts[first] += 3
        }

        let suitStart: Int
        switch first {
        case 0...8:
            suitStart = 0
        case 9...17:
            suitStart = 9
        case 18...26:
            suitStart = 18
        default:
            suitStart = -1
        }

        if suitStart >= 0 {
            let offset = first - suitStart
            if offset <= 6 && counts[first + 1] > 0 && counts[first + 2] > 0 {
                counts[first] -= 1
                counts[first + 1] -= 1
                counts[first + 2] -= 1
                if canMeldAll(&counts, memo: &memo) {
                    counts[first] += 1
                    counts[first + 1] += 1
                    counts[first + 2] += 1
                    memo[key] = true
                    return true
                }
                counts[first] += 1
                counts[first + 1] += 1
                counts[first + 2] += 1
            }
        }

        memo[key] = false
        return false
    }

    private func fanText(
        hand: [MahjongTile],
        huTiles: [MahjongTile],
        currentWinning: Bool,
        flowers: Int,
        rule: MahjongRule
    ) -> String {
        if currentWinning {
            let fan = estimateFan(hand: hand, flowers: flowers, rule: rule)
            return "当前可胡，约\(fan)番"
        }
        if huTiles.isEmpty { return "未听牌" }
        let fan = estimateFan(hand: hand, flowers: flowers, rule: rule)
        return "听牌，约\(fan)番"
    }

    private func estimateFan(hand: [MahjongTile], flowers: Int, rule: MahjongRule) -> Int {
        var fan = 1
        let suits = Set(hand.map { $0.suit }.filter { $0 == .wan || $0 == .tiao || $0 == .tong })
        if suits.count == 1 { fan += 3 }
        let honors = hand.filter { $0.suit == .wind || $0.suit == .dragon }.count
        if honors == 0 { fan += 1 }
        if flowers > 0 {
            switch rule {
            case .guobiao:
                fan += min(flowers, 8)
            case .sichuan:
                fan += 0
            case .guangdong:
                fan += min(flowers, 4)
            }
        }
        return fan
    }
}
