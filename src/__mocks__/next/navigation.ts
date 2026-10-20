import { vi } from 'vitest';

export const useRouter = vi.fn(() => ({
  push: vi.fn(),
  replace: vi.fn(),
  prefetch: vi.fn(),
  back: vi.fn(),
  forward: vi.fn(),
  refresh: vi.fn(),
}));

export const usePathname = vi.fn(() => '/dashboard');
export const useSearchParams = vi.fn(() => new URLSearchParams());
export const redirect = vi.fn();

/** Default export mirrors Next.js' navigation module shape for mocks. */
const navigationMock = { useRouter, usePathname, useSearchParams, redirect };

export default navigationMock;
