import { Hono } from 'hono'

const app = new Hono()

app.get('/api/health', (c) => c.json({ status: 'ok' }))

app.get('/', (c) => c.text('Hello from Bun + Hono'))

export default app
