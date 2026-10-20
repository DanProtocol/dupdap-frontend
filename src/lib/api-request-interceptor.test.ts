import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import axios from 'axios';
import { useAuthStore } from './store';

vi.mock('axios', () => {
  const mockInstance = {
    interceptors: {
      request: { use: vi.fn() },
      response: { use: vi.fn() },
    },
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  };

  return {
    default: {
      create: vi.fn(() => mockInstance),
    },
  };
});

describe('Axios client and request configuration (#484)', () => {
  let requestInterceptor:
    | ((config: { headers: Record<string, string> }) => {
        headers: Record<string, string>;
      })
    | undefined;

  beforeAll(async () => {
    await import('./api');

    const instance = vi.mocked(axios.create).mock.results[0]?.value;
    requestInterceptor = vi.mocked(instance.interceptors.request.use).mock
      .calls[0]?.[0];
  });

  beforeEach(() => {
    localStorage.clear();
    useAuthStore.setState({ token: null, merchant: null });
  });

  it('configures axios with withCredentials: true for httpOnly cookie dispatch', () => {
    expect(axios.create).toHaveBeenCalledWith(
      expect.objectContaining({
        withCredentials: true,
      })
    );
  });

  it('omits manual Authorization header even when store or localStorage has a token (#484)', () => {
    useAuthStore.setState({ token: 'test-jwt-token', merchant: null });
    localStorage.setItem('access_token', 'legacy-token');

    const config = { headers: {} as Record<string, string> };
    const result = requestInterceptor?.(config);

    expect(result?.headers.Authorization).toBeUndefined();
  });

  it('preserves other headers already on the config', () => {
    const config = {
      headers: { 'Content-Type': 'application/json' } as Record<string, string>,
    };
    const result = requestInterceptor?.(config);

    expect(result?.headers['Content-Type']).toBe('application/json');
    expect(result?.headers.Authorization).toBeUndefined();
  });

  it('returns the config object intact', () => {
    const config = { headers: {} as Record<string, string> };
    const result = requestInterceptor?.(config);

    expect(result).toBeDefined();
    expect(result).toHaveProperty('headers');
  });
});
