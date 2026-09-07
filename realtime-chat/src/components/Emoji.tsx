import thumbsUp from '../assets/emoji/1f44d.svg'
import heart from '../assets/emoji/2764.svg'
import joy from '../assets/emoji/1f602.svg'
import tada from '../assets/emoji/1f389.svg'
import rocket from '../assets/emoji/1f680.svg'
import eyes from '../assets/emoji/1f440.svg'

/** Twemoji artwork (CC-BY 4.0) so reactions render identically on every platform. */
const ART: Record<string, string> = {
  '👍': thumbsUp,
  '❤️': heart,
  '😂': joy,
  '🎉': tada,
  '🚀': rocket,
  '👀': eyes,
}

interface EmojiProps {
  emoji: string
  size?: number
}

export function Emoji({ emoji, size = 18 }: EmojiProps) {
  const src = ART[emoji]
  if (!src) return <span style={{ fontSize: size }}>{emoji}</span>
  return <img className="emoji" src={src} alt={emoji} width={size} height={size} draggable={false} />
}
