package com.dabit3.towertussle

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.sin

enum class IconKind { TROPHY, COIN, CROWN, ELIXIR, SWORDS, CARDS, CLOCK, HOME }

/** Vector icon drawn with the shared Art helpers. */
@Composable
fun IconView(kind: IconKind, size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size)) {
        val c = Offset(this.size.width / 2, this.size.height / 2)
        val s = this.size.minDimension
        when (kind) {
            IconKind.TROPHY -> trophy(c, s)
            IconKind.COIN -> coin(c, s)
            IconKind.CROWN -> crown(c, s)
            IconKind.ELIXIR -> elixirDrop(c, s)
            IconKind.SWORDS -> swordsIcon(c, s)
            IconKind.CARDS -> cardsIcon(c, s)
            IconKind.CLOCK -> clock(c, s)
            IconKind.HOME -> {
                val house = Art.polygon(c.x - s * 0.4f to c.y + s * 0.4f, c.x - s * 0.4f to c.y, c.x to c.y - s * 0.42f, c.x + s * 0.4f to c.y, c.x + s * 0.4f to c.y + s * 0.4f)
                shape(house, Art.vertical(Art.stoneLight, Art.stoneDark, house.getBounds()), s * 0.07f)
                drawPath(Art.rounded(Art.rect(c.x - s * 0.1f, c.y + s * 0.1f, s * 0.2f, s * 0.3f), s * 0.05f), Art.woodDark)
            }
        }
    }
}

/** Heavy display text with a dark outline and drop shadow. */
@Composable
fun DisplayText(
    text: String,
    size: TextUnit,
    color: Color = Color.White,
    modifier: Modifier = Modifier,
    outline: Color = Art.outline,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
) {
    val strokeWidth = size.value * 0.16f
    val fill = if (textAlign != null) Modifier.fillMaxWidth() else Modifier
    Box(modifier) {
        Text(
            text, fontSize = size, fontWeight = FontWeight.Black, color = outline, textAlign = textAlign, maxLines = maxLines,
            overflow = TextOverflow.Clip, modifier = fill,
            style = TextStyle(
                drawStyle = Stroke(width = strokeWidth, join = StrokeJoin.Round),
                shadow = Shadow(Color.Black.copy(alpha = 0.5f), Offset(0f, size.value * 0.12f), size.value * 0.1f),
            ),
        )
        Text(text, fontSize = size, fontWeight = FontWeight.Black, color = color, textAlign = textAlign, maxLines = maxLines, overflow = TextOverflow.Clip, modifier = fill)
    }
}

enum class ChunkyStyle(val top: Color, val bottom: Color, val edge: Color, val text: Color) {
    GOLD(Color(1.0f, 0.86f, 0.35f), Color(0.98f, 0.62f, 0.12f), Color(0.62f, 0.34f, 0.04f), Color(0.3f, 0.14f, 0.0f)),
    BLUE(Color(0.42f, 0.72f, 1.0f), Color(0.15f, 0.42f, 0.9f), Color(0.06f, 0.2f, 0.5f), Color.White),
    GREEN(Color(0.55f, 0.9f, 0.4f), Color(0.22f, 0.62f, 0.2f), Color(0.08f, 0.32f, 0.08f), Color.White),
    RED(Color(1.0f, 0.55f, 0.5f), Color(0.85f, 0.2f, 0.22f), Color(0.45f, 0.06f, 0.08f), Color.White),
    SLATE(Color(0.5f, 0.56f, 0.7f), Color(0.24f, 0.28f, 0.42f), Color(0.1f, 0.12f, 0.22f), Color.White),
}

/** Beveled 3D-style button used across the menus. */
@Composable
fun ChunkyButton(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: IconKind? = null,
    style: ChunkyStyle = ChunkyStyle.GOLD,
    height: Dp = 60.dp,
    fontSize: TextUnit = 24.sp,
) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val lift = if (pressed) 2.dp else 6.dp
    Box(
        modifier
            .fillMaxWidth()
            .height(height + 6.dp)
            .padding(top = if (pressed) 4.dp else 0.dp)
            .semantics { role = Role.Button }
            .clickable(interactionSource = interaction, indication = null, onClick = onClick),
    ) {
        val shape = RoundedCornerShape(16.dp)
        Box(Modifier.fillMaxWidth().height(height).offset(y = lift).clip(shape).background(style.edge))
        Box(
            Modifier.fillMaxWidth().height(height).shadow(6.dp, shape, clip = false).clip(shape)
                .background(Brush.verticalGradient(listOf(style.top, style.bottom)))
                .drawBehind {
                    val w = size.width; val h = size.height
                    drawRoundRect(Color.White.copy(alpha = 0.18f), Offset(8.dp.toPx(), 5.dp.toPx()), Size(w - 16.dp.toPx(), 22.dp.toPx()), CornerRadius(12.dp.toPx()))
                    drawRoundRect(
                        Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.55f), Color.White.copy(alpha = 0f)), endY = h / 2),
                        Offset(3.dp.toPx(), 3.dp.toPx()), Size(w - 6.dp.toPx(), h - 6.dp.toPx()), CornerRadius(13.dp.toPx()), style = Stroke(2.dp.toPx()),
                    )
                }
                .border(2.5.dp, Art.outline.copy(alpha = 0.9f), shape),
            contentAlignment = Alignment.Center,
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                if (icon != null) IconView(icon, with(LocalDensity.current) { (fontSize.toPx() * 1.25f).toDp() })
                Text(
                    title, fontSize = fontSize, fontWeight = FontWeight.Black, color = style.text,
                    style = TextStyle(shadow = Shadow(if (style == ChunkyStyle.GOLD) Color.White.copy(alpha = 0.35f) else Color.Black.copy(alpha = 0.5f), Offset(0f, if (style == ChunkyStyle.GOLD) 1.5f else -1.5f), 0f)),
                )
            }
        }
    }
}

