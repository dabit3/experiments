import type { Line } from '../shell/output'

export function OutputLines({ lines }: { lines: Line[] }) {
  return (
    <>
      {lines.map((line, i) => (
        <div className="line" key={i}>
          {line.length === 0 ? '\u00a0' : null}
          {line.map((s, j) =>
            s.style ? (
              <span className={`s-${s.style}`} key={j}>
                {s.text}
              </span>
            ) : (
              <span key={j}>{s.text}</span>
            ),
          )}
          {line.length === 1 && line[0].text === '' ? '\u00a0' : null}
        </div>
      ))}
    </>
  )
}
