package com.dabit3.towertussle

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.setValue
import kotlin.math.max

class PlayerProfile(context: Context) {
    private object Keys {
        const val TROPHIES = "tt.trophies"
        const val GOLD = "tt.gold"
        const val WINS = "tt.wins"
        const val LOSSES = "tt.losses"
        const val DRAWS = "tt.draws"
        const val DECK = "tt.deck"
    }

    private val prefs: SharedPreferences = context.getSharedPreferences("tower_tussle", Context.MODE_PRIVATE)

    var trophies by mutableIntStateOf(prefs.getInt(Keys.TROPHIES, 0)); private set
    var gold by mutableIntStateOf(prefs.getInt(Keys.GOLD, 100)); private set
    var wins by mutableIntStateOf(prefs.getInt(Keys.WINS, 0)); private set
    var losses by mutableIntStateOf(prefs.getInt(Keys.LOSSES, 0)); private set
    var draws by mutableIntStateOf(prefs.getInt(Keys.DRAWS, 0)); private set
    val deck = mutableStateListOf<String>()

    init {
        val saved = prefs.getString(Keys.DECK, null)?.split(",")?.filter { it.isNotBlank() } ?: emptyList()
        val valid = saved.size == 8 && saved.all { id -> Cards.all.any { it.id == id } }
        deck.addAll(if (valid) saved else Cards.defaultDeck)
    }

    val collection: List<String> get() = Cards.all.map { it.id }.filter { it !in deck }

    val averageElixir: Double get() = deck.sumOf { Cards.byId(it).cost }.toDouble() / max(deck.size, 1)

    fun apply(result: MatchResult) {
        trophies = max(0, trophies + result.trophyDelta)
        gold += result.goldDelta
        when (result.outcome) {
            MatchOutcome.VICTORY -> wins++
            MatchOutcome.DEFEAT -> losses++
            MatchOutcome.DRAW -> draws++
        }
        save()
    }

    fun swap(deckCard: String, collectionCard: String) {
        val i = deck.indexOf(deckCard)
        if (i < 0 || collectionCard !in collection) return
        deck[i] = collectionCard
        save()
    }

    fun resetDeck() {
        deck.clear()
        deck.addAll(Cards.defaultDeck)
        save()
    }

    private fun save() {
        prefs.edit()
            .putInt(Keys.TROPHIES, trophies)
            .putInt(Keys.GOLD, gold)
            .putInt(Keys.WINS, wins)
            .putInt(Keys.LOSSES, losses)
            .putInt(Keys.DRAWS, draws)
            .putString(Keys.DECK, deck.joinToString(","))
            .apply()
    }
}
