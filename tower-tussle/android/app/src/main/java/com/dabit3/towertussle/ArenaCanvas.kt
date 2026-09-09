package com.dabit3.towertussle

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import kotlin.math.max
import kotlin.math.min

/** Draws the battle arena. `scale` is pixels per arena unit. */
@Composable
fun ArenaCanvas(engine: BattleEngine, scale: Float, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()
    Canvas(modifier) {
        engine.version // subscribe to frame updates
        val r = ArenaRenderer(this, measurer, scale)
        r.drawGround()
        r.drawDeployHint(engine)
        for (tower in engine.towers) r.drawTower(tower)
        for (unit in engine.units.sortedBy { it.pos.y }) if (unit.alive) r.drawUnit(unit)
        for (p in engine.projectiles) r.drawProjectile(p)
        for (e in engine.effects) r.drawEffect(e)
    }
}

private class ArenaRenderer(val scope: DrawScope, val measurer: TextMeasurer, val scale: Float) {
    private fun pt(v: Vec) = Offset((v.x * scale).toFloat(), (v.y * scale).toFloat())
    private fun len(d: Double) = (d * scale).toFloat()
    private fun px(f: Float): TextUnit = (f / scope.density / scope.fontScale).sp

    private fun text(s: String, center: Offset, sizePx: Float, color: Color = Color.Unspecified, bold: Boolean = false) {
        if (sizePx < 4f) return
        val style = TextStyle(fontSize = px(sizePx), color = color, fontWeight = if (bold) FontWeight.Black else null)
        val layout = measurer.measure(s, style)
        scope.drawText(layout, topLeft = Offset(center.x - layout.size.width / 2f, center.y - layout.size.height / 2f))
    }

    fun drawGround() = with(scope) {
        drawRect(Theme.grass, Offset.Zero, size)
        for (gy in 0 until Arena.HEIGHT.toInt()) {
            for (gx in 0 until Arena.WIDTH.toInt()) {
                if ((gx + gy) % 2 == 0) {
                    drawRect(Theme.grassDark, Offset(len(gx.toDouble()), len(gy.toDouble())), Size(len(1.0), len(1.0)))
                }
            }
        }
        val riverTop = len(Arena.RIVER_TOP)
        val riverH = len(Arena.RIVER_BOTTOM - Arena.RIVER_TOP)
        drawRect(Theme.river, Offset(0f, riverTop), Size(size.width, riverH))
        for (i in 0 until 6) {
            val y = riverTop + i * riverH / 6 + riverH / 12
            val wave = Path()
            wave.moveTo(0f, y)
            var x = 0f
            while (x < size.width) {
                wave.quadraticTo(x + len(0.5), y - len(0.15), x + len(1.0), y)
                x += len(1.0)
            }
            drawPath(wave, Color.White.copy(alpha = 0.18f), style = Stroke(1f))
        }
        for (bx in Arena.BRIDGE_XS) {
            val left = len(bx - Arena.BRIDGE_HALF_WIDTH)
            val top = len(Arena.RIVER_TOP - 0.2)
            val w = len(Arena.BRIDGE_HALF_WIDTH * 2)
            val h = len(Arena.RIVER_BOTTOM - Arena.RIVER_TOP + 0.4)
            drawRoundRect(Theme.bridge, Offset(left, top), Size(w, h), CornerRadius(len(0.15)))
            for (i in 0 until 5) {
                val y = top + i * h / 5 + h / 10
                drawLine(Color.Black.copy(alpha = 0.2f), Offset(left, y), Offset(left + w, y), 1f)
            }
        }
        drawLine(
            Color.White.copy(alpha = 0.15f), Offset(0f, len(Arena.RIVER_CENTER)), Offset(size.width, len(Arena.RIVER_CENTER)), 1f,
            pathEffect = PathEffect.dashPathEffect(floatArrayOf(4f, 4f)),
        )
    }

    fun drawDeployHint(engine: BattleEngine) = with(scope) {
        val card = engine.selectedCard ?: return
        if (engine.result != null) return
        val affordable = engine.canAfford(card)
        val top = if (card.kind == CardKind.SPELL) 0f else len(Arena.PLAYER_DEPLOY_MIN_Y)
        val rectSize = Size(len(Arena.WIDTH), len(Arena.HEIGHT) - top)
        val color = if (affordable) Theme.player else Theme.enemy
        drawRect(color.copy(alpha = 0.18f), Offset(0f, top), rectSize)
        drawRect(
            color.copy(alpha = 0.6f), Offset(1f, top + 1f), Size(rectSize.width - 2f, rectSize.height - 2f),
            style = Stroke(2f, pathEffect = PathEffect.dashPathEffect(floatArrayOf(6f, 4f))),
        )
    }

