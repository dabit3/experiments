package com.dabit3.towertussle

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BattleEngineTest {
    private fun engine() = BattleEngine(Cards.defaultDeck)

    private fun BattleEngine.advance(seconds: Double) {
        var t = 0.0
        while (t < seconds) {
            step(1.0 / 60.0)
            t += 1.0 / 60.0
        }
    }

    @Test
    fun startsWithHandNextCardAndTowers() {
        val e = engine()
        assertEquals(4, e.hand.size)
        assertTrue(e.nextCard.isNotEmpty())
        assertTrue(e.hand.none { it == e.nextCard })
        assertEquals(6, e.towers.size)
        assertEquals(5.0, e.playerElixir, 1e-9)
        assertEquals(180, e.remainingSeconds)
        assertNull(e.result)
    }

    @Test
    fun elixirRegeneratesAndCaps() {
        val e = engine()
        e.advance(5.0)
        assertTrue(e.playerElixir > 5.0)
        e.advance(30.0)
        assertEquals(Arena.MAX_ELIXIR, e.playerElixir, 1e-9)
    }

    @Test
    fun troopsMustDeployOnPlayerSideButSpellsAnywhere() {
        val e = engine()
        val troop = Cards.byId("knight")
        val spell = Cards.byId("meteor")
        assertFalse(e.isValidDeploy(troop, Vec(9.0, 5.0)))
        assertTrue(e.isValidDeploy(troop, Vec(9.0, 24.0)))
        assertTrue(e.isValidDeploy(spell, Vec(9.0, 5.0)))
        assertFalse(e.isValidDeploy(spell, Vec(-1.0, 5.0)))
    }

    @Test
    fun deployingCyclesHandAndSpendsElixir() {
        val e = engine()
        e.advance(20.0)
        val index = e.hand.indices.first { Cards.byId(e.hand[it]).kind == CardKind.TROOP }
        val card = Cards.byId(e.hand[index])
        val expectedNext = e.nextCard
        val before = e.playerElixir
        e.selectHand(index)
        assertEquals(index, e.selectedHandIndex)
        assertTrue(e.deployAtTap(Vec(9.0, 24.0)))
        assertEquals(before - card.cost, e.playerElixir, 1e-9)
        assertEquals(expectedNext, e.hand[index])
        assertNull(e.selectedHandIndex)
        assertTrue(e.units.any { it.side == Side.PLAYER && it.card.id == card.id })
    }

    @Test
    fun rejectsTroopDeployOnEnemySide() {
        val e = engine()
        e.advance(20.0)
        val index = e.hand.indices.first { Cards.byId(e.hand[it]).kind == CardKind.TROOP }
        e.selectHand(index)
        assertFalse(e.deployAtTap(Vec(9.0, 5.0)))
        assertEquals("Deploy on your side", e.announcement)
        assertEquals(index, e.selectedHandIndex)
    }

    @Test
    fun rejectsDeployWithoutSelection() {
        val e = engine()
        assertFalse(e.deployAtTap(Vec(9.0, 24.0)))
        assertTrue(e.units.isEmpty())
    }

    @Test
    fun doubleElixirAndOvertimeTiming() {
        val e = engine()
        assertFalse(e.isDoubleElixir)
        e.advance(121.0)
        assertTrue(e.isDoubleElixir)
    }

    @Test
    fun matchEndsWithResultAfterOvertimeAtLatest() {
        val e = engine()
        e.advance(Arena.REGULATION_SECONDS + Arena.OVERTIME_SECONDS + 2.0)
        val r = e.result
        assertNotNull(r)
        assertTrue(r!!.playerCrowns in 0..3)
        assertTrue(r.enemyCrowns in 0..3)
        assertTrue(r.durationSeconds > 0)
    }

    @Test
    fun surrenderRecordsDefeat() {
        val e = engine()
        e.advance(3.0)
        e.surrender()
        val r = e.result
        assertNotNull(r)
        assertEquals(MatchOutcome.DEFEAT, r!!.outcome)
        assertEquals(3, r.enemyCrowns)
        assertEquals(-20, r.trophyDelta)
        e.surrender()
        assertEquals(r, e.result)
    }

    @Test
    fun destroyingKeepAwardsThreeCrowns() {
        val e = engine()
        val keep = e.towers.first { it.side == Side.ENEMY && it.kind == TowerKind.KEEP }
        keep.hp = 0.0
        assertEquals(3, e.crowns(Side.PLAYER))
    }
}
