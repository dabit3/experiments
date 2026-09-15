package com.dabit3.towertussle

import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.drawscope.withTransform
import kotlin.math.cos
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.sin

/**
 * Original vector artwork for Tower Tussle: characters, towers, icons and
 * shared drawing helpers. Everything is drawn procedurally into a Compose
 * DrawScope so the game ships no external image assets.
 */
object Art {
    // Palette
    val skin = Color(0.99f, 0.83f, 0.68f)
    val skinShade = Color(0.86f, 0.62f, 0.48f)
    val steel = Color(0.78f, 0.82f, 0.88f)
    val steelDark = Color(0.42f, 0.47f, 0.56f)
    val gold = Color(1.0f, 0.80f, 0.25f)
    val goldDark = Color(0.72f, 0.48f, 0.08f)
    val wood = Color(0.62f, 0.42f, 0.22f)
    val woodDark = Color(0.38f, 0.24f, 0.11f)
    val stoneLight = Color(0.80f, 0.80f, 0.78f)
    val stone = Color(0.60f, 0.61f, 0.62f)
    val stoneDark = Color(0.36f, 0.37f, 0.40f)
    val outline = Color(0.10f, 0.08f, 0.14f)
    val leaf = Color(0.22f, 0.50f, 0.20f)
    val leafDark = Color(0.14f, 0.36f, 0.14f)
    val bone = Color(0.96f, 0.95f, 0.88f)
    val goblin = Color(0.42f, 0.72f, 0.28f)
    val goblinDark = Color(0.22f, 0.45f, 0.14f)
    val dragon = Color(0.32f, 0.68f, 0.62f)
    val dragonBelly = Color(0.92f, 0.86f, 0.55f)
    val fire = Color(1.0f, 0.55f, 0.12f)
    val fireCore = Color(1.0f, 0.92f, 0.55f)

    fun team(side: Side): Color = if (side == Side.PLAYER) Theme.player else Theme.enemy
    fun teamDark(side: Side): Color = if (side == Side.PLAYER) Color(0.10f, 0.28f, 0.62f) else Color(0.58f, 0.10f, 0.14f)
    fun teamLight(side: Side): Color = if (side == Side.PLAYER) Color(0.55f, 0.78f, 1.0f) else Color(1.0f, 0.58f, 0.55f)

    // Geometry helpers

    fun rect(x: Float, y: Float, w: Float, h: Float) = Rect(x, y, x + w, y + h)

    fun circle(cx: Float, cy: Float, r: Float): Path = Path().apply { addOval(Rect(cx - r, cy - r, cx + r, cy + r)) }

    fun ellipse(cx: Float, cy: Float, rx: Float, ry: Float): Path = Path().apply { addOval(Rect(cx - rx, cy - ry, cx + rx, cy + ry)) }

    fun rounded(r: Rect, radius: Float): Path = Path().apply { addRoundRect(RoundRect(r, CornerRadius(radius, radius))) }

    fun rectPath(r: Rect): Path = Path().apply { addRect(r) }

    fun polygon(pts: List<Offset>): Path = Path().apply {
        if (pts.isEmpty()) return@apply
        moveTo(pts[0].x, pts[0].y)
        for (i in 1 until pts.size) lineTo(pts[i].x, pts[i].y)
        close()
    }

    fun polygon(vararg pts: Pair<Float, Float>): Path = polygon(pts.map { Offset(it.first, it.second) })

    fun segment(a: Offset, b: Offset): Path = Path().apply { moveTo(a.x, a.y); lineTo(b.x, b.y) }

    fun vertical(top: Color, bottom: Color, frame: Rect): Brush =
        Brush.verticalGradient(listOf(top, bottom), startY = frame.top, endY = max(frame.bottom, frame.top + 0.001f))

    fun vertical(colors: List<Color>, frame: Rect): Brush =
        Brush.verticalGradient(colors, startY = frame.top, endY = max(frame.bottom, frame.top + 0.001f))

    fun horizontal(left: Color, right: Color, frame: Rect): Brush =
        Brush.horizontalGradient(listOf(left, right), startX = frame.left, endX = max(frame.right, frame.left + 0.001f))

    fun radial(colors: List<Color>, center: Offset, radius: Float): Brush =
        Brush.radialGradient(colors, center = center, radius = max(radius, 0.001f))

    fun stroke(width: Float, cap: StrokeCap = StrokeCap.Butt, effect: PathEffect? = null) =
        Stroke(width = width, cap = cap, pathEffect = effect)

    class Pose(
        val phase: Double = 0.0,
        val facing: Float = 1f,
        val attack: Double = 0.0,
        val flash: Boolean = false,
        val time: Double = 0.0,
        val moving: Boolean = false,
    )
}

/** Filled + outlined shape, the signature "cartoon" look used everywhere. */
fun DrawScope.shape(path: Path, fill: Brush, line: Float, strokeColor: Color = Art.outline) {
    drawPath(path, fill)
    if (line > 0) drawPath(path, strokeColor, style = Stroke(line))
}

fun DrawScope.shape(path: Path, fill: Color, line: Float, strokeColor: Color = Art.outline) {
    drawPath(path, fill)
    if (line > 0) drawPath(path, strokeColor, style = Stroke(line))
}

/** Ball with a Art.radial highlight, used for heads, shoulders, orbs. */
fun DrawScope.ball(cx: Float, cy: Float, r: Float, color: Color, dark: Color, line: Float) {
    val path = Art.circle(cx, cy, r)
    shape(path, Art.radial(listOf(color, dark), Offset(cx - r * 0.35f, cy - r * 0.35f), r * 1.5f), line)
}

fun DrawScope.softShadow(cx: Float, cy: Float, rx: Float, ry: Float, alpha: Float = 0.35f) {
    withTransform({
        translate(cx, cy)
        scale(1f, ry / max(rx, 0.001f), Offset.Zero)
    }) {
        drawPath(Art.circle(0f, 0f, rx), Art.radial(listOf(Color.Black.copy(alpha = alpha), Color.Black.copy(alpha = 0f)), Offset.Zero, rx))
    }
}

