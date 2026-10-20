import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Merchant } from './types';

interface AuthState {
  token: string | null;
  merchant: Merchant | null;
  /** True once Zustand's persist middleware has finished rehydrating from localStorage. */
  hasHydrated: boolean;
  setAuth: (
    tokenOrMerchant: string | Merchant,
    maybeMerchant?: Merchant
  ) => void;
  logout: () => void;
  _setHasHydrated: (value: boolean) => void;
}

const LEGACY_TOKEN_KEY = 'access_token';

/** Remove any legacy access_token key written to localStorage (#484). */
export function clearLegacyAccessTokenKey() {
  if (typeof window !== 'undefined') {
    localStorage.removeItem(LEGACY_TOKEN_KEY);
  }
}

/**
 * Auth state is maintained in-memory and merchant profile is persisted via
 * Zustand (`dupdub-auth` key).
 *
 * SECURITY (#484): The JWT access token is stored in an httpOnly, Secure,
 * SameSite=Strict cookie managed by the browser and server. Tokens are NEVER
 * stored in localStorage or sessionStorage to protect against XSS token exfiltration.
 */
export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      merchant: null,
      hasHydrated: false,
      setAuth: (tokenOrMerchant, maybeMerchant) => {
        clearLegacyAccessTokenKey();
        const merchant =
          typeof tokenOrMerchant === 'string'
            ? (maybeMerchant ?? null)
            : tokenOrMerchant;
        // Tokens are never stored in client state or localStorage (#484)
        set({ token: null, merchant });
      },
      logout: () => {
        clearLegacyAccessTokenKey();
        set({ token: null, merchant: null });
      },
      _setHasHydrated: (value) => set({ hasHydrated: value }),
    }),
    {
      name: 'dupdub-auth',
      // Persist only merchant profile; never serialize tokens to localStorage (#484)
      partialize: (state) => ({ merchant: state.merchant }),
      onRehydrateStorage: () => (state) => {
        clearLegacyAccessTokenKey();
        // Mark hydration complete so the dashboard can stop showing its loading
        // spinner. `state` is undefined when there is no persisted data yet
        // (first-ever visit), so fall back to the store's own setter.
        if (state) {
          state.token = null;
          state._setHasHydrated(true);
        } else {
          useAuthStore.getState()._setHasHydrated(true);
        }
      },
    }
  )
);
