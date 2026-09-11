import Foundation
import SwiftUI
import Combine

enum Arena {
    static let width: Double = 18
    static let height: Double = 32
    static let riverTop: Double = 15
    static let riverBottom: Double = 17
    static let riverCenter: Double = 16
    static let bridgeXs: [Double] = [3.5, 14.5]
    static let bridgeHalfWidth: Double = 1.0
    static let playerDeployMinY: Double = 17.2
    static let regulationSeconds: Double = 180
    static let overtimeSeconds: Double = 60
    static let maxElixir: Double = 10
    static let elixirPerSecond: Double = 1.0 / 2.8
    static let aggroRange: Double = 6.0
    static let towerSpellFactor: Double = 0.35

    static func laneX(for x: Double) -> Double { x < width / 2 ? bridgeXs[0] : bridgeXs[1] }

    static func towerPositions(for side: Side) -> [(TowerKind, Vec)] {
        switch side {
        case .player:
            return [(.guardTower, Vec(x: 3.5, y: 25.5)), (.guardTower, Vec(x: 14.5, y: 25.5)), (.keep, Vec(x: 9, y: 29.5))]
        case .enemy:
            return [(.guardTower, Vec(x: 3.5, y: 6.5)), (.guardTower, Vec(x: 14.5, y: 6.5)), (.keep, Vec(x: 9, y: 2.5))]
        }
    }
}

final class BattleEngine: ObservableObject {
    // Battle state
    private(set) var units: [Unit] = []
    private(set) var towers: [Tower] = []
    private(set) var effects: [SpellEffect] = []
    private(set) var projectiles: [Projectile] = []
    private(set) var particles: [Particle] = []
    private(set) var floatingTexts: [FloatingText] = []
    private(set) var elapsed: Double = 0
    private(set) var playerElixir: Double = 5
    private(set) var enemyElixir: Double = 5
    private(set) var hand: [String] = []
    private(set) var nextCard: String = ""
    private var queue: [String] = []
    private var enemyHand: [String] = []
    private var enemyQueue: [String] = []
    private(set) var selectedHandIndex: Int? = nil
    private(set) var result: MatchResult? = nil
    private(set) var isOvertime = false
    private(set) var announcement: String? = nil
    private var announcementTTL: Double = 0
    private var nextId = 1
    private var enemyDecisionTimer: Double = 0
    private var timer: AnyCancellable?
    private var lastTick: Date?
    private var rng = SystemRandomNumberGenerator()
    let deck: [String]

    init(deck: [String]) {
        self.deck = deck
        reset()
    }

    func reset() {
        units = []
        effects = []
        projectiles = []
        particles = []
        floatingTexts = []
        elapsed = 0
        playerElixir = 5
        enemyElixir = 5
        result = nil
        isOvertime = false
        announcement = nil
        selectedHandIndex = nil
        nextId = 1
        enemyDecisionTimer = 1.5
        towers = []
        for side in [Side.player, Side.enemy] {
            for (kind, pos) in Arena.towerPositions(for: side) {
                towers.append(Tower(id: allocId(), kind: kind, side: side, pos: pos))
            }
        }
        var shuffled = deck.shuffled(using: &rng)
        hand = Array(shuffled.prefix(4))
        shuffled.removeFirst(4)
        nextCard = shuffled.first ?? deck[0]
        queue = shuffled
        var enemyDeck = Array(Cards.all.map(\.id).shuffled(using: &rng).prefix(8))
        if !enemyDeck.contains(where: { Cards.byId($0).kind == .spell }) { enemyDeck[0] = "meteor" }
        enemyDeck.shuffle(using: &rng)
        enemyHand = Array(enemyDeck.prefix(4))
        enemyQueue = Array(enemyDeck.dropFirst(4))
        objectWillChange.send()
    }

    func start() {
        lastTick = Date()
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.frame(now) }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func allocId() -> Int {
        defer { nextId += 1 }
        return nextId
    }

