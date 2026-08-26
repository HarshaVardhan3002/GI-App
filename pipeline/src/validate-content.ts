/**
 * The gate.
 *
 * Nothing ships unless this passes. It checks four things, in order of how
 * badly each one would embarrass us:
 *
 *   1. Schema — every file matches `lib/schema.ts`.
 *   2. Referential integrity — no post points at an image, recommendation or
 *      guideline that does not exist; no two posts claim the same day.
 *   3. Licensing — every image an approved post uses carries a licence and a
 *      renderable attribution, and every quote is inside the length cap.
 *   4. Review — the app only reads `approved`, so the approved set must be
 *      self-consistent and attributable.
 *
 * Exit code is 1 on any error. Warnings do not fail the build but are printed,
 * because a hackathon prototype with zero approved posts is a working build
 * that demos nothing.
 *
 *   npm run validate            # validates the app's asset content
 *   npm run validate -- <dir>   # validates some other content directory
 */

import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

import { z } from 'zod';

import {
  QUOTE_MAX_CHARS,
  contentFiles,
  guidelines as guidelinesSchema,
  imageBank as imageBankSchema,
  posts as postsSchema,
  recommendations as recommendationsSchema,
  type ContentSet,
} from './lib/schema.js';

const here = dirname(fileURLToPath(import.meta.url));

/** Where the Flutter app reads its content from. */
const DEFAULT_CONTENT_DIR = resolve(
  here,
  '../../gi_daily_app/assets/content',
);

/** Where the images those files point at actually live. */
const ASSET_ROOT = resolve(here, '../../gi_daily_app');

interface Problem {
  file: string;
  path: string;
  message: string;
}

const errors: Problem[] = [];
const warnings: Problem[] = [];

function fail(file: string, path: string, message: string): void {
  errors.push({ file, path, message });
}

function warn(file: string, path: string, message: string): void {
  warnings.push({ file, path, message });
}

/** Reads and schema-checks one file, or records why it could not. */
function load<T>(dir: string, file: string, schema: z.ZodType<T>): T | null {
  const full = join(dir, file);

  if (!existsSync(full)) {
    fail(file, '', 'file not found');
    return null;
  }

  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(full, 'utf8'));
  } catch (error) {
    fail(file, '', `not valid JSON: ${(error as Error).message}`);
    return null;
  }

  const result = schema.safeParse(raw);
  if (!result.success) {
    for (const issue of result.error.issues) {
      fail(file, issue.path.join('.'), issue.message);
    }
    return null;
  }

  return result.data;
}

/** 2. Referential integrity, plus the one-post-per-day rule. */
function checkReferences(content: ContentSet): void {
  const imageIds = new Set(content.images.images.map((image) => image.id));
  const guidelineIds = new Set(
    content.guidelines.guidelines.map((guideline) => guideline.id),
  );
  const recommendationById = new Map(
    content.recommendations.recommendations.map((rec) => [rec.id, rec]),
  );

  for (const rec of content.recommendations.recommendations) {
    if (!guidelineIds.has(rec.guidelineId)) {
      fail(
        contentFiles.recommendations,
        rec.id,
        `guidelineId '${rec.guidelineId}' does not exist`,
      );
    }
  }

  const seenDates = new Map<string, string>();
  const seenIds = new Set<string>();

  for (const post of content.posts.posts) {
    if (seenIds.has(post.id)) {
      fail(contentFiles.posts, post.id, 'duplicate post id');
    }
    seenIds.add(post.id);

    for (const imageId of post.imageIds) {
      if (!imageIds.has(imageId)) {
        fail(
          contentFiles.posts,
          post.id,
          `imageId '${imageId}' does not exist`,
        );
      }
    }

    if (new Set(post.imageIds).size !== post.imageIds.length) {
      fail(contentFiles.posts, post.id, 'imageIds contains duplicates');
    }

    if (!recommendationById.has(post.recommendationId)) {
      fail(
        contentFiles.posts,
        post.id,
        `recommendationId '${post.recommendationId}' does not exist`,
      );
    }

    // One post per day is the whole product. Two posts on one date means the
    // app has to pick, and whatever it picks is arbitrary.
    if (post.review.status === 'approved') {
      const claimed = seenDates.get(post.date);
      if (claimed) {
        fail(
          contentFiles.posts,
          post.id,
          `date ${post.date} already claimed by approved post '${claimed}'`,
        );
      } else {
        seenDates.set(post.date, post.id);
      }
    }
  }
}

