package com.dabit3.towertussle

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.util.Locale

@Composable
fun ResultsScreen(result: MatchResult, onHome: () -> Unit, onRematch: () -> Unit) {
    val profile = LocalProfile.current
    val titleColor = when (result.outcome) {
        MatchOutcome.VICTORY -> Theme.accent
        MatchOutcome.DEFEAT -> Theme.enemy
        MatchOutcome.DRAW -> Color.White
    }
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(24.dp)) {
        Spacer(Modifier.weight(1f))
        Text(when (result.outcome) { MatchOutcome.VICTORY -> "🎉"; MatchOutcome.DEFEAT -> "💀"; MatchOutcome.DRAW -> "🤝" }, fontSize = 72.sp)
        Text(result.outcome.title, color = titleColor, fontSize = 56.sp, fontWeight = FontWeight.Black, modifier = Modifier.testTag("resultTitle"))

        Row(horizontalArrangement = Arrangement.spacedBy(30.dp), verticalAlignment = Alignment.CenterVertically) {
            CrownColumn("You", result.playerCrowns, Theme.player)
            Text("—", color = Color.White.copy(alpha = 0.4f), fontSize = 28.sp)
            CrownColumn("Enemy", result.enemyCrowns, Theme.enemy)
        }

        Column(
            Modifier.fillMaxWidth().padding(horizontal = 28.dp).clip(RoundedCornerShape(16.dp)).background(Theme.panel).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            RewardRow("🏆", "Trophies", result.trophyDelta, profile.trophies)
            RewardRow("🪙", "Gold", result.goldDelta, profile.gold)
            Row(Modifier.fillMaxWidth()) {
                Text("⏱️  Battle time", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                Text(
                    String.format(Locale.US, "%d:%02d", result.durationSeconds / 60, result.durationSeconds % 60),
                    color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                )
            }
        }

        Spacer(Modifier.weight(1f))

        Column(Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(
                "REMATCH", fontSize = 22.sp, fontWeight = FontWeight.Black, color = Theme.darkText, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Theme.accent)
                    .clickable(onClick = onRematch).padding(vertical = 16.dp).testTag("rematchButton"),
            )
            Text(
                "HOME", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color.White, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Theme.panel)
                    .clickable(onClick = onHome).padding(vertical = 14.dp).testTag("homeButton"),
            )
        }
    }
}

@Composable
private fun CrownColumn(label: String, count: Int, color: Color) {
    Column(
        Modifier.semantics(mergeDescendants = true) { contentDescription = "$label: $count crowns" },
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        CrownRow(count, color, 22.sp)
        Text(label, color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun RewardRow(icon: String, label: String, delta: Int, total: Int) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Text("$icon  $label", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.weight(1f))
        Text(
            if (delta >= 0) "+$delta" else "$delta",
            color = if (delta > 0) Color(0xFF4CD964) else if (delta < 0) Theme.enemy else Color.White.copy(alpha = 0.6f),
            fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
        )
        Text("($total)", color = Color.White.copy(alpha = 0.5f), fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
    }
}