    // MARK: - Derived state

    var remainingSeconds: Int {
        let total = isOvertime ? Arena.regulationSeconds + Arena.overtimeSeconds : Arena.regulationSeconds
        return max(0, Int(ceil(total - elapsed)))
    }

    var isDoubleElixir: Bool { isOvertime || elapsed >= Arena.regulationSeconds - 60 }

    func crowns(for side: Side) -> Int {
        let destroyed = towers.filter { $0.side == side.opposite && !$0.alive }
        if destroyed.contains(where: { $0.kind == .keep }) { return 3 }
        return destroyed.count
    }

    var selectedCard: CardDef? {
        guard let i = selectedHandIndex, i < hand.count else { return nil }
        return Cards.byId(hand[i])
    }

    // MARK: - Player input

    func selectHand(_ index: Int) {
        if selectedHandIndex == index { selectedHandIndex = nil } else { selectedHandIndex = index }
        objectWillChange.send()
    }

    func canAfford(_ card: CardDef) -> Bool { playerElixir >= Double(card.cost) }

    func isValidDeploy(_ card: CardDef, at pos: Vec) -> Bool {
        guard pos.x >= 0.3, pos.x <= Arena.width - 0.3, pos.y >= 0.3, pos.y <= Arena.height - 0.3 else { return false }
        if card.kind == .spell { return true }
        return pos.y >= Arena.playerDeployMinY
    }

    @discardableResult
    func deployAtTap(_ pos: Vec) -> Bool {
        guard result == nil, let index = selectedHandIndex, index < hand.count else { return false }
        let card = Cards.byId(hand[index])
        guard canAfford(card), isValidDeploy(card, at: pos) else {
            flash(card.kind == .spell ? "Not enough elixir" : (canAfford(card) ? "Deploy on your side" : "Not enough elixir"))
            return false
        }
        playerElixir -= Double(card.cost)
        play(card, side: .player, at: pos)
        let played = hand.remove(at: index)
        hand.insert(nextCard, at: index)
        queue.removeFirst()
        queue.append(played)
        nextCard = queue.first ?? played
        selectedHandIndex = nil
        objectWillChange.send()
        return true
    }

    private func flash(_ text: String) {
        announcement = text
        announcementTTL = 1.2
    }

    // MARK: - Simulation

    private func frame(_ now: Date) {
        guard let last = lastTick else { lastTick = now; return }
        var dt = now.timeIntervalSince(last)
        lastTick = now
        dt = min(dt, 0.1)
        guard result == nil else { return }
        step(dt)
        objectWillChange.send()
    }