/** Layered dark panel with a light inset stroke. */
fun Modifier.panel(cornerRadius: Dp = 18.dp, tint: Color = Theme.panel): Modifier = this
    .shadow(6.dp, RoundedCornerShape(cornerRadius), clip = false)
    .clip(RoundedCornerShape(cornerRadius))
    .background(Brush.verticalGradient(listOf(tint.copy(alpha = 0.97f), Theme.background.copy(alpha = 0.98f))))
    .drawBehind {
        val r = cornerRadius.toPx()
        drawRoundRect(
            Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.25f), Color.White.copy(alpha = 0.03f))),
            Offset(2.dp.toPx(), 2.dp.toPx()), Size(size.width - 4.dp.toPx(), size.height - 4.dp.toPx()), CornerRadius(r - 2.dp.toPx()), style = Stroke(1.5.dp.toPx()),
        )
    }
    .border(2.dp, Art.outline.copy(alpha = 0.9f), RoundedCornerShape(cornerRadius))

@Composable
fun ElixirBadge(cost: Int, size: Dp = 24.dp, modifier: Modifier = Modifier) {
    Box(modifier.size(size * 1.15f).semantics { contentDescription = "$cost elixir" }, contentAlignment = Alignment.Center) {
        IconView(IconKind.ELIXIR, size * 1.15f)
        Text(
            "$cost", color = Color.White, fontWeight = FontWeight.Black, fontSize = (size.value * 0.6f).sp,
            modifier = Modifier.offset(y = size * 0.08f),
            style = TextStyle(shadow = Shadow(Color.Black.copy(alpha = 0.8f), Offset(1.5f, 1.5f), 0f)),
        )
    }
}

/** Framed card: illustration, bevel, cost badge and name plaque. */
@Composable
fun CardFrame(
    card: CardDef,
    modifier: Modifier = Modifier,
    selected: Boolean = false,
    affordable: Boolean = true,
    showName: Boolean = true,
    compact: Boolean = false,
) {
    val frameColors = when {
        card.kind == CardKind.SPELL -> listOf(Color(0.85f, 0.65f, 1.0f), Color(0.5f, 0.25f, 0.75f))
        card.count > 1 || card.cost <= 3 -> listOf(Color(0.86f, 0.88f, 0.95f), Color(0.45f, 0.5f, 0.62f))
        else -> listOf(Color(1.0f, 0.9f, 0.5f), Color(0.75f, 0.5f, 0.1f))
    }
    val desaturate = remember(affordable) {
        if (affordable) null else ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0.15f) })
    }
    BoxWithConstraints(modifier.aspectRatio(0.78f)) {
        val w = maxWidth
        val radius = w * 0.14f
        val border = (w * 0.05f).coerceAtLeast(2.dp)
        Box(Modifier.fillMaxSize().colorFiltered(desaturate).alpha(if (affordable) 1f else 0.75f)) {
            Box(
                Modifier.fillMaxSize()
                    .shadow(if (selected) 10.dp else 3.dp, RoundedCornerShape(radius), ambientColor = if (selected) Theme.accent else Color.Black, spotColor = if (selected) Theme.accent else Color.Black)
                    .clip(RoundedCornerShape(radius))
                    .background(Brush.linearGradient(frameColors))
                    .border((w * 0.03f).coerceAtLeast(1.5.dp), Art.outline, RoundedCornerShape(radius)),
            ) {
                Column(Modifier.fillMaxSize().padding(border)) {
                    Canvas(
                        Modifier.fillMaxWidth().weight(1f).clip(RoundedCornerShape(radius * 0.6f))
                            .border(1.dp, Art.outline.copy(alpha = 0.8f), RoundedCornerShape(radius * 0.6f)),
                    ) {
                        cardArt(card, size)
                    }
                    if (showName) {
                        Box(
                            Modifier.fillMaxWidth().padding(top = border * 0.6f).height((w * 0.24f).coerceAtLeast(12.dp))
                                .clip(RoundedCornerShape(radius * 0.4f)).background(Art.outline.copy(alpha = 0.75f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                card.name.uppercase(), color = Color.White, fontWeight = FontWeight.Black,
                                fontSize = (w.value * 0.12f).coerceAtLeast(7f).sp, maxLines = 1, overflow = TextOverflow.Clip,
                                style = TextStyle(shadow = Shadow(Color.Black.copy(alpha = 0.9f), Offset(1f, 1f), 0f)),
                                modifier = Modifier.padding(horizontal = 3.dp),
                            )
                        }
                    }
                }
            }
            if (selected) {
                Box(Modifier.fillMaxSize().border(3.dp, Theme.accent, RoundedCornerShape(radius)))
            }
            ElixirBadge(card.cost, if (compact) w * 0.34f else w * 0.3f, Modifier.offset(x = -w * 0.08f, y = -w * 0.08f))
        }
    }
}

