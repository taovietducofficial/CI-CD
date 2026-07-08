import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'json', 'json-summary'],
      include: ['src/**/*.ts'],
      // ponytail: server.ts is excluded because it starts a listener on import, so a
      // unit test would only be testing a mock. It is covered for real by the container
      // smoke test in .github/workflows/reusable-docker.yml, which boots the built image
      // and curls /health. Consequence: the thresholds below only measure app.ts.
      exclude: ['src/**/*.test.ts', 'src/server.ts'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
