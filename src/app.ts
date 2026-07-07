import Fastify, { type FastifyInstance, type FastifyServerOptions } from 'fastify';

export function buildApp(opts: FastifyServerOptions = { logger: true }): FastifyInstance {
  const app = Fastify(opts);

  app.get('/health', async () => ({ status: 'ok' }));
  app.get('/ready', async () => ({ status: 'ready' }));

  return app;
}