    func step(_ dt: Double) {
        elapsed += dt
        let rate = Arena.elixirPerSecond * (isDoubleElixir ? 2 : 1)
        playerElixir = min(Arena.maxElixir, playerElixir + rate * dt)
        enemyElixir = min(Arena.maxElixir, enemyElixir + rate * dt)

        if announcementTTL > 0 {
            announcementTTL -= dt
            if announcementTTL <= 0 { announcement = nil }
        }

        for unit in units where unit.alive { stepUnit(unit, dt: dt) }
        separateUnits()
        for tower in towers where tower.alive { stepTower(tower, dt: dt) }

        for i in effects.indices {
            effects[i].ttl -= dt
            if !effects[i].resolved && effects[i].landed {
                effects[i].resolved = true
                resolveSpell(effects[i])
            }
        }
        effects.removeAll { $0.ttl <= 0 }
        for i in projectiles.indices {
            let p = projectiles[i]
            let dir = (p.target - p.pos).normalized
            let speed: Double = p.kind == .fireball ? 12 : (p.kind == .cannon ? 14 : 18)
            projectiles[i].pos = p.pos + dir * (speed * dt)
            projectiles[i].ttl -= dt
        }
        for p in projectiles where p.ttl <= 0 || p.pos.distance(to: p.target) < 0.4 {
            spawnImpact(p)
        }
        projectiles.removeAll { $0.ttl <= 0 || $0.pos.distance(to: $0.target) < 0.4 }
        for u in units where !u.alive { spawnDeath(u) }
        units.removeAll { !$0.alive }

        for i in particles.indices {
            var p = particles[i]
            p.ttl -= dt
            switch p.kind {
            case .smoke: p.vel = Vec(x: p.vel.x * 0.98, y: p.vel.y - 0.6 * dt)
            case .debris, .bone: p.vel = Vec(x: p.vel.x * 0.96, y: p.vel.y + 9 * dt)
            case .ember, .spark: p.vel = Vec(x: p.vel.x * 0.93, y: p.vel.y * 0.93 + 2 * dt)
            case .dust, .glow: p.vel = p.vel * 0.9
            case .leaf: p.vel = Vec(x: p.vel.x + sin(elapsed * 6 + Double(p.id)) * dt, y: p.vel.y)
            }
            p.pos = p.pos + p.vel * dt
            particles[i] = p
        }
        particles.removeAll { $0.ttl <= 0 }
        for i in floatingTexts.indices {
            floatingTexts[i].ttl -= dt
            floatingTexts[i].pos.y -= 1.4 * dt
        }
        floatingTexts.removeAll { $0.ttl <= 0 }

        enemyDecisionTimer -= dt
        if enemyDecisionTimer <= 0 {
            enemyDecisionTimer = 0.7
            enemyDecide()
        }
        checkEndConditions()
    }

    private func enemyTowers(of side: Side) -> [Tower] { towers.filter { $0.side != side && $0.alive } }

    private func chooseTarget(for unit: Unit) -> (pos: Vec, radius: Double, unitTarget: Unit?, towerTarget: Tower?)? {
        let card = unit.card
        let isMelee = card.range <= 1.2
        if !card.buildingsOnly {
            var best: Unit? = nil
            var bestDist = Arena.aggroRange
            for other in units where other.alive && other.side != unit.side {
                if isMelee && other.flyingUnit { continue }
                let d = unit.pos.distance(to: other.pos)
                if d < bestDist { bestDist = d; best = other }
            }
            if let best { return (best.pos, best.radius, best, nil) }
        }
        let laneX = Arena.laneX(for: unit.pos.x)
        let enemies = enemyTowers(of: unit.side)
        guard !enemies.isEmpty else { return nil }
        if let laneTower = enemies.first(where: { $0.kind == .guardTower && abs($0.pos.x - laneX) < 0.1 }) {
            return (laneTower.pos, laneTower.kind.radius, nil, laneTower)
        }
        let nearest = enemies.min { $0.pos.distance(to: unit.pos) < $1.pos.distance(to: unit.pos) }!
        return (nearest.pos, nearest.kind.radius, nil, nearest)
    }

    private func stepUnit(_ unit: Unit, dt: Double) {
        unit.hitFlash = max(0, unit.hitFlash - dt)
        unit.attackCooldown = max(0, unit.attackCooldown - dt)
        unit.attackAnim = max(0, unit.attackAnim - dt)
        unit.spawnAge += dt
        unit.moving = false
        guard let target = chooseTarget(for: unit) else { return }
        let dist = unit.pos.distance(to: target.pos)
        let attackRange = unit.card.range + target.radius
        if target.pos.x != unit.pos.x { unit.facing = target.pos.x > unit.pos.x ? 1 : -1 }
        if dist <= attackRange + 0.05 {
            if unit.attackCooldown <= 0 {
                unit.attackCooldown = unit.card.hitSpeed
                unit.attackAnim = 0.25
                if unit.card.range > 1.2 {
                    let kind: ProjectileKind = unit.card.flying ? .fireball : .arrow
                    projectiles.append(Projectile(id: allocId(), kind: kind, start: unit.pos, pos: unit.pos, target: target.pos, side: unit.side, ttl: 1.0))
                } else {
                    spawnParticles(at: target.pos, kind: .spark, count: 3, speed: 3, ttl: 0.25, size: 0.1, color: .white)
                }
                if let u = target.unitTarget { damage(unit: u, amount: unit.card.damage) }
                if let t = target.towerTarget { damage(tower: t, amount: unit.card.damage) }
            }
            return
        }
        let waypoint = moveWaypoint(for: unit, toward: target.pos)
        let dir = (waypoint - unit.pos).normalized
        let stepLen = min(unit.card.speed * dt, unit.pos.distance(to: waypoint))
        unit.moving = stepLen > 0.0001
        unit.walkPhase += stepLen * 4
        if abs(dir.x) > 0.15 { unit.facing = dir.x > 0 ? 1 : -1 }
        unit.pos = unit.pos + dir * stepLen
        unit.pos.x = min(max(unit.pos.x, 0.4), Arena.width - 0.4)
        unit.pos.y = min(max(unit.pos.y, 0.4), Arena.height - 0.4)
    }