fun DrawScope.healthBar(center: Offset, width: Float, height: Float, fraction: Double, side: Side) {
    val frame = Art.rect(center.x - width / 2, center.y - height / 2, width, height)
    drawPath(Art.rounded(frame.inflate(1.5f), height), Art.outline.copy(alpha = 0.85f))
    drawPath(Art.rounded(frame, height / 2), Color(0.16f, 0.16f, 0.16f))
    val f = fraction.coerceIn(0.0, 1.0).toFloat()
    if (f > 0) {
        val fill = Art.rect(frame.left, frame.top, max(height, frame.width * f), frame.height)
        val hue = if (f > 0.5f) Color(0.36f, 0.86f, 0.30f) else if (f > 0.25f) Color(0.98f, 0.80f, 0.22f) else Color(0.95f, 0.28f, 0.22f)
        clipPath(Art.rounded(frame, height / 2)) {
            drawRect(Art.vertical(hue, hue.copy(alpha = 0.7f), fill), topLeft = fill.topLeft, size = fill.size)
            drawRect(Color.White.copy(alpha = 0.3f), topLeft = fill.topLeft, size = Size(fill.width, fill.height * 0.4f))
        }
    }
    drawPath(Art.rounded(frame, height / 2), Art.team(side), style = Stroke(1f))
}

// Icons

fun DrawScope.crown(center: Offset, size: Float, color: Color = Art.gold, dim: Boolean = false, line: Float? = null) {
    val s = size / 2
    val lineWidth = line ?: max(1f, size * 0.07f)
    val path = Art.polygon(
        center.x - s to center.y + s * 0.6f,
        center.x - s to center.y - s * 0.35f,
        center.x - s * 0.5f to center.y + s * 0.05f,
        center.x to center.y - s * 0.75f,
        center.x + s * 0.5f to center.y + s * 0.05f,
        center.x + s to center.y - s * 0.35f,
        center.x + s to center.y + s * 0.6f,
    )
    val frame = path.getBounds()
    val base = if (dim) Color(0.35f, 0.35f, 0.35f) else color
    val dark = if (dim) Color(0.2f, 0.2f, 0.2f) else Art.goldDark
    shape(path, Art.vertical(base, dark, frame), lineWidth)
    drawRect(dark.copy(alpha = 0.6f), Offset(center.x - s, center.y + s * 0.3f), Size(2 * s, s * 0.3f))
    if (!dim) {
        val jewels = listOf(Color(0.95f, 0.25f, 0.35f), Color(0.25f, 0.55f, 1.0f), Color(0.3f, 0.85f, 0.4f))
        for ((i, jx) in listOf(-0.55f, 0f, 0.55f).withIndex()) {
            drawPath(Art.circle(center.x + jx * s, center.y + s * 0.42f, s * 0.12f), jewels[i])
        }
        drawPath(Art.circle(center.x, center.y - s * 0.72f, s * 0.14f), Art.fireCore)
    }
}

fun DrawScope.elixirDrop(center: Offset, size: Float) {
    val s = size / 2
    val p = Path().apply {
        moveTo(center.x, center.y - s)
        cubicTo(center.x + s * 1.15f, center.y - s * 0.1f, center.x + s * 0.95f, center.y + s * 0.95f, center.x, center.y + s * 0.95f)
        cubicTo(center.x - s * 0.95f, center.y + s * 0.95f, center.x - s * 1.15f, center.y - s * 0.1f, center.x, center.y - s)
        close()
    }
    val light = Color(0.93f, 0.55f, 1.0f)
    val dark = Color(0.45f, 0.10f, 0.62f)
    shape(p, Art.radial(listOf(light, Theme.elixir, dark), Offset(center.x - s * 0.3f, center.y + s * 0.1f), s * 1.3f), max(1f, size * 0.07f))
    drawPath(Art.ellipse(center.x - s * 0.3f, center.y + s * 0.15f, s * 0.16f, s * 0.3f), Color.White.copy(alpha = 0.75f))
}

fun DrawScope.trophy(center: Offset, size: Float) {
    val s = size / 2
    val cup = Art.polygon(
        center.x - s * 0.7f to center.y - s * 0.9f,
        center.x + s * 0.7f to center.y - s * 0.9f,
        center.x + s * 0.45f to center.y + s * 0.15f,
        center.x - s * 0.45f to center.y + s * 0.15f,
    )
    shape(cup, Art.horizontal(Art.gold, Art.goldDark, cup.getBounds()), max(1f, size * 0.07f))
    drawPath(Art.ellipse(center.x - s * 0.8f, center.y - s * 0.45f, s * 0.25f, s * 0.35f), Art.goldDark, style = Stroke(max(1f, size * 0.1f)))
    drawPath(Art.ellipse(center.x + s * 0.8f, center.y - s * 0.45f, s * 0.25f, s * 0.35f), Art.goldDark, style = Stroke(max(1f, size * 0.1f)))
    drawRect(Art.goldDark, Offset(center.x - s * 0.12f, center.y + s * 0.15f), Size(s * 0.24f, s * 0.35f))
    shape(Art.rounded(Art.rect(center.x - s * 0.5f, center.y + s * 0.5f, s, s * 0.4f), s * 0.1f), Art.woodDark, max(1f, size * 0.06f))
    drawPath(Art.ellipse(center.x - s * 0.3f, center.y - s * 0.55f, s * 0.1f, s * 0.22f), Color.White.copy(alpha = 0.7f))
}

fun DrawScope.coin(center: Offset, size: Float) {
    val r = size / 2
    ball(center.x, center.y, r, Art.gold, Art.goldDark, max(1f, size * 0.08f))
    drawPath(Art.circle(center.x, center.y, r * 0.65f), Art.goldDark.copy(alpha = 0.8f), style = Stroke(max(1f, size * 0.06f)))
    drawPath(Art.ellipse(center.x - r * 0.35f, center.y - r * 0.35f, r * 0.14f, r * 0.26f), Color.White.copy(alpha = 0.7f))
}

