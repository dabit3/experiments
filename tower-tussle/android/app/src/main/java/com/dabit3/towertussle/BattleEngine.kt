package com.dabit3.towertussle

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.random.Random

object Arena {
    const val WIDTH = 18.0
    const val HEIGHT = 32.0
    const val RIVER_TOP = 15.0
    const val RIVER_BOTTOM = 17.0
    const val RIVER_CENTER = 16.0
    val BRIDGE_XS = listOf(3.5, 14.5)
    const val BRIDGE_HALF_WIDTH = 1.0
    const val PLAYER_DEPLOY_MIN_Y = 17.2
    const val REGULATION_SECONDS = 180.0
    const val OVERTIME_SECONDS = 60.0
    const val MAX_ELIXIR = 10.0
    const val ELIXIR_PER_SECOND = 1.0 / 2.8
    const val AGGRO_RANGE = 6.0
    const val TOWER_SPELL_FACTOR = 0.35

    fun laneX(x: Double): Double = if (x < WIDTH / 2) BRIDGE_XS[0] else BRIDGE_XS[1]

    fun towerPositions(side: Side): List<Pair<TowerKind, Vec>> = when (side) {
        Side.PLAYER -> listOf(TowerKind.GUARD to Vec(3.5, 25.5), TowerKind.GUARD to Vec(14.5, 25.5), TowerKind.KEEP to Vec(9.0, 29.5))
        Side.ENEMY -> listOf(TowerKind.GUARD to Vec(3.5, 6.5), TowerKind.GUARD to Vec(14.5, 6.5), TowerKind.KEEP to Vec(9.0, 2.5))
    }
}

private class Target(val pos: Vec, val radius: Double, val unit: Troop?, val tower: Tower?)

/**
 * Real-time match simulator. Mutations happen on the main thread from the
 * frame loop; [version] is bumped once per frame so Compose recomposes.
 */
class BattleEngine(val deck: List<String>) {
    var version by mutableIntStateOf(0)
        private set

    val units = mutableListOf<Troop>()
    val towers = mutableListOf<Tower>()
    val effects = mutableListOf<SpellEffect>()
    val projectiles = mutableListOf<Projectile>()
    var elapsed = 0.0; private set
    var playerElixir = 5.0; private set
    var enemyElixir = 5.0; private set
    val hand = mutableListOf<String>()
    var nextCard: String = ""; private set
    private val queue = mutableListOf<String>()
    private val enemyHand = mutableListOf<String>()
    private val enemyQueue = mutableListOf<String>()
    var selectedHandIndex: Int? = null; private set
    var result: MatchResult? = null; private set
    var isOvertime = false; private set
    var announcement: String? = null; private set
    private var announcementTTL = 0.0
    private var nextId = 1
    private var enemyDecisionTimer = 0.0
    private var lastTickNanos: Long? = null
    private val rng = Random.Default

    init { reset() }

    fun reset() {
        units.clear(); effects.clear(); projectiles.clear()
        elapsed = 0.0
        playerElixir = 5.0
        enemyElixir = 5.0
        result = null
        isOvertime = false
        announcement = null
        selectedHandIndex = null
        nextId = 1
        enemyDecisionTimer = 1.5
        lastTickNanos = null
        towers.clear()
        for (side in listOf(Side.PLAYER, Side.ENEMY)) {
            for ((kind, pos) in Arena.towerPositions(side)) towers.add(Tower(allocId(), kind, side, pos))
        }
        val shuffled = deck.shuffled(rng).toMutableList()
        hand.clear(); hand.addAll(shuffled.take(4))
        repeat(4) { shuffled.removeAt(0) }
        nextCard = shuffled.firstOrNull() ?: deck[0]
        queue.clear(); queue.addAll(shuffled)
        val enemyDeck = Cards.all.map { it.id }.shuffled(rng).take(8).toMutableList()
        if (enemyDeck.none { Cards.byId(it).kind == CardKind.SPELL }) enemyDeck[0] = "meteor"
        enemyDeck.shuffle(rng)
        enemyHand.clear(); enemyHand.addAll(enemyDeck.take(4))
        enemyQueue.clear(); enemyQueue.addAll(enemyDeck.drop(4))
        bump()
    }

