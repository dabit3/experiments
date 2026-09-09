package com.dabit3.towertussle

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun HomeScreen(onBattle: () -> Unit, onCards: () -> Unit) {
    val profile = LocalProfile.current
    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            StatPill("🏆", "${profile.trophies}", "Trophies", Modifier.weight(1f))
            StatPill("🪙", "${profile.gold}", "Gold", Modifier.weight(1f))
        }

        Spacer(Modifier.weight(1f))

        Column(
            Modifier.fillMaxWidth().semantics(mergeDescendants = true) { contentDescription = "Tower Tussle" },
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text("🏰", fontSize = 84.sp)
            Text(
                "TOWER", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Theme.accent,
                style = androidx.compose.ui.text.TextStyle(shadow = androidx.compose.ui.graphics.Shadow(Color.Black.copy(0.6f), androidx.compose.ui.geometry.Offset(3f, 3f))),
            )
            Text(
                "TUSSLE", fontSize = 52.sp, fontWeight = FontWeight.Black, color = Color.White,
                modifier = Modifier.offset(y = (-18).dp),
                style = androidx.compose.ui.text.TextStyle(shadow = androidx.compose.ui.graphics.Shadow(Color.Black.copy(0.6f), androidx.compose.ui.geometry.Offset(3f, 3f))),
            )
            Text(
                "Real-time tower defense duels", fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                color = Color.White.copy(alpha = 0.7f), modifier = Modifier.offset(y = (-12).dp),
            )
        }

        Spacer(Modifier.weight(1f))

        Column(
            Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                "⚔️  BATTLE",
                fontSize = 26.sp, fontWeight = FontWeight.Black, color = Theme.darkText, textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(6.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .background(Brush.verticalGradient(listOf(Theme.accent, Theme.orange)))
                    .clickable(onClick = onBattle)
                    .padding(vertical = 18.dp)
                    .testTag("battleButton"),
            )
            Text(
                "🃏  CARDS",
                fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White, textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Theme.panel)
                    .border(1.dp, Color.White.copy(alpha = 0.15f), RoundedCornerShape(16.dp))
                    .clickable(onClick = onCards)
                    .padding(vertical = 14.dp)
                    .testTag("cardsButton"),
            )
            Text(
                "${profile.wins}W · ${profile.losses}L · ${profile.draws}D",
                fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color.White.copy(alpha = 0.55f),
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    }
}

@Composable
fun StatPill(icon: String, value: String, label: String, modifier: Modifier = Modifier) {
    Row(
        modifier
            .clip(CircleShape)
            .background(Theme.panel)
            .padding(horizontal = 12.dp, vertical = 8.dp)
            .semantics(mergeDescendants = true) { contentDescription = "$label: $value" },
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(icon, fontSize = 20.sp)
        Column {
            Text(value, fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Text(label, fontSize = 11.sp, color = Color.White.copy(alpha = 0.6f))
        }
    }
}