fun DrawScope.sword(a: Offset, b: Offset, width: Float) {
    val blade = Art.segment(a, b)
    drawPath(blade, Art.outline, style = Stroke(width * 1.9f, cap = StrokeCap.Round))
    drawPath(blade, Art.steel, style = Stroke(width, cap = StrokeCap.Round))
    val dx = b.x - a.x; val dy = b.y - a.y
    val l = max(0.001f, hypot(dx, dy))
    val nx = -dy / l; val ny = dx / l
    val gx = a.x + dx * 0.22f; val gy = a.y + dy * 0.22f
    val guard = Art.segment(Offset(gx + nx * width * 1.6f, gy + ny * width * 1.6f), Offset(gx - nx * width * 1.6f, gy - ny * width * 1.6f))
    drawPath(guard, Art.outline, style = Stroke(width * 1.6f, cap = StrokeCap.Round))
    drawPath(guard, Art.gold, style = Stroke(width * 0.8f, cap = StrokeCap.Round))
}

fun DrawScope.clock(center: Offset, size: Float) {
    ball(center.x, center.y, size * 0.45f, Color.White, Color(0.75f, 0.75f, 0.75f), max(1f, size * 0.07f))
    val hands = Path().apply {
        moveTo(center.x, center.y); lineTo(center.x, center.y - size * 0.3f)
        moveTo(center.x, center.y); lineTo(center.x + size * 0.22f, center.y)
    }
    drawPath(hands, Art.outline, style = Stroke(max(1f, size * 0.07f), cap = StrokeCap.Round))
}

fun DrawScope.cardsIcon(center: Offset, size: Float) {
    for ((i, a) in listOf(-14f, 0f, 14f).withIndex()) {
        withTransform({
            translate(center.x + (i - 1) * size * 0.14f, center.y + size * 0.1f)
            rotate(a, Offset.Zero)
        }) {
            val r = Art.rect(-size * 0.22f, -size * 0.32f, size * 0.44f, size * 0.64f)
            val top = if (i == 1) Theme.player else Theme.elixir
            val bottom = if (i == 1) Art.teamDark(Side.PLAYER) else Color(0.4f, 0.1f, 0.55f)
            shape(Art.rounded(r, size * 0.06f), Art.vertical(top, bottom, r), max(1f, size * 0.05f))
        }
    }
}

fun DrawScope.swordsIcon(center: Offset, size: Float) {
    sword(Offset(center.x - size * 0.4f, center.y + size * 0.4f), Offset(center.x + size * 0.4f, center.y - size * 0.4f), size * 0.11f)
    sword(Offset(center.x + size * 0.4f, center.y + size * 0.4f), Offset(center.x - size * 0.4f, center.y - size * 0.4f), size * 0.11f)
}

// Characters


/** Draws a character whose feet stand at [foot], with base body radius [r]. */
fun DrawScope.character(id: String, side: Side, foot: Offset, r: Float, pose: Art.Pose) {
    withTransform({
        translate(foot.x, foot.y)
        scale(r * pose.facing, r, Offset.Zero)
    }) {
        val line = 0.14f
        when (id) {
            "knight" -> knight(side, pose, line)
            "archers" -> archer(side, pose, line)
            "giant" -> colossus(side, pose, line)
            "duelist" -> duelist(side, pose, line)
            "sharpshooter" -> sharpshooter(side, pose, line)
            "gremlins" -> gremlin(side, pose, line)
            "bones" -> skeleton(side, pose, line)
            "whelp" -> whelp(side, pose, line)
            else -> knight(side, pose, line)
        }
    }
    if (pose.flash) {
        drawPath(Art.circle(foot.x, foot.y - r * 1.4f, r * 1.9f), Color.White.copy(alpha = 0.55f), blendMode = BlendMode.Plus)
    }
}

private fun bobOf(pose: Art.Pose, amount: Float, mult: Double = 1.0): Float =
    if (pose.moving) abs(sin(pose.phase * mult)).toFloat() * amount else 0f

private fun DrawScope.legs(pose: Art.Pose, color: Color, line: Float, spread: Float = 0.45f, length: Float = 0.9f) {
    val swing = if (pose.moving) sin(pose.phase).toFloat() * 0.35f else 0f
    for ((i, s) in listOf(-spread, spread).withIndex()) {
        val dx = s + (if (i == 0) swing else -swing)
        shape(Art.rounded(Art.rect(dx - 0.28f, -length, 0.56f, length), 0.25f), color, line)
        drawPath(Art.rounded(Art.rect(dx - 0.36f, -0.3f, 0.72f, 0.36f), 0.15f), Art.outline)
    }
}

private fun DrawScope.torso(side: Side, line: Float, width: Float = 1.5f, height: Float = 1.5f, bottom: Float = -0.6f, color: Color? = null, dark: Color? = null) {
    val frame = Art.rect(-width / 2, bottom - height, width, height)
    shape(Art.rounded(frame, width * 0.35f), Art.vertical(color ?: Art.team(side), dark ?: Art.teamDark(side), frame), line)
    drawPath(Art.rounded(Art.rect(-width / 2 + 0.15f, bottom - height + 0.12f, width * 0.35f, height * 0.5f), 0.2f), Color.White.copy(alpha = 0.18f))
}

private fun DrawScope.head(cy: Float, r: Float, color: Color = Art.skin, dark: Color = Art.skinShade, line: Float, eyes: Boolean = true) {
    ball(0f, cy, r, color, dark, line)
    if (eyes) {
        drawPath(Art.circle(r * 0.35f, cy + r * 0.05f, r * 0.14f), Art.outline)
        drawPath(Art.circle(r * 0.72f, cy + r * 0.05f, r * 0.14f), Art.outline)
    }
}

