/**
 * The content contract for gi-daily-app.
 *
 * This file is the single source of truth for the shape of everything under
 * `gi_daily_app/assets/content/`. The Flutter app mirrors these types in Dart
 * (`gi_daily_app/lib/content/models/`); the mirror is checked by
 * `validate-content.ts`, which both sides run against the same JSON.
 *
 * Three project constraints are encoded here as schema rules rather than as
 * conventions, so that violating them fails the build:
 *
 *   1. No patient data. Every image carries an open licence and an attribution
 *      string that the app is required to render.
 *   2. Guideline text is not redistributed. A recommendation may carry at most
 *      QUOTE_MAX_CHARS characters of quoted text, and must carry a citation.
 *   3. Nothing unreviewed reaches a user. A post is `draft` until a physician
 *      approves it; the app only ever renders `approved`.
 */

import { z } from 'zod';

/** Longest verbatim quote we take from a guideline. Constraint 2. */
export const QUOTE_MAX_CHARS = 400;

/** Number of answer options on every question. Fixed so the UI never reflows. */
export const OPTIONS_PER_QUESTION = 4;

// ---------------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------------

/** `YYYY-MM-DD`, the key a daily post is addressed by. */
export const isoDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'must be YYYY-MM-DD');

/** Full ISO-8601 instant, used for audit fields. */
export const isoInstant = z.string().datetime({ offset: true });

/**
 * Slug used for every id in the content set: lowercase, digits, dash, dot.
 * Dots are allowed because AWMF recommendation numbers carry them (`6.12`).
 */
export const slug = z
  .string()
  .min(3)
  .regex(/^[a-z0-9][a-z0-9.-]*$/, 'must be a lowercase slug');

/**
 * A string that exists in both languages.
 *
 * German is the product. English exists so that an English-speaking developer
 * can read what they are looking at while working, and is never shown unless
 * the app is running in the `en` debug locale.
 */
export const localizedText = (max: number) =>
  z.object({
    de: z.string().min(1).max(max),
    en: z.string().min(1).max(max),
  });

export type LocalizedText = z.infer<ReturnType<typeof localizedText>>;

// ---------------------------------------------------------------------------
// Licensing
// ---------------------------------------------------------------------------

/**
 * Datasets we are allowed to draw from. Both are open, de-identified and
 * CC BY 4.0. Adding a source here is a licensing decision, not a code change.
 */
export const datasetSource = z.enum([
  'hyperkvasir',
  'gastrovision',
  /**
   * Locally generated stand-in pixels. Exists so the app can be built and
   * demoed before a dataset is downloaded, without ever attributing a
   * synthetic image to a real author. Anything marked `placeholder` renders
   * with a visible badge and is reported by the validator.
   */
  'placeholder',
]);
export type DatasetSource = z.infer<typeof datasetSource>;

/**
 * Everything needed to render a correct attribution line under an image.
 * `attributionText` is what actually appears on screen, pre-composed so the
 * app never has to assemble a legal string itself.
 */
export const licence = z.object({
  /**
   * `PLACEHOLDER` is not a licence. It marks content that is standing in for
   * the real thing and must not be shown to anyone outside the team.
   */
  spdx: z.enum(['CC-BY-4.0', 'PLACEHOLDER']),
  holder: z.string().min(1),
  sourceUrl: z.string().url(),
  licenceUrl: z.string().url(),
  attributionText: z.string().min(1).max(300),
});
export type Licence = z.infer<typeof licence>;

// ---------------------------------------------------------------------------
// images.json
// ---------------------------------------------------------------------------

/**
 * An optional label produced by a classifier rather than by the dataset.
 *
 * Nothing in the app depends on this being present. It is the seam for
 * plugging in a trained model later: the pipeline can write predictions here,
 * the review UI can surface them next to the dataset label, and a physician
 * still decides. A prediction never overrides `className`.
 */