    private fun bump() { version++ }

    private fun allocId(): Int = nextId++

    // Derived state

    val remainingSeconds: Int
        get() {
            val total = if (isOvertime) Arena.REGULATION_SECONDS + Arena.OVERTIME_SECONDS else Arena.REGULATION_SECONDS
            return max(0, ceil(total - elapsed).toInt())
        }

    val isDoubleElixir: Boolean get() = isOvertime || elapsed >= Arena.REGULATION_SECONDS - 60

    fun crowns(side: Side): Int {
        val destroyed = towers.filter { it.side == side.opposite && !it.alive }
        if (destroyed.any { it.kind == TowerKind.KEEP }) return 3
        return destroyed.size
    }

    val selectedCard: CardDef?
        get() {
            val i = selectedHandIndex ?: return null
            if (i >= hand.size) return null
            return Cards.byId(hand[i])
        }

    // Player input

    fun selectHand(index: Int) {
        selectedHandIndex = if (selectedHandIndex == index) null else index
        bump()
    }

    fun canAfford(card: CardDef): Boolean = playerElixir >= card.cost

    fun isValidDeploy(card: CardDef, pos: Vec): Boolean {
        if (pos.x < 0.3 || pos.x > Arena.WIDTH - 0.3 || pos.y < 0.3 || pos.y > Arena.HEIGHT - 0.3) return false
        if (card.kind == CardKind.SPELL) return true
        return pos.y >= Arena.PLAYER_DEPLOY_MIN_Y
    }

    fun deployAtTap(pos: Vec): Boolean {
        if (result != null) return false
        val index = selectedHandIndex ?: return false
        if (index >= hand.size) return false
        val card = Cards.byId(hand[index])
        if (!canAfford(card) || !isValidDeploy(card, pos)) {
            flash(if (!canAfford(card)) "Not enough elixir" else "Deploy on your side")
            bump()
            return false
        }
        playerElixir -= card.cost
        play(card, Side.PLAYER, pos)
        val played = hand.removeAt(index)
        hand.add(index, nextCard)
        queue.removeAt(0)
        queue.add(played)
        nextCard = queue.firstOrNull() ?: played
        selectedHandIndex = null
        bump()
        return true
    }

    private fun flash(text: String) {
        announcement = text
        announcementTTL = 1.2
    }

    // Simulation

    /** Called once per display frame with a monotonic nanosecond timestamp. */
    fun frame(nowNanos: Long) {
        val last = lastTickNanos
        lastTickNanos = nowNanos
        if (last == null) return
        val dt = min((nowNanos - last) / 1_000_000_000.0, 0.1)
        if (result != null) return
        step(dt)
        bump()
    }

    fun step(dt: Double) {
        elapsed += dt
        val rate = Arena.ELIXIR_PER_SECOND * (if (isDoubleElixir) 2 else 1)
        playerElixir = min(Arena.MAX_ELIXIR, playerElixir + rate * dt)
        enemyElixir = min(Arena.MAX_ELIXIR, enemyElixir + rate * dt)

        if (announcementTTL > 0) {
            announcementTTL -= dt
            if (announcementTTL <= 0) announcement = null
        }

        for (unit in units.toList()) if (unit.alive) stepUnit(unit, dt)
        separateUnits()
        for (tower in towers) if (tower.alive) stepTower(tower, dt)

        for (e in effects) e.ttl -= dt
        effects.removeAll { it.ttl <= 0 }
        for (p in projectiles) {
            val dir = (p.target - p.pos).normalized
            p.pos = p.pos + dir * (18 * dt)
            p.ttl -= dt
        }
        projectiles.removeAll { it.ttl <= 0 || it.pos.distance(it.target) < 0.4 }
        units.removeAll { !it.alive }

        enemyDecisionTimer -= dt
        if (enemyDecisionTimer <= 0) {
            enemyDecisionTimer = 0.7
            enemyDecide()
        }
        checkEndConditions()
    }

