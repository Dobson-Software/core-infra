import '@testing-library/jest-dom/vitest';
import { server } from './msw/server';

// Fix for Node.js 22+ built-in localStorage conflicting with jsdom.
// Node's built-in localStorage does not implement the Storage interface methods,
// so we provide a simple in-memory Storage implementation.
if (typeof localStorage !== 'undefined' && typeof localStorage.getItem !== 'function') {
  const store = new Map<string, string>();
  Object.defineProperty(globalThis, 'localStorage', {
    value: {
      getItem: (key: string) => store.get(key) ?? null,
      setItem: (key: string, value: string) => store.set(key, String(value)),
      removeItem: (key: string) => store.delete(key),
      clear: () => store.clear(),
      get length() {
        return store.size;
      },
      key: (index: number) => [...store.keys()][index] ?? null,
    },
    writable: true,
    configurable: true,
  });
}

beforeAll(() => server.listen());
afterEach(() => {
  server.resetHandlers();
  localStorage.clear();
});
afterAll(() => server.close());
