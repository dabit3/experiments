package com.dabit3.towertussle

import android.content.res.AssetManager
import android.graphics.BitmapFactory
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.sin

class RenderedArt(private val assets: AssetManager) {
    private val images = mutableMapOf<String, ImageBitmap>()

    fun image(name: String): ImageBitmap = images.getOrPut(name) {
        assets.open("art/$name.png").use { input ->
            requireNotNull(BitmapFactory.decodeStream(input)) { "Invalid artwork: $name" }.asImageBitmap()
        }
    }

    fun preloadBattle() {
        image("arena")
        for (card in Cards.all.filter { it.kind == CardKind.TROOP }) image("units_${card.id}")
        for (kind in listOf("keep", "guard")) for (team in listOf("blue", "red")) image("tower_${kind}_$team")
    }
}

@Composable
fun rememberArt(battle: Boolean = false): RenderedArt {
    val assets = LocalContext.current.assets
    return remember(assets, battle) { RenderedArt(assets).apply { if (battle) preloadBattle() } }
}

@Composable
fun RenderedImage(name: String, modifier: Modifier = Modifier, fill: Boolean = false, muted: Boolean = false) {
    val art = rememberArt()
    val image = remember(art, name) { art.image(name) }
    Image(
        image, contentDescription = null, modifier = modifier,
        contentScale = if (fill) ContentScale.Crop else ContentScale.Fit,
        colorFilter = if (muted) ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0.2f) }) else null,
    )
}

fun DrawScope.renderedImage(image: ImageBitmap, origin: Offset, dimensions: Size, flash: Boolean = false) {
    drawImage(
        image, dstOffset = IntOffset(origin.x.toInt(), origin.y.toInt()),
        dstSize = IntSize(dimensions.width.toInt().coerceAtLeast(1), dimensions.height.toInt().coerceAtLeast(1)),
        filterQuality = FilterQuality.Medium,
        colorFilter = if (flash) ColorFilter.lighting(Color.White, Color(0xFF555555)) else null,
    )
}

fun DrawScope.renderedUnit(art: RenderedArt, unit: Troop, foot: Offset, radius: Float) {
    val frame = if (unit.attackAnim > 0) {
        if (unit.attackAnim > 0.12) 4 else 5
    } else if (unit.moving) (abs(unit.walkPhase) / (PI / 2)).toInt() % 4 else 0
    val width = radius * 5f
    val lift = if (unit.card.flying) radius * 1.5f + sin(unit.walkPhase).toFloat() * radius * 0.2f else 0f
    withTransform({
        translate(foot.x, foot.y - lift)
        scale(if (unit.facing < 0) -1f else 1f, 1f, Offset.Zero)
    }) {
        drawImage(
            art.image("units_${unit.card.id}"), srcOffset = IntOffset(frame * 256, if (unit.side == Side.ENEMY) 256 else 0), srcSize = IntSize(256, 256),
            dstOffset = IntOffset((-width * 0.5f).toInt(), (-width * 0.79f).toInt()),
            dstSize = IntSize(width.toInt().coerceAtLeast(1), width.toInt().coerceAtLeast(1)),
            filterQuality = FilterQuality.Medium,
            colorFilter = if (unit.hitFlash > 0) ColorFilter.lighting(Color.White, Color(0xFF555555)) else null,
        )
    }
}

@Composable
fun SceneryBackdrop(modifier: Modifier = Modifier, dim: Float = 0f) {
    Canvas(modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height
        drawRect(Brush.verticalGradient(listOf(Color(0xFF061229), Color(0xFF0E3047), Color(0xFF060B1F))))
        val center = Offset(w * 0.5f, h * 0.45f)
        drawCircle(Brush.radialGradient(listOf(Color.Cyan.copy(alpha = 0.15f), Color.Transparent), center, w * 0.8f), w * 0.8f, center)
        for (i in 0..2) drawCircle(Color.Cyan.copy(alpha = 0.06f), w * (0.52f + i * 0.22f), center, style = Stroke(1.dp.toPx()))
        for (i in 0 until 65) {
            val x = ((i * 0.618 + 0.13) % 1).toFloat() * w
            val y = ((i * 0.2713 + 0.04) % 1).toFloat() * h
            drawCircle((if (i % 4 == 0) Art.gold else Color.Cyan).copy(alpha = 0.35f), (if (i % 5 == 0) 1.6f else 0.7f) * density, Offset(x, y))
        }
        if (dim > 0) drawRect(Color.Black.copy(alpha = dim))
    }
}