    private func moveWaypoint(for unit: Unit, toward target: Vec) -> Vec {
        if unit.card.flying { return target }
        let below = unit.pos.y > Arena.riverBottom
        let above = unit.pos.y < Arena.riverTop
        let targetBelow = target.y > Arena.riverCenter
        let targetAbove = target.y < Arena.riverCenter
        let inRiver = !below && !above
        if (below && targetAbove) || (above && targetBelow) || inRiver {
            let laneX = unit.laneX
            let exitY = (below || (inRiver && targetAbove)) ? Arena.riverTop - 0.6 : Arena.riverBottom + 0.6
            let entryY = below ? Arena.riverBottom + 0.4 : Arena.riverTop - 0.4
            if inRiver || abs(unit.pos.x - laneX) < 0.25 {
                return Vec(x: laneX, y: exitY)
            }
            return Vec(x: laneX, y: entryY)
        }
        return target
    }

    private func separateUnits() {
        let alive = units.filter { $0.alive }
        guard alive.count > 1 else { return }
        for i in 0..<(alive.count - 1) {
            for j in (i + 1)..<alive.count {
                let a = alive[i], b = alive[j]
                if a.card.flying != b.card.flying { continue }
                let minDist = a.radius + b.radius
                let delta = b.pos - a.pos
                let d = delta.length
                if d < minDist && d > 0.0001 {
                    let push = delta.normalized * ((minDist - d) * 0.5)
                    a.pos = a.pos - push
                    b.pos = b.pos + push
                } else if d <= 0.0001 {
                    a.pos.x -= 0.05
                    b.pos.x += 0.05
                }
            }
        }
    }

    private func stepTower(_ tower: Tower, dt: Double) {
        tower.hitFlash = max(0, tower.hitFlash - dt)
        tower.attackCooldown = max(0, tower.attackCooldown - dt)
        guard tower.activated else { return }
        var best: Unit? = nil
        var bestDist = Double.infinity
        for u in units where u.alive && u.side != tower.side {
            let d = tower.pos.distance(to: u.pos)
            if d <= tower.kind.range + u.radius && d < bestDist { bestDist = d; best = u }
        }
        guard let target = best else { return }
        if tower.attackCooldown <= 0 {
            tower.attackCooldown = tower.kind.hitSpeed
            let origin = Vec(x: tower.pos.x, y: tower.pos.y - tower.kind.radius * 0.9)
            projectiles.append(Projectile(id: allocId(), kind: tower.kind == .keep ? .cannon : .bolt, start: origin, pos: origin,
                                          target: target.pos, side: tower.side, ttl: 1.0))
            damage(unit: target, amount: tower.kind.damage)
        }
    }

    private func damage(unit: Unit, amount: Double) {
        guard unit.alive else { return }
        unit.hp -= amount
        unit.hitFlash = 0.15
        addDamageText(at: Vec(x: unit.pos.x, y: unit.pos.y - unit.radius - 0.4), amount: amount, side: unit.side)
    }