private fun DrawScope.arm(x: Float, y: Float, r: Float, color: Color, dark: Color, line: Float) = ball(x, y, r, color, dark, line)

private fun DrawScope.knight(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.steelDark, line)
    translate(0f, -bobOf(pose, 0.08f)) {
        torso(side, line, 1.7f, 1.5f)
        drawRect(Art.woodDark, Offset(-0.85f, -1.05f), Size(1.7f, 0.22f))
        drawPath(Art.circle(0f, -0.94f, 0.14f), Art.gold)
        val shield = Art.ellipse(-0.95f, -1.35f, 0.55f, 0.7f)
        shape(shield, Art.radial(listOf(Art.teamLight(side), Art.team(side), Art.teamDark(side)), Offset(-1.1f, -1.55f), 0.9f), line)
        drawPath(Art.ellipse(-0.95f, -1.35f, 0.36f, 0.48f), Art.gold, style = Stroke(0.1f))
        drawPath(Art.circle(-0.95f, -1.35f, 0.12f), Art.gold)
        val swing = pose.attack.toFloat() * 2.2f
        arm(0.95f, -1.35f + swing * 0.1f, 0.34f, Art.steel, Art.steelDark, line)
        sword(Offset(1.0f, -1.3f), Offset(1.35f + swing * 0.5f, -2.75f + swing * 0.9f), 0.16f)
        head(-2.55f, 0.62f, line = line)
        val helm = Art.polygon(-0.7f to -2.5f, -0.66f to -2.9f, 0f to -3.35f, 0.66f to -2.9f, 0.7f to -2.5f)
        shape(helm, Art.vertical(Art.steel, Art.steelDark, helm.getBounds()), line)
        drawRect(Art.steelDark, Offset(0.05f, -3.1f), Size(0.14f, 0.75f))
        drawRect(Art.steelDark, Offset(-0.7f, -2.6f), Size(1.4f, 0.16f))
        drawPath(Art.polygon(0f to -3.35f, -0.1f to -3.75f, 0.35f to -3.85f, 0.25f to -3.3f), Art.team(side))
    }
}

private fun DrawScope.archer(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.woodDark, line, spread = 0.38f, length = 0.85f)
    translate(0f, -bobOf(pose, 0.08f)) {
        shape(Art.rounded(Art.rect(-1.0f, -2.4f, 0.4f, 1.3f), 0.15f), Art.wood, line)
        for (i in 0 until 3) drawRect(Art.bone, Offset(-0.95f + i * 0.12f, -2.75f), Size(0.06f, 0.4f))
        torso(side, line, 1.35f, 1.4f, color = Art.leaf, dark = Art.leafDark)
        drawRect(Art.team(side), Offset(-0.68f, -1.0f), Size(1.35f, 0.2f))
        val draw = pose.attack.toFloat() * 1.5f
        val bow = Path().apply { moveTo(1.05f, -2.7f); quadraticBezierTo(1.9f, -1.7f, 1.05f, -0.7f) }
        drawPath(bow, Art.outline, style = Stroke(0.3f, cap = StrokeCap.Round))
        drawPath(bow, Art.wood, style = Stroke(0.14f, cap = StrokeCap.Round))
        val string = Path().apply { moveTo(1.05f, -2.7f); lineTo(1.05f - draw * 0.4f, -1.7f); lineTo(1.05f, -0.7f) }
        drawPath(string, Art.bone, style = Stroke(0.05f))
        arm(0.85f, -1.5f, 0.28f, Art.skin, Art.skinShade, line)
        head(-2.45f, 0.58f, line = line)
        val hood = Art.polygon(-0.7f to -2.35f, -0.75f to -2.9f, 0f to -3.4f, 0.6f to -3.05f, 0.66f to -2.5f, 0.35f to -2.6f, -0.2f to -2.75f)
        shape(hood, Art.vertical(Art.leaf, Art.leafDark, hood.getBounds()), line)
        drawRect(Color(0.9f, 0.3f, 0.3f), Offset(-0.2f, -3.6f), Size(0.08f, 0.7f))
    }
}

private fun DrawScope.colossus(side: Side, pose: Art.Pose, line: Float) {
    val step = if (pose.moving) sin(pose.phase).toFloat() * 0.3f else 0f
    for ((i, x) in listOf(-0.85f, 0.85f).withIndex()) {
        val dx = x + (if (i == 0) step else -step)
        val r = Art.rect(dx - 0.5f, -1.2f, 1.0f, 1.2f)
        shape(Art.rounded(r, 0.35f), Art.vertical(Art.stone, Art.stoneDark, r), line)
    }
    translate(0f, -bobOf(pose, 0.1f)) {
        val body = Art.polygon(-1.7f to -1.0f, -1.95f to -2.3f, -1.4f to -3.5f, -0.5f to -4.1f, 0.7f to -4.15f, 1.6f to -3.4f, 1.95f to -2.2f, 1.6f to -1.0f)
        shape(body, Art.radial(listOf(Art.stoneLight, Art.stone, Art.stoneDark), Offset(-0.6f, -3.2f), 3.2f), line * 1.2f)
        val cracks = Path().apply {
            moveTo(-0.9f, -1.4f); lineTo(-0.4f, -2.1f); lineTo(-0.7f, -2.6f)
            moveTo(1.1f, -3.1f); lineTo(0.8f, -2.4f)
        }
        drawPath(cracks, Art.stoneDark, style = Stroke(0.1f, cap = StrokeCap.Round))
        drawPath(Art.circle(0f, -2.0f, 0.32f), Art.team(side))
        drawPath(Art.circle(0f, -2.0f, 0.16f), Art.teamLight(side))
        for (x in listOf(-0.55f, 0.45f)) {
            drawPath(Art.ellipse(x + 0.35f, -3.35f, 0.3f, 0.16f), Art.outline)
            drawPath(Art.ellipse(x + 0.35f, -3.35f, 0.2f, 0.09f), Art.team(side))
        }
        drawPath(Art.rounded(Art.rect(-1.05f, -3.75f, 2.1f, 0.25f), 0.1f), Art.stoneDark)
        val punch = pose.attack.toFloat() * 1.4f
        shape(Art.circle(-1.9f, -1.55f, 0.55f), Art.vertical(Art.stone, Art.stoneDark, Art.rect(-2.45f, -2.1f, 1.1f, 1.1f)), line)
        shape(Art.circle(2.0f + punch * 0.3f, -1.55f - punch * 0.4f, 0.55f), Art.vertical(Art.stone, Art.stoneDark, Art.rect(1.45f, -2.1f, 1.1f, 1.1f)), line)
    }
}