/** Renders the content through a color filter (used to grey out unaffordable cards). */
private fun Modifier.colorFiltered(filter: ColorFilter?): Modifier = if (filter == null) this else drawWithContent {
    drawIntoCanvas { it.saveLayer(Rect(0f, 0f, size.width, size.height), Paint().apply { colorFilter = filter }) }
    drawContent()
    drawIntoCanvas { it.restore() }
}

/** Painted backdrop for the menu screens: sky, hills and a castle skyline. */
@Composable
fun SceneryBackdrop(modifier: Modifier = Modifier, dim: Float = 0f) {
    Canvas(modifier.fillMaxSize()) {
        val w = size.width; val h = size.height
        drawRect(Brush.verticalGradient(listOf(Color(0.09f, 0.15f, 0.36f), Color(0.2f, 0.4f, 0.75f), Color(0.55f, 0.72f, 0.9f)), endY = h * 0.7f))
        drawPath(Art.circle(w * 0.72f, h * 0.32f, w * 0.55f), Art.radial(listOf(Art.gold.copy(alpha = 0.35f), Art.gold.copy(alpha = 0f)), Offset(w * 0.72f, h * 0.32f), w * 0.55f), blendMode = BlendMode.Plus)
        for (i in 0 until 40) {
            val x = ((i * 0.618) % 1.0).toFloat() * w
            val y = ((i * 0.2713 + 0.1) % 1.0).toFloat() * h * 0.35f
            drawPath(Art.circle(x, y, 0.8f + (i % 3) * 0.5f), Color.White.copy(alpha = 0.5f + (i % 4) * 0.12f))
        }
        for ((cx, cy, s) in listOf(Triple(0.2f, 0.22f, 1.0f), Triple(0.75f, 0.15f, 0.7f), Triple(0.5f, 0.32f, 0.55f))) {
            val c = Offset(w * cx, h * cy)
            val r = w * 0.09f * s
            for ((dx, dy, rr) in listOf(Triple(-1.1f, 0.2f, 0.7f), Triple(0f, 0f, 1f), Triple(1.1f, 0.25f, 0.75f), Triple(0.5f, -0.4f, 0.6f))) {
                drawPath(Art.circle(c.x + r * dx, c.y + r * dy, r * rr), Color.White.copy(alpha = 0.18f))
            }
        }
        fun hills(baseY: Float, amp: Float, color: Color, seed: Float) {
            val p = Path()
            p.moveTo(0f, h); p.lineTo(0f, baseY)
            var x = 0f
            while (x <= w) {
                val y = baseY - amp * (0.5f + 0.5f * sin(x / w * 5 + seed)) - amp * 0.3f * sin(x / w * 13 + seed * 2)
                p.lineTo(x, y); x += 8f
            }
            p.lineTo(w, h); p.close()
            drawPath(p, color)
        }
        hills(h * 0.62f, h * 0.08f, Color(0.18f, 0.32f, 0.5f), 1f)
        hills(h * 0.68f, h * 0.07f, Color(0.16f, 0.36f, 0.36f), 3f)
        val baseY = h * 0.7f
        val silhouette = Color(0.1f, 0.16f, 0.3f).copy(alpha = 0.9f)
        for ((cx, cw, ch) in listOf(Triple(0.12f, 0.09f, 0.12f), Triple(0.3f, 0.06f, 0.08f), Triple(0.5f, 0.12f, 0.16f), Triple(0.7f, 0.06f, 0.09f), Triple(0.88f, 0.09f, 0.12f))) {
            val r = Rect(w * cx - w * cw / 2, baseY - h * ch, w * cx + w * cw / 2, baseY + 4)
            drawRect(silhouette, r.topLeft, r.size)
            for (i in 0 until 3) {
                val bx = r.left + r.width * (i + 0.5f) / 3
                drawRect(silhouette, Offset(bx - r.width * 0.12f, r.top - h * 0.015f), Size(r.width * 0.24f, h * 0.02f))
            }
            drawRect(silhouette, Offset(r.center.x - 1, r.top - h * 0.05f), Size(2f, h * 0.05f))
            drawPath(Art.polygon(r.center.x to r.top - h * 0.05f, r.center.x + w * 0.03f to r.top - h * 0.04f, r.center.x to r.top - h * 0.03f), if (cx == 0.5f) Art.gold else Theme.enemy)
            drawPath(Art.rounded(Art.rect(r.center.x - r.width * 0.1f, r.top + r.height * 0.3f, r.width * 0.2f, r.height * 0.18f), r.width * 0.1f), Art.gold.copy(alpha = 0.85f))
        }
        drawRect(silhouette, Offset(0f, baseY - 2), Size(w, h - baseY + 2))
        drawRect(Brush.verticalGradient(listOf(Color(0.2f, 0.42f, 0.24f), Color(0.08f, 0.2f, 0.14f)), startY = baseY, endY = h), Offset(0f, baseY), Size(w, h - baseY))
        for (i in 0 until 60) {
            val x = ((i * 0.731) % 1.0).toFloat() * w
            val y = baseY + ((i * 0.457) % 1.0).toFloat() * (h - baseY)
            val s = 3 + (y - baseY) / (h - baseY) * 5
            val tuft = Path().apply {
                moveTo(x - s, y); lineTo(x - s * 0.4f, y - s * 1.5f)
                moveTo(x, y); lineTo(x, y - s * 2)
                moveTo(x + s, y); lineTo(x + s * 0.4f, y - s * 1.5f)
            }
            drawPath(tuft, Color(0.3f, 0.6f, 0.3f).copy(alpha = 0.5f), style = Stroke(1.5f, cap = StrokeCap.Round))
        }
        if (dim > 0) drawRect(Color.Black.copy(alpha = dim))
    }
}

