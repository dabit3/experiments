export function ClockWidget({ now }: { now: Date }) {
  const hh = String(now.getHours()).padStart(2, '0')
  const mm = String(now.getMinutes()).padStart(2, '0')
  const ss = String(now.getSeconds()).padStart(2, '0')
  return (
    <section className="widget widget--clock" aria-label="Clock">
      <h2 className="widget__title">Current time</h2>
      <p className="clock" aria-live="off">
        <span className="clock__hm" data-testid="clock-hm">
          {hh}:{mm}
        </span>
        <span className="clock__ss">:{ss}</span>
      </p>
      <p className="widget__note">Rule 11 wants the HH:MM part exactly as shown.</p>
    </section>
  )
}