private fun DrawScope.duelist(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.outline, line, spread = 0.4f, length = 0.95f)
    translate(0f, -bobOf(pose, 0.09f)) {
        val cape = Art.polygon(-0.6f to -2.3f, 0.3f to -2.3f, -0.3f to -0.35f, -1.35f to -0.5f)
        shape(cape, Art.vertical(Art.team(side), Art.teamDark(side), cape.getBounds()), line)
        torso(side, line, 1.35f, 1.5f, color = Color(0.92f, 0.92f, 0.92f), dark = Color(0.7f, 0.7f, 0.7f))
        drawRect(Art.gold, Offset(-0.68f, -1.0f), Size(1.35f, 0.2f))
        drawRect(Art.team(side), Offset(-0.1f, -2.1f), Size(0.2f, 1.05f))
        val lunge = pose.attack.toFloat() * 3f
        arm(0.8f + lunge * 0.15f, -1.75f, 0.28f, Art.skin, Art.skinShade, line)
        val blade = Art.segment(Offset(0.9f + lunge * 0.15f, -1.75f), Offset(2.6f + lunge * 0.6f, -1.8f - lunge * 0.05f))
        drawPath(blade, Art.outline, style = Stroke(0.22f, cap = StrokeCap.Round))
        drawPath(blade, Art.steel, style = Stroke(0.09f, cap = StrokeCap.Round))
        drawPath(Art.circle(1.15f + lunge * 0.15f, -1.75f, 0.16f), Art.gold)
        head(-2.5f, 0.58f, line = line)
        val helm = Art.polygon(-0.66f to -2.55f, -0.6f to -3.05f, 0f to -3.3f, 0.6f to -3.05f, 0.66f to -2.55f)
        shape(helm, Art.vertical(Art.steel, Art.steelDark, helm.getBounds()), line)
        drawRect(Art.steelDark, Offset(-0.66f, -2.62f), Size(1.32f, 0.12f))
        val plume = Path().apply {
            moveTo(0f, -3.3f)
            quadraticBezierTo(-0.4f, -4.2f, -1.2f, -3.3f)
            quadraticBezierTo(-0.5f, -3.5f, 0f, -3.3f)
        }
        shape(plume, Color(0.9f, 0.2f, 0.3f), line * 0.8f)
    }
}

private fun DrawScope.sharpshooter(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.woodDark, line, spread = 0.4f, length = 0.9f)
    translate(0f, -bobOf(pose, 0.08f)) {
        torso(side, line, 1.45f, 1.5f, color = Color(0.36f, 0.22f, 0.16f), dark = Color(0.2f, 0.12f, 0.08f))
        drawRect(Art.team(side), Offset(-0.7f, -1.0f), Size(1.4f, 0.2f))
        drawRect(Art.team(side), Offset(-0.4f, -2.1f), Size(0.8f, 0.55f))
        val recoil = pose.attack.toFloat() * 1.2f
        val barrel = Art.segment(Offset(-0.5f - recoil * 0.2f, -1.55f), Offset(2.5f - recoil * 0.2f, -1.75f))
        drawPath(barrel, Art.outline, style = Stroke(0.34f, cap = StrokeCap.Round))
        drawPath(barrel, Art.steelDark, style = Stroke(0.16f, cap = StrokeCap.Round))
        shape(Art.rounded(Art.rect(-0.8f - recoil * 0.2f, -1.65f, 1.2f, 0.3f), 0.1f), Art.wood, line * 0.8f)
        arm(0.85f - recoil * 0.2f, -1.6f, 0.27f, Art.skin, Art.skinShade, line)
        if (pose.attack > 0.15) drawPath(Art.circle(2.65f, -1.78f, 0.28f + recoil * 0.1f), Art.fireCore.copy(alpha = 0.9f))
        head(-2.5f, 0.58f, line = line)
        shape(Art.ellipse(0.05f, -2.9f, 1.05f, 0.28f), Color(0.25f, 0.15f, 0.1f), line)
        val top = Art.rect(-0.5f, -3.65f, 1.0f, 0.85f)
        shape(Art.rounded(top, 0.2f), Art.vertical(Color(0.36f, 0.22f, 0.16f), Color(0.22f, 0.12f, 0.08f), top), line)
        drawRect(Art.gold, Offset(-0.5f, -3.05f), Size(1.0f, 0.16f))
        drawPath(Art.polygon(0.3f to -3.55f, 0.9f to -4.1f, 0.6f to -3.4f), Art.bone)
    }
}

