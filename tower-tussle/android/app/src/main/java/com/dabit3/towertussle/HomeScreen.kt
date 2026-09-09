package com.dabit3.towertussle

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun HomeScreen(onBattle: () -> Unit, onCards: () -> Unit) {
    val profile = LocalProfile.current
    Box(Modifier.fillMaxSize()) {
        SceneryBackdrop()
        Column(Modifier.fillMaxSize()) {
            Row(
                Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                StatPill(IconKind.TROPHY, "${profile.trophies}", "Trophies", Modifier.weight(1f))
                StatPill(IconKind.COIN, "${profile.gold}", "Gold", Modifier.weight(1f))
            }

            Spacer(Modifier.weight(1f))

            Column(
                Modifier.fillMaxWidth().semantics(mergeDescendants = true) { contentDescription = "Tower Tussle" },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                HeroTowers(Modifier.fillMaxWidth().height(170.dp))
                DisplayText("TOWER", 58.sp, color = Theme.accent, modifier = Modifier.offset(y = (-10).dp))
                DisplayText("TUSSLE", 58.sp, color = Color.White, modifier = Modifier.offset(y = (-30).dp))
                Text(
                    "Real-time tower defense duels", fontSize = 15.sp, fontWeight = FontWeight.Bold,
                    color = Color.White.copy(alpha = 0.85f), modifier = Modifier.offset(y = (-26).dp),
                )
            }

            Spacer(Modifier.weight(1f))

            Column(
                Modifier.fillMaxWidth().padding(horizontal = 28.dp).padding(bottom = 24.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                ChunkyButton("BATTLE", onClick = onBattle, icon = IconKind.SWORDS, modifier = Modifier.testTag("battleButton"))
                ChunkyButton("CARDS", onClick = onCards, icon = IconKind.CARDS, style = ChunkyStyle.BLUE, height = 52.dp, fontSize = 20.sp, modifier = Modifier.testTag("cardsButton"))
                Text(
                    "${profile.wins}W · ${profile.losses}L · ${profile.draws}D",
                    fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.7f),
                    modifier = Modifier.padding(top = 4.dp),
                )
            }
        }
    }
}

/** Two rival towers facing off, drawn with the in-game tower art. */
@Composable
private fun HeroTowers(modifier: Modifier) {
    Canvas(modifier) {
        val w = size.width; val h = size.height
        val r = h * 0.22f
        softShadow(w * 0.5f, h * 0.92f, w * 0.34f, h * 0.05f, 0.4f)
        tower(TowerKind.GUARD, Side.ENEMY, Offset(w * 0.3f, h * 0.55f), r * 0.85f, alive = true, activated = true, flash = false, time = 0.0)
        tower(TowerKind.GUARD, Side.PLAYER, Offset(w * 0.7f, h * 0.55f), r * 0.85f, alive = true, activated = true, flash = false, time = 1.5)
        tower(TowerKind.KEEP, Side.PLAYER, Offset(w * 0.5f, h * 0.62f), r, alive = true, activated = true, flash = false, time = 0.7)
        character("knight", Side.PLAYER, Offset(w * 0.86f, h * 0.95f), h * 0.055f, Art.Pose(attack = 0.4))
        character("gremlins", Side.ENEMY, Offset(w * 0.14f, h * 0.95f), h * 0.05f, Art.Pose(facing = 1f, attack = 0.5))
    }
}