export const modelPrediction = z.object({
  modelId: slug,
  modelVersion: z.string().min(1),
  label: z.string().min(1),
  confidence: z.number().min(0).max(1),
  predictedAt: isoInstant,
});
export type ModelPrediction = z.infer<typeof modelPrediction>;

export const image = z.object({
  id: slug,
  source: datasetSource,
  /** Identifier inside the source dataset, so a claim can be traced back. */
  sourceId: z.string().min(1),
  /**
   * Canonical dataset class name, verbatim from the dataset's own folder
   * names. These are unintuitive on purpose (`normal-z-line`, `oesophagitis-a`)
   * and must never be retyped; see HYPERKVASIR_CLASSES in
   * scripts/build_image_bank.py.
   */
  className: z.string().min(1),
  /** Path relative to the Flutter asset root. */
  assetPath: z.string().regex(/^assets\/images\/[a-z0-9_-]+\.webp$/),
  width: z.number().int().positive(),
  height: z.number().int().positive(),
  licence,
  prediction: modelPrediction.optional(),
  addedAt: isoInstant,
});
export type Image = z.infer<typeof image>;

export const imageBank = z.object({
  version: z.literal(1),
  images: z.array(image),
});
export type ImageBank = z.infer<typeof imageBank>;

// ---------------------------------------------------------------------------
// guidelines.json
// ---------------------------------------------------------------------------

export const guideline = z.object({
  id: slug,
  /** AWMF register number, e.g. `021-007OL`. */
  awmfRegisterNumber: z.string().regex(/^\d{3}-\d{3}[A-Z]*$/),
  /** German title, as published. Not translated. */
  title: z.string().min(1),
  publisher: z.string().min(1),
  /** Guideline class, e.g. `S3`. */
  level: z.enum(['S1', 'S2e', 'S2k', 'S3']),
  version: z.string().min(1),
  publishedAt: isoDate,
  validUntil: isoDate.optional(),
  url: z.string().url(),
  /**
   * Standing note on what we may and may not do with this document. Rendered
   * in the app's citation sheet.
   */
  rightsNote: z.string().min(1).max(400),
});
export type Guideline = z.infer<typeof guideline>;

export const guidelines = z.object({
  version: z.literal(1),
  guidelines: z.array(guideline),
});
export type Guidelines = z.infer<typeof guidelines>;

// ---------------------------------------------------------------------------
// recommendations.json
// ---------------------------------------------------------------------------

/** Empfehlungsgrad. `EK` is an Expertenkonsens with no graded evidence. */
export const recommendationStrength = z.enum(['A', 'B', '0', 'EK']);

/** Konsensstärke as reported in the guideline. */
export const consensusStrength = z.enum([
  'starker Konsens',
  'Konsens',
  'mehrheitliche Zustimmung',
  'kein Konsens',
]);

export const recommendation = z.object({
  id: slug,
  guidelineId: slug,
  /** Recommendation number within the guideline, e.g. `6.12`. */
  number: z.string().regex(/^\d+(\.\d+)*$/),
  strength: recommendationStrength,
  consensus: consensusStrength.optional(),
  /** Level of evidence, verbatim, when the guideline states one. */
  levelOfEvidence: z.string().max(40).optional(),
  /**
   * Short verbatim quote. Capped at QUOTE_MAX_CHARS: we cite, we do not
   * redistribute. Constraint 2.
   */
  quote: z.string().min(1).max(QUOTE_MAX_CHARS),
  /** Full citation line, rendered wherever the quote is shown. */
  citation: z.string().min(1),
  page: z.number().int().positive().optional(),
  /** Deep link into the source document, when one exists. */
  url: z.string().url().optional(),
});
export type Recommendation = z.infer<typeof recommendation>;

export const recommendations = z.object({
  version: z.literal(1),
  recommendations: z.array(recommendation),
});
export type Recommendations = z.infer<typeof recommendations>;

// ---------------------------------------------------------------------------
// posts.json
// ---------------------------------------------------------------------------