private fun DrawScope.gremlin(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.goblin, line, spread = 0.35f, length = 0.7f)
    translate(0f, -bobOf(pose, 0.15f, 1.5)) {
        torso(side, line, 1.2f, 1.1f, bottom = -0.5f, color = Art.goblin, dark = Art.goblinDark)
        shape(Art.rounded(Art.rect(-0.6f, -1.15f, 1.2f, 0.35f), 0.1f), Art.team(side), line * 0.7f)
        val stab = pose.attack.toFloat() * 2.5f
        val blade = Art.segment(Offset(0.6f + stab * 0.2f, -1.2f), Offset(1.35f + stab * 0.3f, -1.9f))
        drawPath(blade, Art.outline, style = Stroke(0.24f, cap = StrokeCap.Round))
        drawPath(blade, Art.steel, style = Stroke(0.1f, cap = StrokeCap.Round))
        arm(0.65f + stab * 0.2f, -1.15f, 0.24f, Art.goblin, Art.goblinDark, line)
        for (x in listOf(-1f, 1f)) {
            shape(Art.polygon(x * 0.5f to -2.3f, x * 1.35f to -2.95f, x * 0.55f to -2.75f), Art.goblin, line)
        }
        head(-2.3f, 0.7f, Art.goblin, Art.goblinDark, line, eyes = false)
        for (x in listOf(0.15f, 0.55f)) {
            drawPath(Art.circle(x, -2.4f, 0.19f), Color(1.0f, 0.9f, 0.3f))
            drawPath(Art.circle(x + 0.06f, -2.4f, 0.09f), Art.outline)
        }
        val grin = Path().apply { moveTo(0f, -1.95f); quadraticBezierTo(0.3f, -1.7f, 0.6f, -2.0f) }
        drawPath(grin, Art.outline, style = Stroke(0.08f))
        drawPath(Art.polygon(0.15f to -1.85f, 0.25f to -1.6f, 0.35f to -1.85f), Art.bone)
    }
}

private fun DrawScope.skeleton(side: Side, pose: Art.Pose, line: Float) {
    legs(pose, Art.bone, line, spread = 0.3f, length = 0.8f)
    translate(0f, -bobOf(pose, 0.12f, 1.4)) {
        shape(Art.rounded(Art.rect(-0.6f, -2.05f, 1.2f, 1.35f), 0.4f), Art.bone, line)
        for (i in 0 until 3) drawRect(Art.outline.copy(alpha = 0.7f), Offset(-0.45f, -1.85f + i * 0.35f), Size(0.9f, 0.14f))
        drawPath(Art.rounded(Art.rect(-0.62f, -0.85f, 1.24f, 0.22f), 0.05f), Art.team(side))
        val swing = pose.attack.toFloat() * 2f
        sword(Offset(0.75f, -1.4f), Offset(1.1f + swing * 0.5f, -2.5f + swing * 0.7f), 0.12f)
        arm(0.7f, -1.45f, 0.22f, Art.bone, Color(0.75f, 0.75f, 0.75f), line)
        head(-2.6f, 0.6f, Art.bone, Color(0.72f, 0.72f, 0.72f), line, eyes = false)
        drawPath(Art.ellipse(0.12f, -2.65f, 0.19f, 0.22f), Art.outline)
        drawPath(Art.ellipse(0.55f, -2.65f, 0.17f, 0.2f), Art.outline)
        drawPath(Art.circle(0.15f, -2.68f, 0.06f), Art.team(side))
        drawPath(Art.circle(0.57f, -2.68f, 0.05f), Art.team(side))
        for (i in 0 until 3) drawRect(Art.outline.copy(alpha = 0.6f), Offset(0.05f + i * 0.18f, -2.25f), Size(0.08f, 0.16f))
    }
}

private fun DrawScope.whelp(side: Side, pose: Art.Pose, line: Float) {
    val flap = sin(pose.time * 9).toFloat()
    val hover = -1.4f + sin(pose.time * 3).toFloat() * 0.15f
    translate(0f, hover) {
        val dark = Color(0.16f, 0.42f, 0.4f)
        for (sx in listOf(-1f, 1f)) {
            val wing = Art.polygon(
                sx * 0.5f to -1.9f, sx * 1.7f to -2.9f - flap * 0.5f, sx * 2.5f to -2.2f - flap * 0.6f,
                sx * 2.05f to -1.5f - flap * 0.3f, sx * 1.4f to -1.35f,
            )
            shape(wing, Art.vertical(Art.team(side), Art.teamDark(side), wing.getBounds()), line)
            val veins = Path().apply {
                moveTo(sx * 0.6f, -1.85f); lineTo(sx * 1.7f, -2.85f - flap * 0.5f)
                moveTo(sx * 0.6f, -1.8f); lineTo(sx * 2.45f, -2.2f - flap * 0.6f)
            }
            drawPath(veins, Art.teamDark(side), style = Stroke(0.07f))
        }
        val tail = Path().apply { moveTo(-0.7f, -1.2f); quadraticBezierTo(-1.7f, -1.5f, -1.9f, -0.4f) }
        drawPath(tail, Art.outline, style = Stroke(0.44f, cap = StrokeCap.Round))
        drawPath(tail, Art.dragon, style = Stroke(0.26f, cap = StrokeCap.Round))
        drawPath(Art.polygon(-1.9f to -0.15f, -2.35f to -0.55f, -1.75f to -0.7f), Art.team(side))
        ball(0f, -1.5f, 1.0f, Art.dragon, dark, line)
        drawPath(Art.ellipse(0.2f, -1.3f, 0.55f, 0.65f), Art.dragonBelly)
        for (x in listOf(-0.4f, 0.4f)) shape(Art.ellipse(x, -0.55f, 0.3f, 0.2f), Art.dragon, line)
        ball(0.75f, -2.55f, 0.72f, Art.dragon, dark, line)
        shape(Art.rounded(Art.rect(1.0f, -2.55f, 0.85f, 0.5f), 0.2f), Art.dragon, line)
        drawPath(Art.circle(1.7f, -2.4f, 0.06f), Art.outline)
        drawPath(Art.circle(0.95f, -2.75f, 0.2f), Color(1.0f, 0.85f, 0.3f))
        drawPath(Art.circle(1.0f, -2.75f, 0.1f), Art.outline)
        for (x in listOf(0.3f, 0.6f)) drawPath(Art.polygon(x to -3.15f, x + 0.2f to -3.65f, x + 0.35f to -3.1f), Art.team(side))
        if (pose.attack > 0.1) {
            val f = pose.attack.toFloat() * 4
            drawPath(Art.ellipse(2.2f + f * 0.4f, -2.3f, 0.5f + f * 0.3f, 0.3f + f * 0.15f), Art.fire.copy(alpha = 0.9f))
            drawPath(Art.ellipse(2.1f + f * 0.3f, -2.3f, 0.3f + f * 0.2f, 0.18f + f * 0.1f), Art.fireCore)
        }
    }
}

