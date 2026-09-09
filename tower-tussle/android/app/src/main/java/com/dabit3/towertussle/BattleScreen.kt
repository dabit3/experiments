package com.dabit3.towertussle

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import java.util.Locale
import kotlin.math.min

@Composable
fun BattleScreen(engine: BattleEngine, onFinished: (MatchResult) -> Unit, onQuit: () -> Unit) {
    var showQuitConfirm by remember { mutableStateOf(false) }

    LaunchedEffect(engine) {
        while (engine.result == null) {
            withFrameNanos { engine.frame(it) }
        }
        delay(1200)
        engine.result?.let(onFinished)
    }

    engine.version

    Box(Modifier.fillMaxSize()) {
        SceneryBackdrop(dim = 0.45f)
        Column(Modifier.fillMaxSize().padding(horizontal = 10.dp).padding(bottom = 6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Hud(engine, onQuitTapped = { showQuitConfirm = true })

            BoxWithConstraints(Modifier.fillMaxWidth().weight(1f), contentAlignment = Alignment.Center) {
                val density = LocalDensity.current
                val widthPx = with(density) { maxWidth.toPx() }
                val heightPx = with(density) { maxHeight.toPx() }
                val scale = min(widthPx / Arena.WIDTH, heightPx / Arena.HEIGHT).toFloat()
                val arenaW = with(density) { (Arena.WIDTH * scale).toFloat().toDp() }
                val arenaH = with(density) { (Arena.HEIGHT * scale).toFloat().toDp() }
                Box(
                    Modifier
                        .size(arenaW, arenaH)
                        .shadow(10.dp, RoundedCornerShape(12.dp), clip = false)
                        .clip(RoundedCornerShape(12.dp))
                        .border(2.5.dp, Art.outline.copy(alpha = 0.9f), RoundedCornerShape(12.dp))
                        .pointerInput(engine, scale) {
                            detectTapGestures { p -> engine.deployAtTap(Vec(p.x / scale.toDouble(), p.y / scale.toDouble())) }
                        }
                        .semantics { contentDescription = "Arena" }
                        .testTag("arena"),
                ) {
                    ArenaCanvas(engine, scale, Modifier.fillMaxSize())
                }
                engine.announcement?.let { text ->
                    DisplayText(
                        text, 18.sp, color = Theme.accent,
                        modifier = Modifier.panel(cornerRadius = 20.dp, tint = Color(0.2f, 0.12f, 0.3f))
                            .padding(horizontal = 18.dp, vertical = 8.dp).testTag("announcement"),
                    )
                }
                engine.result?.let { r ->
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        IconView(if (r.outcome == MatchOutcome.VICTORY) IconKind.CROWN else IconKind.SWORDS, 64.dp)
                        DisplayText(
                            r.outcome.title, 56.sp,
                            color = when (r.outcome) { MatchOutcome.VICTORY -> Theme.accent; MatchOutcome.DEFEAT -> Theme.enemy; MatchOutcome.DRAW -> Color.White },
                        )
                    }
                }
            }

            HandBar(engine)
        }
    }

    if (showQuitConfirm) {
        AlertDialog(
            onDismissRequest = { showQuitConfirm = false },
            title = { Text("Leave the battle?") },
            confirmButton = { TextButton(onClick = { showQuitConfirm = false; onQuit() }) { Text("Surrender", color = Theme.enemy) } },
            dismissButton = { TextButton(onClick = { showQuitConfirm = false }) { Text("Keep fighting") } },
            containerColor = Theme.panel,
        )
    }
}

@Composable
private fun Hud(engine: BattleEngine, onQuitTapped: () -> Unit) {
    val s = engine.remainingSeconds
    Row(Modifier.fillMaxWidth().padding(top = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier.size(38.dp).panel(cornerRadius = 19.dp, tint = Color(0.5f, 0.12f, 0.16f)).clickable(onClick = onQuitTapped)
                .semantics { contentDescription = "Quit battle"; role = Role.Button }.testTag("quitButton"),
            contentAlignment = Alignment.Center,
        ) {
            DisplayText("✕", 16.sp)
        }
        Spacer(Modifier.weight(1f))
        Row(
            Modifier.panel(cornerRadius = 22.dp).padding(horizontal = 12.dp, vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Box(Modifier.testTag("enemyCrowns")) { CrownRow(engine.crowns(Side.ENEMY), Theme.enemy, 18.dp) }
            DisplayText(
                String.format(Locale.US, "%d:%02d", s / 60, s % 60),
                24.sp,
                color = if (engine.isOvertime) Theme.enemy else if (engine.isDoubleElixir) Color(0.95f, 0.6f, 1.0f) else Color.White,
                textAlign = TextAlign.Center,
                modifier = Modifier.width(84.dp).testTag("timer"),
            )
            Box(Modifier.testTag("playerCrowns")) { CrownRow(engine.crowns(Side.PLAYER), Theme.player, 18.dp) }
        }
        Spacer(Modifier.weight(1f))
        Box(Modifier.width(38.dp), contentAlignment = Alignment.Center) {
            val tag = if (engine.isOvertime) "OT" else if (engine.isDoubleElixir) "2×" else ""
            if (tag.isNotEmpty()) DisplayText(tag, 13.sp, color = Color(0.95f, 0.6f, 1.0f), modifier = Modifier.panel(cornerRadius = 12.dp).padding(horizontal = 6.dp, vertical = 3.dp))
        }
    }
}

@Composable
private fun HandBar(engine: BattleEngine) {
    Column(
        Modifier.fillMaxWidth().panel(cornerRadius = 18.dp).padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Bottom) {
            Column(Modifier.width(48.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("NEXT", fontSize = 9.sp, fontWeight = FontWeight.Black, color = Color.White.copy(alpha = 0.7f))
                HandCard(Cards.byId(engine.nextCard), selected = false, affordable = true, small = true, modifier = Modifier.testTag("nextCard"))
            }
            for ((index, id) in engine.hand.withIndex()) {
                val card = Cards.byId(id)
                HandCard(
                    card, selected = engine.selectedHandIndex == index, affordable = engine.canAfford(card), small = false,
                    modifier = Modifier.weight(1f)
                        .semantics { contentDescription = "${card.name}, ${card.cost} elixir"; role = Role.Button }
                        .testTag("hand-$index"),
                    onClick = { engine.selectHand(index) },
                )
            }
        }
        ElixirBar(engine.playerElixir, Arena.MAX_ELIXIR, Modifier.testTag("elixirBar"))
    }
}

@Composable
fun HandCard(card: CardDef, selected: Boolean, affordable: Boolean, small: Boolean, modifier: Modifier = Modifier, onClick: (() -> Unit)? = null) {
    val lift by animateDpAsState(if (selected) (-10).dp else 0.dp, label = "lift")
    Box(
        modifier
            .offset(y = lift)
            .padding(top = 6.dp, start = 4.dp)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
    ) {
        CardFrame(card, selected = selected, affordable = affordable, showName = !small, compact = small)
    }
}