    private func damage(tower: Tower, amount: Double) {
        guard tower.alive else { return }
        tower.hp -= amount
        tower.hitFlash = 0.15
        tower.activated = true
        addDamageText(at: Vec(x: tower.pos.x, y: tower.pos.y - tower.kind.radius - 0.7), amount: amount, side: tower.side)
        spawnParticles(at: tower.pos, kind: .debris, count: 3, speed: 4, ttl: 0.6, size: 0.14, color: Color(white: 0.55))
        if tower.hp <= 0 {
            tower.hp = 0
            for t in towers where t.side == tower.side && t.kind == .keep { t.activated = true }
            effects.append(SpellEffect(id: allocId(), kind: .towerFall, pos: tower.pos, radius: tower.kind.radius * 2.0, side: tower.side))
            spawnParticles(at: tower.pos, kind: .debris, count: 18, speed: 7, ttl: 1.1, size: 0.22, color: Color(white: 0.5))
            spawnParticles(at: tower.pos, kind: .smoke, count: 14, speed: 1.6, ttl: 2.2, size: 0.9, color: Color(white: 0.35))
            spawnParticles(at: tower.pos, kind: .ember, count: 16, speed: 6, ttl: 0.9, size: 0.12, color: .orange)
            flash(tower.side == .player ? "Your \(tower.kind.name) fell!" : "Enemy \(tower.kind.name) destroyed!")
        }
    }

    /// Damage numbers landing near a fresh one for the same side are merged so clusters stay legible.
    private func addDamageText(at pos: Vec, amount: Double, side: Side) {
        if let i = floatingTexts.lastIndex(where: { $0.side == side && $0.age < 0.25 && $0.pos.distance(to: pos) < 1.2 }) {
            floatingTexts[i].amount += amount
            floatingTexts[i].ttl = floatingTexts[i].maxTtl
            return
        }
        let jitter = Double(floatingTexts.count % 3 - 1) * 0.45
        floatingTexts.append(FloatingText(id: allocId(), pos: Vec(x: pos.x + jitter, y: pos.y), amount: amount, side: side,
                                          color: side == .player ? Color(red: 1.0, green: 0.45, blue: 0.4) : Color(red: 1.0, green: 0.92, blue: 0.5),
                                          ttl: 0.7, maxTtl: 0.7))
        if floatingTexts.count > 24 { floatingTexts.removeFirst(floatingTexts.count - 24) }
    }

    private func spawnParticles(at pos: Vec, kind: ParticleKind, count: Int, speed: Double, ttl: Double, size: Double, color: Color, upward: Bool = false) {
        for _ in 0..<count {
            let angle = Double.random(in: 0..<(2 * Double.pi), using: &rng)
            let s = Double.random(in: 0.3...1.0, using: &rng) * speed
            var vel = Vec(x: cos(angle) * s, y: sin(angle) * s)
            if upward || kind == .debris || kind == .bone { vel.y = -abs(vel.y) - speed * 0.4 }
            if kind == .smoke { vel.y = -abs(vel.y) * 0.6 - 0.4 }
            let life = ttl * Double.random(in: 0.6...1.0, using: &rng)
            particles.append(Particle(id: allocId(), kind: kind, pos: pos, vel: vel, ttl: life, maxTtl: life,
                                      size: size * Double.random(in: 0.7...1.3, using: &rng), color: color))
        }
        if particles.count > 400 { particles.removeFirst(particles.count - 400) }
    }

    private func spawnImpact(_ p: Projectile) {
        switch p.kind {
        case .fireball:
            spawnParticles(at: p.target, kind: .ember, count: 6, speed: 3, ttl: 0.35, size: 0.12, color: .orange)
        case .cannon:
            spawnParticles(at: p.target, kind: .dust, count: 6, speed: 2.5, ttl: 0.4, size: 0.3, color: Color(white: 0.8))
        case .arrow, .bolt:
            spawnParticles(at: p.target, kind: .spark, count: 3, speed: 2.5, ttl: 0.2, size: 0.08, color: .white)
        }
    }