@Composable
fun StatPill(icon: IconKind, value: String, label: String, modifier: Modifier = Modifier) {
    Row(
        modifier
            .panel(cornerRadius = 22.dp)
            .padding(horizontal = 12.dp, vertical = 8.dp)
            .semantics(mergeDescendants = true) { contentDescription = "$label: $value" },
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconView(icon, 26.dp)
        Column {
            DisplayText(value, 17.sp)
            Text(label, fontSize = 11.sp, color = Color.White.copy(alpha = 0.65f), fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun CrownRow(count: Int, color: Color, size: Dp) {
    Row(Modifier.semantics { contentDescription = "$count crowns" }, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        for (i in 0 until 3) {
            Canvas(Modifier.size(size)) {
                val c = Offset(this.size.width / 2, this.size.height / 2)
                crown(c, this.size.minDimension, color = color, dim = i >= count)
            }
        }
    }
}

@Composable
fun ElixirBar(value: Double, max: Double, modifier: Modifier = Modifier) {
    val fraction = (value / max).toFloat().coerceIn(0f, 1f)
    Row(
        modifier.fillMaxWidth().semantics { contentDescription = "Elixir ${value.toInt()} of ${max.toInt()}" },
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        IconView(IconKind.ELIXIR, 26.dp)
        Box(Modifier.weight(1f).height(22.dp)) {
            Canvas(Modifier.fillMaxSize()) {
                val h = size.height; val w = size.width
                val r = CornerRadius(h / 2)
                drawRoundRect(Art.outline.copy(alpha = 0.9f), Offset.Zero, Size(w, h), r)
                drawRoundRect(Color(0.12f, 0.08f, 0.18f), Offset(2f, 2f), Size(w - 4, h - 4), r)
                val fillW = (w - 4) * fraction
                if (fillW > 0) {
                    drawRoundRect(Brush.verticalGradient(listOf(Color(0.95f, 0.55f, 1.0f), Theme.elixir, Theme.elixirDark)), Offset(2f, 2f), Size(fillW.coerceAtLeast(h - 4), h - 4), r)
                    drawRoundRect(Color.White.copy(alpha = 0.3f), Offset(6f, 4f), Size((fillW - 8).coerceAtLeast(1f), (h - 4) * 0.35f), r)
                }
                for (i in 1 until max.toInt()) {
                    val x = 2 + (w - 4) * i / max.toFloat()
                    drawRect(Art.outline.copy(alpha = 0.55f), Offset(x - 0.75f, 2f), Size(1.5f, h - 4))
                }
            }
            DisplayText("${value.toInt()}", 13.sp, modifier = Modifier.align(Alignment.Center))
        }
    }
}
