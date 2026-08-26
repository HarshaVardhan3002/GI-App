/**
 * The review step, as a local web page.
 *
 *   npm run review          # then open http://localhost:4173
 *
 * A physician reads each draft next to the image it is about, and approves or
 * rejects it. Approving writes `reviewedBy` and `reviewedAt` into posts.json;
 * the app reads that file and shows approved posts only. This is where
 * constraint 3 actually happens — everything else in the pipeline just keeps
 * the drafts tidy until someone gets here.
 *
 * Deliberately a local, unauthenticated server bound to localhost. It edits a
 * file in the working tree, so the audit trail is git, and the access control is
 * that you have to be on the machine. Do not expose it.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';
import { dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { posts as postsSchema, type Post } from './lib/schema.js';

const here = dirname(fileURLToPath(import.meta.url));
const APP_ROOT = resolve(here, '../../gi_daily_app');
const CONTENT_DIR = join(APP_ROOT, 'assets/content');
const POSTS_FILE = join(CONTENT_DIR, 'posts.json');

const PORT = 4173;

function readPosts(): Post[] {
  const parsed = postsSchema.parse(
    JSON.parse(readFileSync(POSTS_FILE, 'utf8')),
  );
  return parsed.posts;
}

function writePosts(posts: Post[]): void {
  // Re-validate before writing. A review action must not be able to produce a
  // file the app cannot read.
  const validated = postsSchema.parse({ version: 1, posts });
  writeFileSync(POSTS_FILE, `${JSON.stringify(validated, null, 2)}\n`, 'utf8');
}

function json(response: ServerResponse, status: number, body: unknown): void {
  const payload = JSON.stringify(body);
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(payload),
  });
  response.end(payload);
}

async function readBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) chunks.push(chunk as Buffer);
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

/** Content the page needs: the drafts, plus what each one points at. */
function reviewPayload(): unknown {
  const images = JSON.parse(
    readFileSync(join(CONTENT_DIR, 'images.json'), 'utf8'),
  ) as { images: Array<Record<string, unknown>> };
  const recommendations = JSON.parse(
    readFileSync(join(CONTENT_DIR, 'recommendations.json'), 'utf8'),
  ) as { recommendations: Array<Record<string, unknown>> };

  return {
    posts: readPosts(),
    images: images.images,
    recommendations: recommendations.recommendations,
  };
}

const MIME: Record<string, string> = {
  '.webp': 'image/webp',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
};

const server = createServer((request, response) => {
  const url = new URL(request.url ?? '/', `http://localhost:${PORT}`);

  if (request.method === 'GET' && url.pathname === '/') {
    const html = readFileSync(join(here, 'review.html'), 'utf8');
    response.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    response.end(html);
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/content') {
    try {
      json(response, 200, reviewPayload());
    } catch (error) {
      json(response, 500, { error: (error as Error).message });
    }
    return;
  }

  // Serves the images the drafts are about, straight out of the app's assets.
  if (request.method === 'GET' && url.pathname.startsWith('/assets/')) {
    const file = join(APP_ROOT, url.pathname);
    if (!file.startsWith(APP_ROOT)) {
      json(response, 400, { error: 'bad path' });
      return;
    }
    try {
      const body = readFileSync(file);
      response.writeHead(200, {
        'content-type': MIME[extname(file)] ?? 'application/octet-stream',
      });
      response.end(body);
    } catch {
      json(response, 404, { error: 'not found' });
    }
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/review') {
    void (async () => {
      try {
        const body = (await readBody(request)) as {
          id: string;
          status: 'approved' | 'rejected' | 'draft';
          reviewedBy: string;
          note?: string;
        };

        if (body.status === 'approved' && !body.reviewedBy?.trim()) {
          json(response, 400, {
            error: 'approval needs a name — an anonymous approval is not one',
          });
          return;
        }

        const posts = readPosts();
        const index = posts.findIndex((post) => post.id === body.id);
        if (index === -1) {
          json(response, 404, { error: `no post '${body.id}'` });
          return;
        }

        const current = posts[index]!;
        posts[index] = {
          ...current,
          review: {
            status: body.status,
            ...(body.status === 'draft'
              ? {}
              : {
                  reviewedBy: body.reviewedBy.trim(),
                  reviewedAt: new Date().toISOString(),
                }),
            ...(body.note?.trim() ? { note: body.note.trim() } : {}),
          },
        };

        writePosts(posts);
        json(response, 200, { ok: true, post: posts[index] });
      } catch (error) {
        json(response, 400, { error: (error as Error).message });
      }
    })();
    return;
  }

  json(response, 404, { error: 'not found' });
});

server.listen(PORT, '127.0.0.1', () => {
  process.stdout.write(`Review UI on http://localhost:${PORT}\n`);
  process.stdout.write(`Editing ${POSTS_FILE}\n`);
});