    fun drawTower(tower: Tower) = with(scope) {
        val r = len(tower.kind.radius)
        val center = pt(tower.pos)
        val topLeft = Offset(center.x - r, center.y - r)
        val sz = Size(2 * r, 2 * r)
        val color = if (tower.side == Side.PLAYER) Theme.player else Theme.enemy
        if (!tower.alive) {
            drawRoundRect(Color.Black.copy(alpha = 0.35f), topLeft, sz, CornerRadius(r * 0.3f))
            text("💥", center, r * 1.2f)
            return
        }
        drawOval(Color.Black.copy(alpha = 0.25f), Offset(topLeft.x - r * 0.1f, topLeft.y - r * 0.1f + r * 0.25f), Size(sz.width + r * 0.2f, sz.height + r * 0.2f))
        drawRoundRect(if (tower.hitFlash > 0) Color.White else Color(0.55f, 0.55f, 0.6f), topLeft, sz, CornerRadius(r * 0.3f))
        drawRoundRect(color, Offset(topLeft.x + r * 0.2f, topLeft.y + r * 0.2f), Size(sz.width - r * 0.4f, sz.height - r * 0.4f), CornerRadius(r * 0.2f))
        text(if (tower.kind == TowerKind.KEEP) "👑" else "🏰", center, r * 1.1f)
        if (tower.kind == TowerKind.KEEP && !tower.activated) {
            text("💤", Offset(center.x + r * 0.8f, center.y - r * 0.8f), r * 0.5f)
        }
        drawHealthBar(Offset(center.x, topLeft.y - len(0.35)), 2 * r, tower.hp / tower.kind.maxHp, "${tower.hp.toInt()}")
    }

    fun drawUnit(unit: Troop) = with(scope) {
        val r = len(unit.radius)
        val center = pt(unit.pos)
        val color = if (unit.side == Side.PLAYER) Theme.player else Theme.enemy
        val shadowOffset = if (unit.card.flying) r * 0.9f else r * 0.3f
        drawOval(Color.Black.copy(alpha = 0.3f), Offset(center.x - r * 0.8f, center.y + shadowOffset - r * 0.25f), Size(r * 1.6f, r * 0.5f))
        val bodyCenter = if (unit.card.flying) Offset(center.x, center.y - r * 0.6f) else center
        drawCircle(if (unit.hitFlash > 0) Color.White else color, r, bodyCenter)
        drawCircle(Color.White.copy(alpha = 0.7f), r, bodyCenter, style = Stroke(max(1f, r * 0.12f)))
        text(unit.card.emoji, bodyCenter, r * 1.3f)
        drawHealthBar(Offset(bodyCenter.x, bodyCenter.y - r - len(0.25)), max(2 * r, len(0.9)), unit.hp / unit.card.hp, null)
    }

    private fun drawHealthBar(center: Offset, width: Float, fraction: Double, label: String?) = with(scope) {
        val h = len(0.28)
        val topLeft = Offset(center.x - width / 2, center.y - h / 2)
        drawRoundRect(Color.Black.copy(alpha = 0.6f), topLeft, Size(width, h), CornerRadius(h / 2))
        val f = fraction.coerceIn(0.0, 1.0).toFloat()
        drawRoundRect(if (fraction > 0.35) Color(0xFF4CD964) else Theme.orange, topLeft, Size(width * f, h), CornerRadius(h / 2))
        if (label != null) text(label, center, h * 0.8f, Color.White, bold = true)
    }

    fun drawProjectile(p: Projectile) = with(scope) {
        drawCircle(if (p.side == Side.PLAYER) Color.Cyan else Color.Yellow, len(0.15), pt(p.pos))
    }

    fun drawEffect(e: SpellEffect) = with(scope) {
        val progress = 1 - (e.ttl / 0.7).coerceIn(0.0, 1.0)
        val r = len(e.radius) * (0.4f + 0.6f * progress.toFloat())
        val c = pt(e.pos)
        drawCircle(e.color.copy(alpha = (0.45 * (1 - progress)).toFloat()), r, c)
        drawCircle(e.color.copy(alpha = (0.9 * (1 - progress)).toFloat()), r, c, style = Stroke(3f))
    }
}

private fun Double.coerceIn(lo: Double, hi: Double): Double = min(hi, max(lo, this))