// Towers

fun DrawScope.tower(kind: TowerKind, side: Side, center: Offset, r: Float, alive: Boolean, activated: Boolean, flash: Boolean, time: Double) {
    withTransform({
        translate(center.x, center.y)
        scale(r, r, Offset.Zero)
    }) {
        val line = 0.09f
        if (!alive) {
            rubble(kind, side, line)
            return@withTransform
        }
        val keep = kind == TowerKind.KEEP
        val w = if (keep) 1.9f else 1.5f
        val h = if (keep) 1.9f else 1.7f
        val base = Art.rect(-w / 2, -h * 0.55f, w, h)
        softShadow(0.15f, base.bottom - 0.1f, w * 0.75f, 0.35f, 0.45f)
        if (keep) {
            for (x in listOf(-1.05f, 1.05f)) {
                val tr = Art.rect(x - 0.32f, -0.55f, 0.64f, 1.25f)
                shape(Art.rounded(tr, 0.12f), Art.horizontal(Art.stoneLight, Art.stoneDark, tr), line)
                val cone = Art.polygon(tr.left - 0.1f to tr.top, tr.center.x to tr.top - 0.7f, tr.right + 0.1f to tr.top)
                shape(cone, Art.vertical(Art.teamLight(side), Art.teamDark(side), cone.getBounds()), line)
            }
        }
        shape(Art.rounded(base, 0.12f), Art.horizontal(Art.stoneLight, Art.stoneDark, base), line)
        val bricks = Path()
        var row = 0
        var y = base.top + 0.25f
        while (y < base.bottom - 0.15f) {
            bricks.moveTo(base.left, y); bricks.lineTo(base.right, y)
            var x = base.left + (if (row % 2 == 0) 0f else 0.25f)
            while (x < base.right) { bricks.moveTo(x, y); bricks.lineTo(x, minOf(base.bottom, y + 0.25f)); x += 0.5f }
            y += 0.25f
            row++
        }
        drawPath(bricks, Art.stoneDark.copy(alpha = 0.35f), style = Stroke(0.035f))
        shape(Art.rounded(Art.rect(-0.28f, base.bottom - 0.6f, 0.56f, 0.6f), 0.25f), Art.woodDark, line * 0.8f)
        val glow = if (activated) (if (side == Side.PLAYER) Color(1.0f, 0.85f, 0.4f) else Color(1.0f, 0.6f, 0.3f)) else Color(0.15f, 0.15f, 0.15f)
        for (x in if (keep) listOf(-0.42f, 0.42f) else listOf(0f)) {
            shape(Art.rounded(Art.rect(x - 0.14f, base.top + 0.55f, 0.28f, 0.42f), 0.14f), glow, line * 0.7f)
        }
        val rim = Art.rect(base.left - 0.15f, base.top - 0.22f, base.width + 0.3f, 0.32f)
        shape(Art.rounded(rim, 0.06f), Art.vertical(Art.stoneLight, Art.stone, rim), line)
        val count = if (keep) 5 else 4
        for (i in 0 until count) {
            val bx = rim.left + rim.width * (i + 0.5f) / count
            shape(Art.rounded(Art.rect(bx - 0.12f, rim.top - 0.22f, 0.24f, 0.26f), 0.04f), Art.stoneLight, line * 0.8f)
        }
        if (keep) {
            val dome = Art.rect(-0.75f, rim.top - 1.1f, 1.5f, 1.2f)
            val domeBase = dome.bottom - 0.1f
            val domePath = Path().apply {
                moveTo(-0.75f, domeBase)
                cubicTo(-0.75f, domeBase - 1.05f, 0.75f, domeBase - 1.05f, 0.75f, domeBase)
                close()
            }
            shape(Art.rounded(Art.rect(-0.82f, domeBase - 0.08f, 1.64f, 0.2f), 0.05f), Art.stone, line)
            shape(domePath, Art.radial(listOf(Art.teamLight(side), Art.team(side), Art.teamDark(side)), Offset(-0.3f, dome.top + 0.4f), 1.2f), line)
            crown(Offset(0f, dome.top - 0.05f), 0.7f, line = line * 0.8f)
        } else {
            val cone = Art.polygon(rim.left + 0.05f to rim.top - 0.15f, 0f to rim.top - 1.35f, rim.right - 0.05f to rim.top - 0.15f)
            shape(cone, Art.horizontal(Art.teamLight(side), Art.teamDark(side), cone.getBounds()), line)
            drawPath(Art.polygon(-0.1f to rim.top - 0.15f, 0f to rim.top - 1.35f, 0.35f to rim.top - 0.15f), Color.White.copy(alpha = 0.18f))
            val topY = rim.top - 1.35f
            drawPath(Art.segment(Offset(0f, topY), Offset(0f, topY - 0.6f)), Art.woodDark, style = Stroke(0.06f))
            val wave = sin(time * 5 + center.x).toFloat()
            shape(Art.polygon(0f to topY - 0.6f, 0.7f to topY - 0.5f + wave * 0.08f, 0.02f to topY - 0.25f), Art.gold, line * 0.7f)
        }
        if (flash) {
            drawPath(Art.rounded(base.inflate(0.2f).let { Rect(it.left, it.top - 0.6f, it.right, it.bottom + 0.6f) }, 0.3f), Color.White.copy(alpha = 0.35f), blendMode = BlendMode.Plus)
        }
    }
}

