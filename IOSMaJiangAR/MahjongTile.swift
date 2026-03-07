import Foundation

enum MahjongSuit: String, CaseIterable {
    case wan
    case tiao
    case tong
    case wind
    case dragon
    case flower
}

enum MahjongTile: String, CaseIterable, Hashable {
    case wan1, wan2, wan3, wan4, wan5, wan6, wan7, wan8, wan9
    case tiao1, tiao2, tiao3, tiao4, tiao5, tiao6, tiao7, tiao8, tiao9
    case tong1, tong2, tong3, tong4, tong5, tong6, tong7, tong8, tong9
    case east, south, west, north
    case red, green, white
    case plum, orchid, bamboo, chrysanthemum, spring, summer, autumn, winter

    var suit: MahjongSuit {
        switch self {
        case .wan1, .wan2, .wan3, .wan4, .wan5, .wan6, .wan7, .wan8, .wan9:
            return .wan
        case .tiao1, .tiao2, .tiao3, .tiao4, .tiao5, .tiao6, .tiao7, .tiao8, .tiao9:
            return .tiao
        case .tong1, .tong2, .tong3, .tong4, .tong5, .tong6, .tong7, .tong8, .tong9:
            return .tong
        case .east, .south, .west, .north:
            return .wind
        case .red, .green, .white:
            return .dragon
        case .plum, .orchid, .bamboo, .chrysanthemum, .spring, .summer, .autumn, .winter:
            return .flower
        }
    }

    var rank: Int {
        switch self {
        case .wan1, .tiao1, .tong1: return 1
        case .wan2, .tiao2, .tong2: return 2
        case .wan3, .tiao3, .tong3: return 3
        case .wan4, .tiao4, .tong4: return 4
        case .wan5, .tiao5, .tong5: return 5
        case .wan6, .tiao6, .tong6: return 6
        case .wan7, .tiao7, .tong7: return 7
        case .wan8, .tiao8, .tong8: return 8
        case .wan9, .tiao9, .tong9: return 9
        default: return 0
        }
    }

    var displayName: String {
        switch self {
        case .wan1: return "一万"
        case .wan2: return "二万"
        case .wan3: return "三万"
        case .wan4: return "四万"
        case .wan5: return "五万"
        case .wan6: return "六万"
        case .wan7: return "七万"
        case .wan8: return "八万"
        case .wan9: return "九万"
        case .tiao1: return "一条"
        case .tiao2: return "二条"
        case .tiao3: return "三条"
        case .tiao4: return "四条"
        case .tiao5: return "五条"
        case .tiao6: return "六条"
        case .tiao7: return "七条"
        case .tiao8: return "八条"
        case .tiao9: return "九条"
        case .tong1: return "一筒"
        case .tong2: return "二筒"
        case .tong3: return "三筒"
        case .tong4: return "四筒"
        case .tong5: return "五筒"
        case .tong6: return "六筒"
        case .tong7: return "七筒"
        case .tong8: return "八筒"
        case .tong9: return "九筒"
        case .east: return "东风"
        case .south: return "南风"
        case .west: return "西风"
        case .north: return "北风"
        case .red: return "红中"
        case .green: return "发财"
        case .white: return "白板"
        case .plum: return "梅"
        case .orchid: return "兰"
        case .bamboo: return "竹"
        case .chrysanthemum: return "菊"
        case .spring: return "春"
        case .summer: return "夏"
        case .autumn: return "秋"
        case .winter: return "冬"
        }
    }

    var modelLabel: String {
        rawValue
    }

    static let drawableTiles: [MahjongTile] = [
        .wan1, .wan2, .wan3, .wan4, .wan5, .wan6, .wan7, .wan8, .wan9,
        .tiao1, .tiao2, .tiao3, .tiao4, .tiao5, .tiao6, .tiao7, .tiao8, .tiao9,
        .tong1, .tong2, .tong3, .tong4, .tong5, .tong6, .tong7, .tong8, .tong9,
        .east, .south, .west, .north, .red, .green, .white
    ]
}

extension MahjongTile {
    static let modelLookup: [String: MahjongTile] = {
        Dictionary(uniqueKeysWithValues: MahjongTile.allCases.map { ($0.modelLabel, $0) })
    }()
}
