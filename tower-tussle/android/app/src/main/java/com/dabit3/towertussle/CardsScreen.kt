package com.dabit3.towertussle

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CardsScreen(onBack: () -> Unit) {
    val profile = LocalProfile.current
    var selectedDeckCard by remember { mutableStateOf<String?>(null) }
    var detailCard by remember { mutableStateOf<CardDef?>(null) }

    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                "‹ Home", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.clickable(onClick = onBack).padding(4.dp).testTag("backButton"),
            )
            Spacer(Modifier.weight(1f))
            Text("CARDS", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Black)
            Spacer(Modifier.weight(1f))
            Text(
                "Reset", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { profile.resetDeck(); selectedDeckCard = null }.padding(4.dp).testTag("resetDeckButton"),
            )
        }

        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 30.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text("Battle Deck", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.weight(1f))
                Text(
                    String.format(Locale.US, "Avg elixir %.1f", profile.averageElixir),
                    color = Theme.elixir, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.testTag("avgElixir"),
                )
            }

            CardGrid(profile.deck.toList()) { id ->
                CardTile(
                    card = Cards.byId(id), selected = selectedDeckCard == id, dimmed = false,
                    modifier = Modifier.testTag("deck-$id"),
                    onClick = { if (selectedDeckCard == id) detailCard = Cards.byId(id) else selectedDeckCard = id },
                )
            }

            Text(
                if (selectedDeckCard == null) "Tap a deck card, then a collection card to swap. Tap a selected card again for details."
                else "Now tap a collection card to swap it into your deck.",
                color = Color.White.copy(alpha = 0.6f), fontSize = 12.sp,
            )

            Text("Collection", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 8.dp))

            CardGrid(profile.collection) { id ->
                CardTile(
                    card = Cards.byId(id), selected = false, dimmed = selectedDeckCard == null,
                    modifier = Modifier.testTag("collection-$id"),
                    onClick = {
                        val deckCard = selectedDeckCard
                        if (deckCard != null) {
                            profile.swap(deckCard, id)
                            selectedDeckCard = null
                        } else {
                            detailCard = Cards.byId(id)
                        }
                    },
                )
            }
        }
    }

    detailCard?.let { card ->
        ModalBottomSheet(onDismissRequest = { detailCard = null }, containerColor = Theme.background) {
            CardDetailSheet(card)
        }
    }
}

@Composable
private fun CardGrid(ids: List<String>, tile: @Composable (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        for (row in ids.chunked(4)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                for (id in row) Box(Modifier.weight(1f)) { tile(id) }
                repeat(4 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

@Composable
fun CardTile(card: CardDef, selected: Boolean, dimmed: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Column(
        modifier
            .scale(if (selected) 1.05f else 1f)
            .alpha(if (dimmed) 0.75f else 1f)
            .clip(RoundedCornerShape(12.dp))
            .background(Theme.panel)
            .border(if (selected) 3.dp else 1.dp, if (selected) Theme.accent else Color.White.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .semantics(mergeDescendants = true) { contentDescription = "${card.name}, ${card.cost} elixir"; role = Role.Button }
            .padding(4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Box(
            Modifier.fillMaxWidth().aspectRatio(0.82f).clip(RoundedCornerShape(10.dp)).background(cardGradient(card)),
        ) {
            Text(card.emoji, fontSize = 34.sp, modifier = Modifier.align(Alignment.Center))
            ElixirBadge(card.cost, 22.dp, Modifier.offset((-4).dp, (-4).dp))
        }
        Text(
            card.name, color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold, maxLines = 1,
            overflow = TextOverflow.Ellipsis, textAlign = TextAlign.Center,
        )
    }
}

fun cardGradient(card: CardDef): Brush = if (card.kind == CardKind.SPELL)
    Brush.verticalGradient(listOf(Theme.spellTop, Theme.spellBottom))
else
    Brush.verticalGradient(listOf(Theme.troopTop, Theme.troopBottom))

@Composable
fun ElixirBadge(cost: Int, size: Dp = 22.dp, modifier: Modifier = Modifier) {
    Box(
        modifier
            .size(size)
            .clip(CircleShape)
            .background(Theme.elixir)
            .border(1.5.dp, Color.White.copy(alpha = 0.8f), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Text("$cost", color = Color.White, fontWeight = FontWeight.Black, fontSize = (size.value * 0.55f).sp)
    }
}

@Composable
fun CardDetailSheet(card: CardDef) {
    Column(Modifier.fillMaxWidth().padding(24.dp).padding(bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            Text(card.emoji, fontSize = 56.sp)
            Column(Modifier.weight(1f)) {
                Text(card.name, color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Black)
                Text(
                    if (card.kind == CardKind.SPELL) "Spell" else if (card.flying) "Flying troop" else "Ground troop",
                    color = Color.White.copy(alpha = 0.7f), fontSize = 15.sp,
                )
            }
            ElixirBadge(card.cost, 40.dp)
        }
        Text(card.description, color = Color.White.copy(alpha = 0.85f), fontSize = 16.sp)
        HorizontalDivider(color = Color.White.copy(alpha = 0.2f))
        if (card.kind == CardKind.TROOP) {
            StatRow("Hitpoints", "${card.hp.toInt()}" + if (card.count > 1) " ×${card.count}" else "")
            StatRow("Damage", "${card.damage.toInt()}")
            StatRow("Hit speed", String.format(Locale.US, "%.1fs", card.hitSpeed))
            StatRow("Range", if (card.isMelee) "Melee" else String.format(Locale.US, "%.1f", card.range))
            StatRow("Speed", when {
                card.speed >= 3.4 -> "Very fast"
                card.speed >= 2.8 -> "Fast"
                card.speed >= 1.8 -> "Medium"
                else -> "Slow"
            })
            if (card.buildingsOnly) StatRow("Targets", "Buildings only")
        } else {
            StatRow("Damage", "${card.damage.toInt()}")
            StatRow("Tower damage", "${(card.damage * Arena.TOWER_SPELL_FACTOR).toInt()}")
            StatRow("Radius", String.format(Locale.US, "%.1f", card.radius))
        }
    }
}

@Composable
private fun StatRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth()) {
        Text(label, color = Color.White.copy(alpha = 0.7f), fontSize = 15.sp)
        Spacer(Modifier.weight(1f))
        Text(value, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}
