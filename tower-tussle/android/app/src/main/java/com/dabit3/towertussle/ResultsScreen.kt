package com.dabit3.towertussle

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun ResultsScreen(result: MatchResult, onHome: () -> Unit, onRematch: () -> Unit) {
    val profile = LocalProfile.current
    val titleColor = when (result.outcome) {
        MatchOutcome.VICTORY -> Theme.accent
        MatchOutcome.DEFEAT -> Theme.enemy
        MatchOutcome.DRAW -> Color.White
    }
    Box(Modifier.fillMaxSize()) {
        SceneryBackdrop(dim = if (result.outcome == MatchOutcome.DEFEAT) 0.5f else 0.2f)
        Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Spacer(Modifier.weight(1f))
            OutcomeEmblem(result.outcome, Modifier.size(150.dp))
            DisplayText(result.outcome.title, 58.sp, color = titleColor, modifier = Modifier.testTag("resultTitle"))

            Row(
                Modifier.panel(cornerRadius = 22.dp).padding(horizontal = 22.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(26.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                CrownColumn("You", result.playerCrowns, Theme.player)
                DisplayText("VS", 22.sp, color = Color.White.copy(alpha = 0.6f))
                CrownColumn("Enemy", result.enemyCrowns, Theme.enemy)
            }

            Column(
                Modifier.fillMaxWidth().padding(horizontal = 28.dp).panel().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                RewardRow(IconKind.TROPHY, "Trophies", result.trophyDelta, profile.trophies)
                RewardRow(IconKind.COIN, "Gold", result.goldDelta, profile.gold)
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    IconView(IconKind.CLOCK, 22.dp)
                    Text("Battle time", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.weight(1f))
                    DisplayText(String.format(Locale.US, "%d:%02d", result.durationSeconds / 60, result.durationSeconds % 60), 16.sp)
                }
            }

            Spacer(Modifier.weight(1f))

            Column(Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                ChunkyButton("REMATCH", onClick = onRematch, icon = IconKind.SWORDS, modifier = Modifier.testTag("rematchButton"))
                ChunkyButton("HOME", onClick = onHome, icon = IconKind.HOME, style = ChunkyStyle.SLATE, height = 52.dp, fontSize = 20.sp, modifier = Modifier.testTag("homeButton"))
            }
        }
    }
}

/** Big vector emblem for the match outcome: crowned keep, rubble, or crossed swords. */
@Composable
private fun OutcomeEmblem(outcome: MatchOutcome, modifier: Modifier) {
    Canvas(modifier) {
        val w = size.width; val h = size.height
        val c = Offset(w / 2, h / 2)
        val glow = when (outcome) { MatchOutcome.VICTORY -> Art.gold; MatchOutcome.DEFEAT -> Theme.enemy; MatchOutcome.DRAW -> Color.White }
        drawPath(Art.circle(c.x, c.y, w * 0.5f), Art.radial(listOf(glow.copy(alpha = 0.55f), glow.copy(alpha = 0f)), c, w * 0.5f), blendMode = BlendMode.Plus)
        if (outcome == MatchOutcome.VICTORY) {
            for (i in 0 until 12) {
                val a = i / 12.0 * PI * 2
                val ray = Art.polygon(
                    c.x to c.y,
                    c.x + (cos(a - 0.08) * w * 0.5).toFloat() to c.y + (sin(a - 0.08) * w * 0.5).toFloat(),
                    c.x + (cos(a + 0.08) * w * 0.5).toFloat() to c.y + (sin(a + 0.08) * w * 0.5).toFloat(),
                )
                drawPath(ray, Art.gold.copy(alpha = 0.18f), blendMode = BlendMode.Plus)
            }
        }
        when (outcome) {
            MatchOutcome.VICTORY -> {
                tower(TowerKind.KEEP, Side.PLAYER, Offset(c.x, c.y + h * 0.08f), w * 0.2f, alive = true, activated = true, flash = false, time = 0.0)
                crown(Offset(c.x, c.y - h * 0.4f), w * 0.36f)
            }
            MatchOutcome.DEFEAT -> {
                tower(TowerKind.KEEP, Side.PLAYER, Offset(c.x, c.y + h * 0.1f), w * 0.3f, alive = false, activated = true, flash = false, time = 0.0)
                for ((x, y, s) in listOf(Triple(-0.25f, -0.28f, 0.14f), Triple(0.2f, -0.35f, 0.1f), Triple(0.05f, -0.15f, 0.08f))) {
                    val p = Offset(c.x + w * x, c.y + h * y)
                    drawPath(Art.circle(p.x, p.y, w * s), Art.radial(listOf(Color(0.4f, 0.4f, 0.45f).copy(alpha = 0.7f), Color(0.4f, 0.4f, 0.45f).copy(alpha = 0f)), p, w * s))
                }
            }
            MatchOutcome.DRAW -> {
                sword(Offset(c.x - w * 0.36f, c.y + h * 0.36f), Offset(c.x + w * 0.36f, c.y - h * 0.36f), w * 0.08f)
                sword(Offset(c.x + w * 0.36f, c.y + h * 0.36f), Offset(c.x - w * 0.36f, c.y - h * 0.36f), w * 0.08f)
            }
        }
    }
}

@Composable
private fun CrownColumn(label: String, count: Int, color: Color) {
    Column(
        Modifier.semantics(mergeDescendants = true) { contentDescription = "$label: $count crowns" },
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        CrownRow(count, color, 28.dp)
        Text(label.uppercase(), color = Color.White.copy(alpha = 0.75f), fontSize = 12.sp, fontWeight = FontWeight.Black)
    }
}

@Composable
private fun RewardRow(icon: IconKind, label: String, delta: Int, total: Int) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        IconView(icon, 22.dp)
        Text(label, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        DisplayText(
            if (delta >= 0) "+$delta" else "$delta", 16.sp,
            color = if (delta > 0) Color(0xFF4CD964) else if (delta < 0) Theme.enemy else Color.White.copy(alpha = 0.6f),
        )
        Text("($total)", color = Color.White.copy(alpha = 0.6f), fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}