    private fun enemyTowers(side: Side): List<Tower> = towers.filter { it.side != side && it.alive }

    private fun chooseTarget(unit: Troop): Target? {
        val card = unit.card
        if (!card.buildingsOnly) {
            var best: Troop? = null
            var bestDist = Arena.AGGRO_RANGE
            for (other in units) {
                if (!other.alive || other.side == unit.side) continue
                if (card.isMelee && other.card.flying) continue
                val d = unit.pos.distance(other.pos)
                if (d < bestDist) { bestDist = d; best = other }
            }
            if (best != null) return Target(best.pos, best.radius, best, null)
        }
        val laneX = Arena.laneX(unit.pos.x)
        val enemies = enemyTowers(unit.side)
        if (enemies.isEmpty()) return null
        val laneTower = enemies.firstOrNull { it.kind == TowerKind.GUARD && abs(it.pos.x - laneX) < 0.1 }
        if (laneTower != null) return Target(laneTower.pos, laneTower.kind.radius, null, laneTower)
        val nearest = enemies.minByOrNull { it.pos.distance(unit.pos) }!!
        return Target(nearest.pos, nearest.kind.radius, null, nearest)
    }

    private fun stepUnit(unit: Troop, dt: Double) {
        unit.hitFlash = max(0.0, unit.hitFlash - dt)
        unit.attackCooldown = max(0.0, unit.attackCooldown - dt)
        val target = chooseTarget(unit) ?: return
        val dist = unit.pos.distance(target.pos)
        val attackRange = unit.card.range + target.radius
        if (dist <= attackRange + 0.05) {
            if (unit.attackCooldown <= 0) {
                unit.attackCooldown = unit.card.hitSpeed
                if (unit.card.range > 1.2) {
                    projectiles.add(Projectile(allocId(), unit.pos, target.pos, unit.side, 1.0))
                }
                target.unit?.let { damageUnit(it, unit.card.damage) }
                target.tower?.let { damageTower(it, unit.card.damage) }
            }
            return
        }
        val waypoint = moveWaypoint(unit, target.pos)
        val dir = (waypoint - unit.pos).normalized
        val stepLen = min(unit.card.speed * dt, unit.pos.distance(waypoint))
        val np = unit.pos + dir * stepLen
        unit.pos = Vec(np.x.coerceIn(0.4, Arena.WIDTH - 0.4), np.y.coerceIn(0.4, Arena.HEIGHT - 0.4))
    }

    private fun moveWaypoint(unit: Troop, target: Vec): Vec {
        if (unit.card.flying) return target
        val below = unit.pos.y > Arena.RIVER_BOTTOM
        val above = unit.pos.y < Arena.RIVER_TOP
        val targetBelow = target.y > Arena.RIVER_CENTER
        val targetAbove = target.y < Arena.RIVER_CENTER
        val inRiver = !below && !above
        if ((below && targetAbove) || (above && targetBelow) || inRiver) {
            val laneX = unit.laneX
            val exitY = if (below || (inRiver && targetAbove)) Arena.RIVER_TOP - 0.6 else Arena.RIVER_BOTTOM + 0.6
            val entryY = if (below) Arena.RIVER_BOTTOM + 0.4 else Arena.RIVER_TOP - 0.4
            if (inRiver || abs(unit.pos.x - laneX) < 0.25) return Vec(laneX, exitY)
            return Vec(laneX, entryY)
        }
        return target
    }

