/**
 * Sticker artwork is bundled (Twemoji, MIT) so emoji render identically on every OS,
 * in Present mode and in the exported PDF, regardless of installed system fonts.
 */
import rocket from '@twemoji/svg/1f680.svg'
import check from '@twemoji/svg/2705.svg'
import fire from '@twemoji/svg/1f525.svg'
import bulb from '@twemoji/svg/1f4a1.svg'
import target from '@twemoji/svg/1f3af.svg'
import robot from '@twemoji/svg/1f916.svg'
import testTube from '@twemoji/svg/1f9ea.svg'
import bug from '@twemoji/svg/1f41b.svg'
import bolt from '@twemoji/svg/26a1.svg'
import trophy from '@twemoji/svg/1f3c6.svg'
import chart from '@twemoji/svg/1f4c8.svg'
import tools from '@twemoji/svg/1f6e0.svg'
import lock from '@twemoji/svg/1f512.svg'
import party from '@twemoji/svg/1f389.svg'
import eyes from '@twemoji/svg/1f440.svg'
import heart from '@twemoji/svg/2764.svg'
import star from '@twemoji/svg/2b50.svg'
import cloud from '@twemoji/svg/2601.svg'
import brain from '@twemoji/svg/1f9e0.svg'
import box from '@twemoji/svg/1f4e6.svg'
import stopwatch from '@twemoji/svg/23f1.svg'
import speech from '@twemoji/svg/1f4ac.svg'
import compass from '@twemoji/svg/1f9ed.svg'
import pizza from '@twemoji/svg/1f355.svg'

export const STICKERS = [
  '🚀',
  '✅',
  '🔥',
  '💡',
  '🎯',
  '🤖',
  '🧪',
  '🐛',
  '⚡',
  '🏆',
  '📈',
  '🛠️',
  '🔒',
  '🎉',
  '👀',
  '❤️',
  '⭐',
  '☁️',
  '🧠',
  '📦',
  '⏱️',
  '💬',
  '🧭',
  '🍕',
] as const

const ART = new Map<string, string>([
  ['🚀', rocket],
  ['✅', check],
  ['🔥', fire],
  ['💡', bulb],
  ['🎯', target],
  ['🤖', robot],
  ['🧪', testTube],
  ['🐛', bug],
  ['⚡', bolt],
  ['🏆', trophy],
  ['📈', chart],
  ['🛠️', tools],
  ['🔒', lock],
  ['🎉', party],
  ['👀', eyes],
  ['❤️', heart],
  ['⭐', star],
  ['☁️', cloud],
  ['🧠', brain],
  ['📦', box],
  ['⏱️', stopwatch],
  ['💬', speech],
  ['🧭', compass],
  ['🍕', pizza],
])

export function stickerArt(emoji: string): string | undefined {
  return ART.get(emoji)
}
