/**
 * Pairs an image with a recommendation and writes a draft post.
 *
 *   npx tsx src/generate-posts.ts --date 2026-09-17 \
 *       --image hyperkvasir-polyp-001 \
 *       --recommendation dgvs-s3-krk-r-6.12 \
 *       --type treatment
 *
 * Everything this writes is a `draft`. The app never reads drafts, so nothing
 * produced here can reach a user until a physician has approved it — that is
 * constraint 3, and it is the reason this script is allowed to be as crude or
 * as clever as we like.
 *
 * The generator itself is behind an interface. Today the only implementation is
 * `templateGenerator`, which produces a correctly shaped post with the clinical
 * content left blank for a person to write. When a model is trained, it
 * implements `PostGenerator` and is selected with `--generator`; nothing else in
 * the pipeline changes, and the output still lands as a draft.
 */

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { fileURLToPath } from 'node:url';

import {
  OPTIONS_PER_QUESTION,
  imageBank as imageBankSchema,
  post as postSchema,
  posts as postsSchema,
  recommendations as recommendationsSchema,
  type Image,
  type Post,
  type QuestionType,
  type Recommendation,
} from './lib/schema.js';

const here = dirname(fileURLToPath(import.meta.url));
const CONTENT_DIR = resolve(here, '../../gi_daily_app/assets/content');

/**
 * What any post source has to provide.
 *
 * A model plugs in here. It gets the image (including the dataset class name,
 * and a classifier's prediction when one has been written) and the
 * recommendation the answer must trace back to, and returns the clinical
 * content. It does not get to decide the date, the ids, or the review status.
 */
export interface PostGenerator {
  readonly name: string;
  readonly modelId?: string;
  readonly promptVersion?: string;

  generate(input: {
    image: Image;
    recommendation: Recommendation;
    questionType: QuestionType;
  }): Promise<GeneratedContent>;
}

export interface GeneratedContent {
  question: { de: string; en: string };
  options: Array<{
    id: string;
    text: { de: string; en: string };
    correct: boolean;
  }>;
  explanation: { de: string; en: string };
}

/**
 * Writes a correctly shaped post with the clinical content stubbed.
 *
 * This is not a placeholder for a model that will do the thinking. Somebody has
 * to write four plausible answers at Facharzt level, and a physician has to
 * approve them; what this removes is the shape, the ids and the wiring, which
 * are the parts a person should not be retyping.
 */
const templateGenerator: PostGenerator = {
  name: 'manual',

  async generate({ image, recommendation, questionType }) {
    const stem = {
      diagnosis: {
        de: `TODO Frage zur Diagnose. Bilddatensatzklasse: ${image.className}.`,
        en: `TODO diagnosis question. Dataset class: ${image.className}.`,
      },
      finding: {
        de: `TODO Frage zum endoskopischen Befund. Bilddatensatzklasse: ${image.className}.`,
        en: `TODO endoscopic finding question. Dataset class: ${image.className}.`,
      },
      treatment: {
        de: `TODO Frage zur Therapiestrategie. Bilddatensatzklasse: ${image.className}.`,
        en: `TODO treatment strategy question. Dataset class: ${image.className}.`,
      },
    }[questionType];

    const keys = ['a', 'b', 'c', 'd'].slice(0, OPTIONS_PER_QUESTION);

    return {
      question: stem,
      options: keys.map((id, index) => ({
        id,
        text: {
          de: `TODO Antwortoption ${id.toUpperCase()}`,
          en: `TODO answer option ${id.toUpperCase()}`,
        },
        // The first option is marked correct only so the draft satisfies the
        // exactly-one-correct rule and can be round-tripped through the schema.
        correct: index === 0,
      })),
      explanation: {
        de:
          `TODO Begründung, die auf Empfehlung ${recommendation.number} ` +
          `zurückführt.`,
        en:
          `TODO reasoning that traces back to recommendation ` +
          `${recommendation.number}.`,
      },
    };
  },
};

const generators: Record<string, PostGenerator> = {
  manual: templateGenerator,
};

function readJson<T>(file: string, schema: { parse: (value: unknown) => T }): T {
  const path = resolve(CONTENT_DIR, file);
  if (!existsSync(path)) {
    throw new Error(`missing content file: ${path}`);
  }
  return schema.parse(JSON.parse(readFileSync(path, 'utf8')));
}

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      date: { type: 'string' },
      image: { type: 'string' },
      recommendation: { type: 'string' },
      type: { type: 'string' },
      generator: { type: 'string', default: 'manual' },
    },
  });

  const missing = (['date', 'image', 'recommendation', 'type'] as const).filter(
    (key) => !values[key],
  );
  if (missing.length > 0) {
    throw new Error(`missing required argument(s): --${missing.join(', --')}`);
  }

  const generator = generators[values.generator!];
  if (!generator) {
    throw new Error(
      `unknown generator '${values.generator}'. Available: ${Object.keys(generators).join(', ')}`,
    );
  }

  const images = readJson('images.json', imageBankSchema);
  const recommendations = readJson(
    'recommendations.json',
    recommendationsSchema,
  );
  const existing = readJson('posts.json', postsSchema);

  const image = images.images.find((entry) => entry.id === values.image);
  if (!image) throw new Error(`no image with id '${values.image}'`);

  const recommendation = recommendations.recommendations.find(
    (entry) => entry.id === values.recommendation,
  );
  if (!recommendation) {
    throw new Error(`no recommendation with id '${values.recommendation}'`);
  }

  const questionType = values.type as QuestionType;
  const id = `post-${values.date}`;

  if (existing.posts.some((entry) => entry.id === id)) {
    throw new Error(
      `post '${id}' already exists — edit it, or pick another date`,
    );
  }

  const content = await generator.generate({
    image,
    recommendation,
    questionType,
  });

  const draft: Post = postSchema.parse({
    id,
    date: values.date,
    imageIds: [image.id],
    recommendationId: recommendation.id,
    questionType,
    ...content,
    review: { status: 'draft' },
    provenance: {
      generator: generator.name,
      ...(generator.modelId ? { modelId: generator.modelId } : {}),
      ...(generator.promptVersion
        ? { promptVersion: generator.promptVersion }
        : {}),
      generatedAt: new Date().toISOString(),
    },
  });

  const merged = postsSchema.parse({
    version: 1,
    posts: [...existing.posts, draft].sort((a, b) =>
      a.date.localeCompare(b.date),
    ),
  });

  const out = resolve(CONTENT_DIR, 'posts.json');
  writeFileSync(out, `${JSON.stringify(merged, null, 2)}\n`, 'utf8');

  process.stdout.write(`Wrote draft '${id}' using generator '${generator.name}'\n`);
  process.stdout.write(`  -> ${out}\n`);
  process.stdout.write(
    'Status is draft. It will not appear in the app until a physician approves it.\n',
  );
}

main().catch((error: unknown) => {
  process.stderr.write(`${(error as Error).message}\n`);
  process.exit(1);
});