    private func spawnDeath(_ unit: Unit) {
        let color = unit.side == .player ? Theme.player : Theme.enemy
        if unit.card.id == "bones" {
            spawnParticles(at: unit.pos, kind: .bone, count: 5, speed: 3.5, ttl: 0.7, size: 0.16, color: Color(white: 0.95))
        } else if unit.card.id == "giant" {
            spawnParticles(at: unit.pos, kind: .debris, count: 10, speed: 4, ttl: 0.8, size: 0.2, color: Color(white: 0.55))
        }
        spawnParticles(at: unit.pos, kind: .dust, count: 6, speed: 1.6, ttl: 0.6, size: 0.35, color: Color(white: 0.9))
        spawnParticles(at: unit.pos, kind: .glow, count: 5, speed: 2.2, ttl: 0.45, size: 0.18, color: color)
    }

    private func resolveSpell(_ e: SpellEffect) {
        guard e.damage > 0 else { return }
        for u in units where u.alive && u.side != e.side && u.pos.distance(to: e.pos) <= e.radius + u.radius {
            damage(unit: u, amount: e.damage)
        }
        for t in towers where t.alive && t.side != e.side && t.pos.distance(to: e.pos) <= e.radius + t.kind.radius {
            damage(tower: t, amount: e.damage * Arena.towerSpellFactor)
        }
        switch e.kind {
        case .meteor:
            spawnParticles(at: e.pos, kind: .ember, count: 26, speed: 7, ttl: 0.9, size: 0.16, color: .orange)
            spawnParticles(at: e.pos, kind: .smoke, count: 10, speed: 2.2, ttl: 1.4, size: 0.8, color: Color(white: 0.3))
            spawnParticles(at: e.pos, kind: .debris, count: 8, speed: 6, ttl: 0.8, size: 0.16, color: Color(red: 0.35, green: 0.25, blue: 0.2))
        case .volley:
            spawnParticles(at: e.pos, kind: .dust, count: 14, speed: 3.5, ttl: 0.5, size: 0.3, color: Color(white: 0.85))
        case .towerFall, .deploy:
            break
        }
    }

    func play(_ card: CardDef, side: Side, at pos: Vec) {
        switch card.kind {
        case .spell:
            effects.append(SpellEffect(id: allocId(), kind: card.id == "meteor" ? .meteor : .volley, pos: pos,
                                       radius: card.radius, side: side, damage: card.damage))
        case .troop:
            effects.append(SpellEffect(id: allocId(), kind: .deploy, pos: pos, radius: card.count > 1 ? 1.1 : 0.8, side: side))
            spawnParticles(at: pos, kind: .dust, count: 8, speed: 2.5, ttl: 0.5, size: 0.3, color: Color(white: 0.9))
            let n = card.count
            for i in 0..<n {
                let angle = Double(i) / Double(max(n, 1)) * 2 * Double.pi
                let spread = n > 1 ? 0.6 : 0
                let p = Vec(x: pos.x + cos(angle) * spread, y: pos.y + sin(angle) * spread)
                let unit = Unit(id: allocId(), card: card, side: side, pos: p)
                unit.laneX = Arena.laneX(for: pos.x)
                unit.facing = side == .player ? 1 : -1
                units.append(unit)
            }
        }
    }

    // MARK: - Enemy AI

