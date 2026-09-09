import Foundation
import SwiftUI

enum Side: Int, Codable {
    case player = 0
    case enemy = 1

    var opposite: Side { self == .player ? .enemy : .player }
}

enum CardKind: String, Codable {
    case troop
    case spell
}

struct CardDef: Identifiable, Hashable {
    let id: String
    let name: String
    let cost: Int
    let kind: CardKind
    let emoji: String
    let count: Int
    let hp: Double
    let damage: Double
    let range: Double
    let hitSpeed: Double
    let speed: Double
    let flying: Bool
    let buildingsOnly: Bool
    let radius: Double
    let description: String

    static func troop(_ id: String, _ name: String, cost: Int, emoji: String, count: Int = 1,
                      hp: Double, damage: Double, range: Double, hitSpeed: Double, speed: Double,
                      flying: Bool = false, buildingsOnly: Bool = false, description: String) -> CardDef {
        CardDef(id: id, name: name, cost: cost, kind: .troop, emoji: emoji, count: count, hp: hp,
                damage: damage, range: range, hitSpeed: hitSpeed, speed: speed, flying: flying,
                buildingsOnly: buildingsOnly, radius: 0, description: description)
    }

    static func spell(_ id: String, _ name: String, cost: Int, emoji: String, damage: Double,
                      radius: Double, description: String) -> CardDef {
        CardDef(id: id, name: name, cost: cost, kind: .spell, emoji: emoji, count: 0, hp: 0,
                damage: damage, range: 0, hitSpeed: 0, speed: 0, flying: false, buildingsOnly: false,
                radius: radius, description: description)
    }
}

enum Cards {
    static let all: [CardDef] = [
        .troop("knight", "Knight", cost: 3, emoji: "🛡️", hp: 1400, damage: 160, range: 1.0, hitSpeed: 1.1, speed: 2.0,
               description: "A sturdy melee fighter. Good at soaking damage."),
        .troop("archers", "Archers", cost: 3, emoji: "🏹", count: 2, hp: 250, damage: 90, range: 5.0, hitSpeed: 1.0, speed: 2.0,
               description: "A pair of ranged shooters. Can hit flying troops."),
        .troop("giant", "Colossus", cost: 5, emoji: "🗿", hp: 3300, damage: 210, range: 1.0, hitSpeed: 1.5, speed: 1.3,
               buildingsOnly: true, description: "Slow, huge, and only interested in towers."),
        .troop("duelist", "Duelist", cost: 4, emoji: "⚔️", hp: 1100, damage: 550, range: 1.0, hitSpeed: 1.6, speed: 3.0,
               description: "Fast, and hits like a truck. Fragile in a crowd."),
        .troop("sharpshooter", "Sharpshooter", cost: 4, emoji: "🎯", hp: 600, damage: 180, range: 6.0, hitSpeed: 1.1, speed: 2.0,
               description: "Long range. Picks off troops before they arrive."),
        .troop("gremlins", "Gremlins", cost: 2, emoji: "👺", count: 3, hp: 170, damage: 100, range: 0.8, hitSpeed: 1.1, speed: 3.5,
               description: "Three very fast, very rude little fighters."),
        .troop("bones", "Bone Brigade", cost: 3, emoji: "💀", count: 6, hp: 70, damage: 70, range: 0.8, hitSpeed: 1.0, speed: 3.0,
               description: "Six skeletons. Overwhelms single targets, melts to spells."),
        .troop("whelp", "Whelp", cost: 4, emoji: "🐲", hp: 1000, damage: 130, range: 3.5, hitSpeed: 1.5, speed: 2.3,
               flying: true, description: "A baby dragon. Flies over the river; melee can't touch it."),
        .spell("meteor", "Meteor", cost: 4, emoji: "☄️", damage: 570, radius: 2.5,
               description: "Big area damage. Towers take 35%."),
        .spell("volley", "Volley", cost: 3, emoji: "🌧️", damage: 240, radius: 4.0,
               description: "Wide, light area damage. Clears swarms."),
    ]

    static let defaultDeck = ["knight", "archers", "giant", "duelist", "sharpshooter", "gremlins", "meteor", "volley"]

    static func byId(_ id: String) -> CardDef {
        all.first { $0.id == id } ?? all[0]
    }
}

struct Vec: Equatable {
    var x: Double
    var y: Double

    static func - (a: Vec, b: Vec) -> Vec { Vec(x: a.x - b.x, y: a.y - b.y) }
    static func + (a: Vec, b: Vec) -> Vec { Vec(x: a.x + b.x, y: a.y + b.y) }
    static func * (a: Vec, s: Double) -> Vec { Vec(x: a.x * s, y: a.y * s) }
    var length: Double { (x * x + y * y).squareRoot() }
    func distance(to other: Vec) -> Double { (self - other).length }
    var normalized: Vec { length > 0.0001 ? self * (1 / length) : Vec(x: 0, y: 0) }
}

final class Unit: Identifiable {
    let id: Int
    let card: CardDef
    let side: Side
    var pos: Vec
    var hp: Double
    var attackCooldown: Double = 0
    var targetId: Int? = nil
    var laneX: Double = 3.5
    var hitFlash: Double = 0

    init(id: Int, card: CardDef, side: Side, pos: Vec) {
        self.id = id
        self.card = card
        self.side = side
        self.pos = pos
        self.hp = card.hp
    }

    var alive: Bool { hp > 0 }
    var radius: Double { card.count > 1 ? 0.35 : 0.5 }
}

enum TowerKind: String {
    case guardTower
    case keep

    var maxHp: Double { self == .keep ? 4000 : 2500 }
    var damage: Double { self == .keep ? 120 : 100 }
    var range: Double { self == .keep ? 7.0 : 7.5 }
    var hitSpeed: Double { self == .keep ? 1.0 : 0.8 }
    var radius: Double { self == .keep ? 1.3 : 1.0 }
    var name: String { self == .keep ? "Keep" : "Guard Tower" }
}

final class Tower: Identifiable {
    let id: Int
    let kind: TowerKind
    let side: Side
    let pos: Vec
    var hp: Double
    var attackCooldown: Double = 0
    var activated: Bool
    var hitFlash: Double = 0

    init(id: Int, kind: TowerKind, side: Side, pos: Vec) {
        self.id = id
        self.kind = kind
        self.side = side
        self.pos = pos
        self.hp = kind.maxHp
        self.activated = kind == .guardTower
    }

    var alive: Bool { hp > 0 }
}

struct SpellEffect: Identifiable {
    let id: Int
    let pos: Vec
    let radius: Double
    let color: Color
    var ttl: Double
}

struct Projectile: Identifiable {
    let id: Int
    var pos: Vec
    let target: Vec
    let side: Side
    var ttl: Double
}

enum MatchOutcome: String {
    case victory = "VICTORY"
    case defeat = "DEFEAT"
    case draw = "DRAW"
}

struct MatchResult {
    let outcome: MatchOutcome
    let playerCrowns: Int
    let enemyCrowns: Int
    let trophyDelta: Int
    let goldDelta: Int
    let durationSeconds: Int
}
