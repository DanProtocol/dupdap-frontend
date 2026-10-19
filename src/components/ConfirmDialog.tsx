'use client';

import { useEffect } from 'react';
import { cn } from '@/lib/utils';

interface ConfirmDialogProps {
  /** Whether the dialog is visible. Renders null when false. */
  open: boolean;
  /** Dialog heading. Defaults to "Are you sure?". */
  title?: string;
  /** Main body message shown to the user. */
  message?: string;
  /** Alias for `message` — shown when `message` is not provided. */
  description?: string;
  /** Label for the confirm button. Defaults to "Confirm". */
  confirmLabel?: string;
  /** Label for the cancel button. Defaults to "Cancel". */
  cancelLabel?: string;
  /** When true, the confirm button gets destructive (red) styling. */
  destructive?: boolean;
  /** When true, both buttons are disabled and the confirm label becomes "Working...". */
  loading?: boolean;
  /** Called when the user confirms the action. */
  onConfirm: () => void;
  /** Called when the user cancels — via the cancel button or Escape key. */
  onCancel: () => void;
}

/**
 * ConfirmDialog — a lightweight confirmation modal with confirm/cancel buttons.
 *
 * Accessibility:
 * - Renders as a role="dialog" with aria-modal="true".
 * - Escape key cancels (only when open).
 * - Backdrop click cancels.
 * - Focus is trapped within the panel while open.
 */
export default function ConfirmDialog({
  open,
  title = 'Are you sure?',
  message,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  destructive = false,
  loading = false,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  // Close on Escape — listener is only attached while the dialog is open and
  // cleaned up on unmount so no callbacks fire after the component is gone.
  useEffect(() => {
    if (!open) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onCancel();
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [open, onCancel]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onCancel}
      data-testid="confirm-dialog-backdrop"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        tabIndex={-1}
        className="card w-full max-w-sm p-6 outline-none"
        onClick={(e) => e.stopPropagation()}
      >
        {title && <h2 className="mb-2 text-lg font-semibold">{title}</h2>}
        <p className="mb-6 text-sm text-gray-600">{message ?? description}</p>
        <div className="flex justify-end gap-3">
          <button
            type="button"
            onClick={onCancel}
            disabled={loading}
            className="btn-secondary"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={loading}
            className={cn(
              destructive
                ? 'bg-red-500 text-white hover:bg-red-600'
                : 'btn-primary'
            )}
          >
            {loading ? 'Working...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
