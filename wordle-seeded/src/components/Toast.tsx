import type { Toast as ToastData } from '../hooks/useGame'
import './Toast.css'

export function Toast({ toast }: { toast: ToastData | null }) {
  return (
    <div className="toast-stack" aria-live="polite" aria-atomic="true">
      {toast && (
        <div key={toast.id} className={`toast toast--${toast.tone}`} role="status" data-testid="toast">
          {toast.message}
        </div>
      )}
    </div>
  )
}