    private fun separateUnits() {
        val alive = units.filter { it.alive }
        if (alive.size < 2) return
        for (i in 0 until alive.size - 1) {
            for (j in i + 1 until alive.size) {
                val a = alive[i]; val b = alive[j]
                if (a.card.flying != b.card.flying) continue
                val minDist = a.radius + b.radius
                val delta = b.pos - a.pos
                val d = delta.length
                if (d < minDist && d > 0.0001) {
                    val push = delta.normalized * ((minDist - d) * 0.5)
                    a.pos = a.pos - push
                    b.pos = b.pos + push
                } else if (d <= 0.0001) {
                    a.pos = Vec(a.pos.x - 0.05, a.pos.y)
                    b.pos = Vec(b.pos.x + 0.05, b.pos.y)
                }
            }
        }
    }

    private fun stepTower(tower: Tower, dt: Double) {
        tower.hitFlash = max(0.0, tower.hitFlash - dt)
        tower.attackCooldown = max(0.0, tower.attackCooldown - dt)
        if (!tower.activated) return
        var best: Troop? = null
        var bestDist = Double.POSITIVE_INFINITY
        for (u in units) {
            if (!u.alive || u.side == tower.side) continue
            val d = tower.pos.distance(u.pos)
            if (d <= tower.kind.range + u.radius && d < bestDist) { bestDist = d; best = u }
        }
        val target = best ?: return
        if (tower.attackCooldown <= 0) {
            tower.attackCooldown = tower.kind.hitSpeed
            projectiles.add(Projectile(allocId(), tower.pos, target.pos, tower.side, 1.0))
            damageUnit(target, tower.kind.damage)
        }
    }

    private fun damageUnit(unit: Troop, amount: Double) {
        if (!unit.alive) return
        unit.hp -= amount
        unit.hitFlash = 0.15
    }

    private fun damageTower(tower: Tower, amount: Double) {
        if (!tower.alive) return
        tower.hp -= amount
        tower.hitFlash = 0.15
        tower.activated = true
        if (tower.hp <= 0) {
            tower.hp = 0.0
            for (t in towers) if (t.side == tower.side && t.kind == TowerKind.KEEP) t.activated = true
            effects.add(SpellEffect(allocId(), tower.pos, 2.2, Theme.orange, 0.8))
            flash(if (tower.side == Side.PLAYER) "Your ${tower.kind.label} fell!" else "Enemy ${tower.kind.label} destroyed!")
        }
    }

    fun play(card: CardDef, side: Side, pos: Vec) {
        when (card.kind) {
            CardKind.SPELL -> {
                effects.add(SpellEffect(allocId(), pos, card.radius, if (card.id == "meteor") Theme.orange else Color.Cyan, 0.7))
                for (u in units) {
                    if (u.alive && u.side != side && u.pos.distance(pos) <= card.radius + u.radius) damageUnit(u, card.damage)
                }
                for (t in towers) {
                    if (t.alive && t.side != side && t.pos.distance(pos) <= card.radius + t.kind.radius) {
                        damageTower(t, card.damage * Arena.TOWER_SPELL_FACTOR)
                    }
                }
            }
            CardKind.TROOP -> {
                val n = card.count
                for (i in 0 until n) {
                    val angle = i.toDouble() / max(n, 1) * 2 * Math.PI
                    val spread = if (n > 1) 0.6 else 0.0
                    val p = Vec(pos.x + cos(angle) * spread, pos.y + sin(angle) * spread)
                    val unit = Troop(allocId(), card, side, p)
                    unit.laneX = Arena.laneX(pos.x)
                    units.add(unit)
                }
            }
        }
    }

    // Enemy AI