fun DrawScope.rubble(kind: TowerKind, side: Side, line: Float) {
    val s = if (kind == TowerKind.KEEP) 1.2f else 1.0f
    drawPath(Art.ellipse(0f, 0.35f * s, 1.25f * s, 0.55f * s), Color(0.16f, 0.12f, 0.1f).copy(alpha = 0.6f))
    val blocks = listOf(
        listOf(-0.7f, 0.15f, 0.6f, 0.45f, -12f), listOf(0.1f, 0.05f, 0.75f, 0.55f, 8f), listOf(-0.25f, -0.35f, 0.55f, 0.45f, 20f),
        listOf(0.55f, -0.15f, 0.5f, 0.4f, -25f), listOf(-0.05f, 0.3f, 0.45f, 0.35f, 0f),
    )
    for ((x, y, w, h, angle) in blocks.map { Quint(it[0], it[1], it[2], it[3], it[4]) }) {
        withTransform({
            translate(x * s, y * s)
            rotate(angle, Offset.Zero)
        }) {
            val r = Art.rect(-w * s / 2, -h * s / 2, w * s, h * s)
            shape(Art.rounded(r, 0.08f), Art.vertical(Art.stoneLight, Art.stoneDark, r), line)
        }
    }
    val banner = Art.polygon(-0.9f * s to -0.2f * s, -0.3f * s to -0.35f * s, -0.2f * s to 0.1f * s, -0.8f * s to 0.25f * s)
    shape(banner, Art.teamDark(side), line * 0.8f)
}

private data class Quint(val a: Float, val b: Float, val c: Float, val d: Float, val e: Float)

// Card illustrations

/** Character (or spell) on a themed vignette filling [size]. */
fun DrawScope.cardArt(card: CardDef, size: Size) {
    val w = size.width; val h = size.height
    val top: Color; val bottom: Color
    when (card.kind) {
        CardKind.SPELL -> { top = Color(0.55f, 0.24f, 0.75f); bottom = Color(0.22f, 0.07f, 0.4f) }
        CardKind.TROOP -> {
            top = if (card.flying) Color(0.45f, 0.72f, 0.95f) else Color(0.42f, 0.65f, 0.32f)
            bottom = if (card.flying) Color(0.16f, 0.32f, 0.62f) else Color(0.16f, 0.34f, 0.16f)
        }
    }
    drawRect(Art.radial(listOf(top, bottom), Offset(w * 0.5f, h * 0.35f), h * 0.9f))
    for (i in 0 until 6) {
        val a = i / 6f * Math.PI.toFloat() * 2
        val p = Art.polygon(
            w / 2 to h * 0.4f,
            w / 2 + cos(a) * h to h * 0.4f + sin(a) * h,
            w / 2 + cos(a + 0.25f) * h to h * 0.4f + sin(a + 0.25f) * h,
        )
        drawPath(p, Color.White.copy(alpha = 0.16f))
    }
    if (card.kind == CardKind.TROOP && !card.flying) {
        drawPath(Art.ellipse(w / 2, h * 0.84f, w * 0.55f, h * 0.09f), Color(0.2f, 0.4f, 0.16f))
    }
    val r = minOf(w, h) * (if (card.count > 1) 0.14f else if (card.id == "giant") 0.15f else 0.19f)
    val foot = Offset(w / 2, if (card.flying) h * 0.84f + r * 1.6f else h * 0.84f)
    when (card.kind) {
        CardKind.SPELL -> spellArt(card, size)
        CardKind.TROOP -> {
            if (card.count > 1) {
                val n = minOf(card.count, 3)
                for (i in 0 until n) {
                    val dx = (i - (n - 1) / 2f) * r * 2.4f
                    character(card.id, Side.PLAYER, Offset(foot.x + dx, foot.y - (i % 2) * r * 0.9f), r, Art.Pose(phase = i.toDouble(), attack = 0.6))
                }
            } else {
                character(card.id, Side.PLAYER, foot, r, Art.Pose(attack = 0.55))
            }
        }
    }
}

private fun DrawScope.spellArt(card: CardDef, size: Size) {
    val w = size.width; val h = size.height
    if (card.id == "meteor") {
        val trail = Art.segment(Offset(w * 0.85f, h * 0.1f), Offset(w * 0.45f, h * 0.58f))
        drawPath(trail, Art.fire.copy(alpha = 0.5f), style = Stroke(w * 0.22f, cap = StrokeCap.Round))
        drawPath(trail, Art.fireCore.copy(alpha = 0.8f), style = Stroke(w * 0.1f, cap = StrokeCap.Round))
        ball(w * 0.42f, h * 0.6f, w * 0.2f, Art.fireCore, Art.fire, max(1f, w * 0.03f))
        drawPath(Art.circle(w * 0.36f, h * 0.55f, w * 0.05f), Color(0.5f, 0.2f, 0.1f))
        drawPath(Art.circle(w * 0.5f, h * 0.66f, w * 0.035f), Color(0.5f, 0.2f, 0.1f))
        drawPath(Art.ellipse(w * 0.45f, h * 0.86f, w * 0.35f, h * 0.06f), Art.fire.copy(alpha = 0.45f))
    } else {
        for (i in 0 until 7) {
            val x = w * (0.15f + 0.12f * i)
            val y = h * (0.25f + 0.08f * ((i * 3) % 5))
            val a = Art.segment(Offset(x + w * 0.06f, y - h * 0.18f), Offset(x, y + h * 0.2f))
            drawPath(a, Art.outline, style = Stroke(max(1.5f, w * 0.03f), cap = StrokeCap.Round))
            drawPath(a, Art.wood, style = Stroke(max(1f, w * 0.015f), cap = StrokeCap.Round))
            drawPath(Art.polygon(x to y + h * 0.2f, x - w * 0.035f to y + h * 0.12f, x + w * 0.035f to y + h * 0.13f), Art.steel)
            drawPath(Art.polygon(x + w * 0.06f to y - h * 0.18f, x + w * 0.1f to y - h * 0.14f, x + w * 0.04f to y - h * 0.11f), Color.White)
        }
        drawPath(Art.ellipse(w * 0.5f, h * 0.86f, w * 0.4f, h * 0.06f), Color.Cyan.copy(alpha = 0.35f))
    }
}