    private func enemyDecide() {
        let playerUnits = units.filter { $0.alive && $0.side == .player }
        let threats = playerUnits.filter { $0.pos.y < Arena.riverBottom + 3 }

        // Spell on clusters.
        if let spellIndex = enemyHand.firstIndex(where: { Cards.byId($0).kind == .spell }) {
            let spell = Cards.byId(enemyHand[spellIndex])
            if enemyElixir >= Double(spell.cost) {
                for anchor in playerUnits {
                    let cluster = playerUnits.filter { $0.pos.distance(to: anchor.pos) <= spell.radius }
                    let value = cluster.reduce(0.0) { $0 + Double($1.card.cost) / Double($1.card.count) }
                    if cluster.count >= 3 || value >= Double(spell.cost) + 1 {
                        var cx = 0.0, cy = 0.0
                        for c in cluster { cx += c.pos.x; cy += c.pos.y }
                        let center = Vec(x: cx / Double(cluster.count), y: cy / Double(cluster.count))
                        enemyPlay(index: spellIndex, at: center)
                        return
                    }
                }
            }
        }

        let affordable = enemyHand.enumerated().filter {
            let c = Cards.byId($0.element)
            return c.kind == .troop && enemyElixir >= Double(c.cost)
        }
        guard !affordable.isEmpty else { return }
        let underPressure = !threats.isEmpty
        let eager = enemyElixir >= 8
        guard underPressure || eager || (enemyElixir >= 5 && Double.random(in: 0..<1, using: &rng) < 0.25) else { return }

        let laneX: Double
        if underPressure {
            let left = threats.filter { $0.pos.x < Arena.width / 2 }.count
            laneX = left >= threats.count - left ? Arena.bridgeXs[0] : Arena.bridgeXs[1]
        } else {
            laneX = Arena.bridgeXs.randomElement(using: &rng)!
        }
        let pick = underPressure
            ? affordable.max { Cards.byId($0.element).cost < Cards.byId($1.element).cost }!
            : affordable.randomElement(using: &rng)!
        let card = Cards.byId(pick.element)
        let y = underPressure ? Double.random(in: 9...12, using: &rng) : Double.random(in: 8...13, using: &rng)
        let x = min(max(laneX + Double.random(in: -1.2...1.2, using: &rng), 1), Arena.width - 1)
        enemyPlay(index: pick.offset, at: Vec(x: x, y: card.buildingsOnly ? 13 : y))
    }

    private func enemyPlay(index: Int, at pos: Vec) {
        let card = Cards.byId(enemyHand[index])
        enemyElixir -= Double(card.cost)
        play(card, side: .enemy, at: pos)
        let played = enemyHand.remove(at: index)
        let next = enemyQueue.removeFirst()
        enemyHand.insert(next, at: index)
        enemyQueue.append(played)
    }

    // MARK: - End conditions

    private func checkEndConditions() {
        let pc = crowns(for: .player)
        let ec = crowns(for: .enemy)
        if pc == 3 || ec == 3 {
            finish(pc: pc, ec: ec)
            return
        }
        if !isOvertime && elapsed >= Arena.regulationSeconds {
            if pc != ec { finish(pc: pc, ec: ec); return }
            isOvertime = true
            flash("OVERTIME! Next tower wins")
        }
        if isOvertime {
            if pc != ec { finish(pc: pc, ec: ec); return }
            if elapsed >= Arena.regulationSeconds + Arena.overtimeSeconds { finish(pc: pc, ec: ec) }
        }
    }

    /// Forfeits the match: recorded as a defeat with the enemy awarded a full 3 crowns.
    func surrender() {
        guard result == nil else { return }
        finish(pc: crowns(for: .player), ec: 3)
    }

    private func finish(pc: Int, ec: Int) {
        let outcome: MatchOutcome = pc > ec ? .victory : (pc < ec ? .defeat : .draw)
        let trophy = outcome == .victory ? 30 : (outcome == .defeat ? -20 : 0)
        let gold = outcome == .victory ? 50 : (outcome == .defeat ? 10 : 20)
        result = MatchResult(outcome: outcome, playerCrowns: pc, enemyCrowns: ec, trophyDelta: trophy,
                             goldDelta: gold, durationSeconds: Int(elapsed))
        stop()
        objectWillChange.send()
    }
}

extension Unit {
    var flyingUnit: Bool { card.flying }
}