/** 3. Licensing and attribution. Constraints 1 and 2. */
function checkLicensing(content: ContentSet): void {
  for (const image of content.images.images) {
    const file = join(ASSET_ROOT, image.assetPath);
    if (!existsSync(file)) {
      fail(
        contentFiles.images,
        image.id,
        `assetPath '${image.assetPath}' has no file on disk`,
      );
    }

    if (!image.licence.attributionText.includes(image.licence.holder)) {
      warn(
        contentFiles.images,
        image.id,
        'attributionText does not name the licence holder',
      );
    }

    // Placeholders exist so the app builds before a dataset does. They must
    // never be quiet about it.
    if (image.licence.spdx === 'PLACEHOLDER') {
      warn(
        contentFiles.images,
        image.id,
        'PLACEHOLDER image — stand-in pixels, not for any audience outside the team',
      );
    }
  }

  // The cap is enforced by the schema; this catches quotes that sit suspiciously
  // close to it, which in practice means someone pasted a paragraph and trimmed.
  for (const rec of content.recommendations.recommendations) {
    if (rec.quote.length > QUOTE_MAX_CHARS * 0.95) {
      warn(
        contentFiles.recommendations,
        rec.id,
        `quote is ${rec.quote.length}/${QUOTE_MAX_CHARS} chars — check it is a citation, not an excerpt`,
      );
    }
  }
}

/** 4. Review state. Constraint 3. */
function checkReview(content: ContentSet): void {
  const approved = content.posts.posts.filter(
    (post) => post.review.status === 'approved',
  );

  if (approved.length === 0) {
    warn(
      contentFiles.posts,
      '',
      'no approved posts — the app will render its empty state',
    );
  }

  for (const post of approved) {
    // A post whose German is missing is not approvable: German is the product.
    if (post.question.de.trim() === post.question.en.trim()) {
      warn(
        contentFiles.posts,
        post.id,
        'German and English question are identical — likely untranslated',
      );
    }
  }
}

function main(): void {
  const dir = resolve(process.argv[2] ?? DEFAULT_CONTENT_DIR);
  process.stdout.write(`Validating content in ${dir}\n\n`);

  const images = load(dir, contentFiles.images, imageBankSchema);
  const guidelines = load(dir, contentFiles.guidelines, guidelinesSchema);
  const recommendations = load(
    dir,
    contentFiles.recommendations,
    recommendationsSchema,
  );
  const postsFile = load(dir, contentFiles.posts, postsSchema);

  // Cross-document checks only make sense once every document parsed.
  if (images && guidelines && recommendations && postsFile) {
    const content: ContentSet = {
      images,
      guidelines,
      recommendations,
      posts: postsFile,
    };
    checkReferences(content);
    checkLicensing(content);
    checkReview(content);

    process.stdout.write(
      `  ${content.images.images.length} images, ` +
        `${content.guidelines.guidelines.length} guidelines, ` +
        `${content.recommendations.recommendations.length} recommendations, ` +
        `${content.posts.posts.length} posts ` +
        `(${
          content.posts.posts.filter((p) => p.review.status === 'approved')
            .length
        } approved)\n\n`,
    );
  }

  for (const warning of warnings) {
    process.stdout.write(
      `  warn  ${warning.file}${warning.path ? ` [${warning.path}]` : ''}: ${warning.message}\n`,
    );
  }

  for (const error of errors) {
    process.stdout.write(
      `  ERROR ${error.file}${error.path ? ` [${error.path}]` : ''}: ${error.message}\n`,
    );
  }

  if (errors.length > 0) {
    process.stdout.write(`\nFAILED: ${errors.length} error(s)\n`);
    process.exit(1);
  }

  process.stdout.write(
    `\nOK${warnings.length > 0 ? ` (${warnings.length} warning(s))` : ''}\n`,
  );
}

main();