    private fun enemyDecide() {
        val playerUnits = units.filter { it.alive && it.side == Side.PLAYER }
        val threats = playerUnits.filter { it.pos.y < Arena.RIVER_BOTTOM + 3 }

        val spellIndex = enemyHand.indexOfFirst { Cards.byId(it).kind == CardKind.SPELL }
        if (spellIndex >= 0) {
            val spell = Cards.byId(enemyHand[spellIndex])
            if (enemyElixir >= spell.cost) {
                for (anchor in playerUnits) {
                    val cluster = playerUnits.filter { it.pos.distance(anchor.pos) <= spell.radius }
                    val value = cluster.sumOf { it.card.cost.toDouble() / it.card.count }
                    if (cluster.size >= 3 || value >= spell.cost + 1) {
                        val cx = cluster.sumOf { it.pos.x } / cluster.size
                        val cy = cluster.sumOf { it.pos.y } / cluster.size
                        enemyPlay(spellIndex, Vec(cx, cy))
                        return
                    }
                }
            }
        }

        val affordable = enemyHand.withIndex().filter {
            val c = Cards.byId(it.value)
            c.kind == CardKind.TROOP && enemyElixir >= c.cost
        }
        if (affordable.isEmpty()) return
        val underPressure = threats.isNotEmpty()
        val eager = enemyElixir >= 8
        if (!(underPressure || eager || (enemyElixir >= 5 && rng.nextDouble() < 0.25))) return

        val laneX = if (underPressure) {
            val left = threats.count { it.pos.x < Arena.WIDTH / 2 }
            if (left >= threats.size - left) Arena.BRIDGE_XS[0] else Arena.BRIDGE_XS[1]
        } else {
            Arena.BRIDGE_XS.random(rng)
        }
        val pick = if (underPressure) affordable.maxByOrNull { Cards.byId(it.value).cost }!! else affordable.random(rng)
        val card = Cards.byId(pick.value)
        val y = if (underPressure) rng.nextDouble(9.0, 12.0) else rng.nextDouble(8.0, 13.0)
        val x = (laneX + rng.nextDouble(-1.2, 1.2)).coerceIn(1.0, Arena.WIDTH - 1)
        enemyPlay(pick.index, Vec(x, if (card.buildingsOnly) 13.0 else y))
    }

    private fun enemyPlay(index: Int, pos: Vec) {
        val card = Cards.byId(enemyHand[index])
        enemyElixir -= card.cost
        play(card, Side.ENEMY, pos)
        val played = enemyHand.removeAt(index)
        val next = enemyQueue.removeAt(0)
        enemyHand.add(index, next)
        enemyQueue.add(played)
    }

    // End conditions

    private fun checkEndConditions() {
        val pc = crowns(Side.PLAYER)
        val ec = crowns(Side.ENEMY)
        if (pc == 3 || ec == 3) { finish(pc, ec); return }
        if (!isOvertime && elapsed >= Arena.REGULATION_SECONDS) {
            if (pc != ec) { finish(pc, ec); return }
            isOvertime = true
            flash("OVERTIME! Next tower wins")
        }
        if (isOvertime) {
            if (pc != ec) { finish(pc, ec); return }
            if (elapsed >= Arena.REGULATION_SECONDS + Arena.OVERTIME_SECONDS) finish(pc, ec)
        }
    }

    /** Forfeits the match: recorded as a defeat with the enemy awarded a full 3 crowns. */
    fun surrender() {
        if (result != null) return
        finish(crowns(Side.PLAYER), 3)
    }

    private fun finish(pc: Int, ec: Int) {
        val outcome = when {
            pc > ec -> MatchOutcome.VICTORY
            pc < ec -> MatchOutcome.DEFEAT
            else -> MatchOutcome.DRAW
        }
        val trophy = when (outcome) { MatchOutcome.VICTORY -> 30; MatchOutcome.DEFEAT -> -20; MatchOutcome.DRAW -> 0 }
        val gold = when (outcome) { MatchOutcome.VICTORY -> 50; MatchOutcome.DEFEAT -> 10; MatchOutcome.DRAW -> 20 }
        result = MatchResult(outcome, pc, ec, trophy, gold, elapsed.toInt())
        bump()
    }
}