/**
 * The three things we ask about an endoscopic image.
 *
 * `diagnosis`  — what is this?
 * `finding`    — what do we see endoscopically?
 * `treatment`  — what is the right strategy from here?
 */
export const questionType = z.enum(['diagnosis', 'finding', 'treatment']);
export type QuestionType = z.infer<typeof questionType>;

/**
 * Review state. Constraint 3: the app renders `approved` and nothing else.
 * `draft` is what a generator produces; `rejected` is kept rather than deleted
 * so that a bad generation stays visible to the team.
 */
export const reviewStatus = z.enum(['draft', 'approved', 'rejected']);
export type ReviewStatus = z.infer<typeof reviewStatus>;

export const answerOption = z.object({
  id: z.string().regex(/^[a-d]$/),
  text: localizedText(160),
  correct: z.boolean(),
});
export type AnswerOption = z.infer<typeof answerOption>;

/**
 * Provenance of a generated post. Present whenever a post was not written by
 * hand, so a reviewer always knows what produced what they are approving.
 */
export const provenance = z.object({
  generator: z.enum(['manual', 'llm', 'classifier-assisted']),
  modelId: z.string().min(1).optional(),
  promptVersion: z.string().min(1).optional(),
  generatedAt: isoInstant,
});
export type Provenance = z.infer<typeof provenance>;

export const review = z.object({
  status: reviewStatus,
  /** Physician who made the call. Free text; the team is five people. */
  reviewedBy: z.string().min(1).optional(),
  reviewedAt: isoInstant.optional(),
  note: z.string().max(1000).optional(),
});
export type Review = z.infer<typeof review>;

export const post = z
  .object({
    id: slug,
    /** The day this post is the post for. Unique across the set. */
    date: isoDate,
    /**
     * The images this case is about, in the order they are shown.
     *
     * Usually one. Several when a single lesion needs more than one view to be
     * answerable — white light, then NBI, then after dye. Capped at six: past
     * that it stops being one case.
     */
    imageIds: z.array(slug).min(1).max(6),
    recommendationId: slug,
    questionType,
    question: localizedText(240),
    options: z.array(answerOption).length(OPTIONS_PER_QUESTION),
    /**
     * Why the correct answer is correct, ending at the recommendation. This is
     * the payoff of the whole app, so it gets room: up to 900 characters.
     */
    explanation: localizedText(900),
    review,
    provenance,
  })
  .superRefine((value, ctx) => {
    const correct = value.options.filter((option) => option.correct);
    if (correct.length !== 1) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['options'],
        message: `exactly one option must be correct, found ${correct.length}`,
      });
    }

    const ids = value.options.map((option) => option.id);
    if (new Set(ids).size !== ids.length) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['options'],
        message: 'option ids must be unique',
      });
    }

    // An approved post must say who approved it and when. Constraint 3 is
    // worthless if approval can be anonymous.
    if (value.review.status === 'approved') {
      if (!value.review.reviewedBy || !value.review.reviewedAt) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['review'],
          message: 'approved posts require reviewedBy and reviewedAt',
        });
      }
    }
  });
export type Post = z.infer<typeof post>;

export const posts = z.object({
  version: z.literal(1),
  posts: z.array(post),
});
export type Posts = z.infer<typeof posts>;

// ---------------------------------------------------------------------------
// The content set as a whole
// ---------------------------------------------------------------------------

/**
 * The four files, loaded together. Referential integrity between them is
 * checked by `validate-content.ts` rather than here, because Zod validates one
 * document at a time and the interesting failures are cross-document ones:
 * a post pointing at an image that no longer exists, two posts claiming the
 * same day, an approved post citing a draft-only recommendation.
 */
export interface ContentSet {
  images: ImageBank;
  guidelines: Guidelines;
  recommendations: Recommendations;
  posts: Posts;
}

export const contentFiles = {
  images: 'images.json',
  guidelines: 'guidelines.json',
  recommendations: 'recommendations.json',
  posts: 'posts.json',
} as const;
