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
                    .clip(RoundedCornerShape(12.dp))
                    .border(2.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
                    .pointerInput(engine, scale) {
                        detectTapGestures { p -> engine.deployAtTap(Vec(p.x / scale.toDouble(), p.y / scale.toDouble())) }
                    }
                    .semantics { contentDescription = "Arena" }
                    .testTag("arena"),
            ) {
                ArenaCanvas(engine, scale, Modifier.fillMaxSize())
            }
            engine.announcement?.let { text ->
                Text(
                    text, color = Theme.accent, fontSize = 17.sp, fontWeight = FontWeight.Black,
                    modifier = Modifier.clip(CircleShape).background(Color.Black.copy(alpha = 0.65f))
                        .padding(horizontal = 16.dp, vertical = 8.dp).testTag("announcement"),
                )
            }
            engine.result?.let { r ->
                Text(
                    r.outcome.title, fontSize = 54.sp, fontWeight = FontWeight.Black,
                    color = when (r.outcome) { MatchOutcome.VICTORY -> Theme.accent; MatchOutcome.DEFEAT -> Theme.enemy; MatchOutcome.DRAW -> Color.White },
                    style = androidx.compose.ui.text.TextStyle(shadow = androidx.compose.ui.graphics.Shadow(Color.Black, androidx.compose.ui.geometry.Offset(3f, 3f))),
                )
            }
        }

        HandBar(engine)
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
        Text(
            "✕", color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
            modifier = Modifier.size(36.dp).clip(CircleShape).background(Theme.panel).clickable(onClick = onQuitTapped)
                .semantics { contentDescription = "Quit battle"; role = Role.Button }.testTag("quitButton").padding(top = 6.dp),
        )
        Spacer(Modifier.weight(1f))
        Box(Modifier.testTag("enemyCrowns")) { CrownRow(engine.crowns(Side.ENEMY), Theme.enemy, 13.sp) }
        Text(
            String.format(Locale.US, "%d:%02d", s / 60, s % 60),
            color = if (engine.isOvertime) Theme.enemy else if (engine.isDoubleElixir) Theme.elixir else Color.White,
            fontSize = 22.sp, fontWeight = FontWeight.Black, textAlign = TextAlign.Center,
            modifier = Modifier.width(84.dp).testTag("timer"),
        )
        Box(Modifier.testTag("playerCrowns")) { CrownRow(engine.crowns(Side.PLAYER), Theme.player, 13.sp) }
        Spacer(Modifier.weight(1f))
        Text(
            if (engine.isOvertime) "OT" else if (engine.isDoubleElixir) "2×" else "",
            color = Theme.elixir, fontSize = 12.sp, fontWeight = FontWeight.Black, modifier = Modifier.width(36.dp),
        )
    }
}

@Composable
fun CrownRow(count: Int, color: Color, size: TextUnit) {
    Row(Modifier.semantics { contentDescription = "$count crowns" }, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        for (i in 0 until 3) {
            Text("♛", fontSize = size, color = if (i < count) color else Color.White.copy(alpha = 0.2f))
        }
    }
}

@Composable
private fun HandBar(engine: BattleEngine) {
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Theme.panel).padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Bottom) {
            Column(Modifier.width(44.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Next", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.6f))
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
    val saturation = if (affordable) 1f else 0.2f
    Box(
        modifier
            .offset(y = lift)
            .aspectRatio(0.8f)
            .alpha(if (affordable) 1f else 0.55f)
            .clip(RoundedCornerShape(10.dp))
            .background(cardGradient(card))
            .border(if (selected) 3.dp else 1.dp, if (selected) Theme.accent else Color.White.copy(alpha = 0.2f), RoundedCornerShape(10.dp))
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier),
    ) {
        Column(Modifier.fillMaxSize().padding(horizontal = 2.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            Text(card.emoji, fontSize = if (small) 18.sp else 30.sp, modifier = Modifier.alpha(saturation.coerceAtLeast(0.6f)))
            if (!small) {
                Text(card.name, color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        ElixirBadge(card.cost, if (small) 16.dp else 22.dp, Modifier.offset((-3).dp, (-3).dp))
    }
}

@Composable
fun ElixirBar(value: Double, max: Double, modifier: Modifier = Modifier) {
    val fraction = (value / max).toFloat().coerceIn(0f, 1f)
    Box(
        modifier.fillMaxWidth().height(20.dp).clip(RoundedCornerShape(8.dp)).background(Color.Black.copy(alpha = 0.5f))
            .semantics { contentDescription = "Elixir ${value.toInt()} of ${max.toInt()}" },
    ) {
        Box(
            Modifier.fillMaxHeight().fillMaxWidth(fraction).clip(RoundedCornerShape(8.dp))
                .background(Brush.verticalGradient(listOf(Theme.elixir, Theme.elixirDark))),
        )
        Row(Modifier.fillMaxSize()) {
            for (i in 1 until max.toInt()) {
                Spacer(Modifier.weight(1f))
                Box(Modifier.width(1.dp).fillMaxHeight().background(Color.Black.copy(alpha = 0.35f)))
            }
            Spacer(Modifier.weight(1f))
        }
        Text(
            "${value.toInt()}", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Black,
            modifier = Modifier.align(Alignment.Center),
        )
    }
}
