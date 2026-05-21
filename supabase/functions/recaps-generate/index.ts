type ErrorCode =
  | "INVALID_REQUEST"
  | "UNAUTHORIZED"
  | "RATE_LIMIT_REACHED"
  | "AI_PROVIDER_ERROR"
  | "INTERNAL_ERROR";

type RecapMemory = {
  entry_id: string;
  created_at: string;
  scene_labels: string[];
  mood: string;
  note?: string | null;
  ai_narrative?: string | null;
};

type RecapRequest = {
  recap_id: string;
  entry_ids: string[];
  memories: RecapMemory[];
  locale: string;
};

const jsonHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const allowedKeys = new Set([
  "recap_id",
  "entry_ids",
  "memories",
  "locale",
]);

const allowedMemoryKeys = new Set([
  "entry_id",
  "created_at",
  "scene_labels",
  "mood",
  "note",
  "ai_narrative",
]);

const forbiddenKeyFragments = [
  "photo",
  "thumbnail",
  "medium",
  "preview",
  "exif",
  "gps",
  "voice",
  "image",
  "blob",
  "path",
  "file",
];

const forbiddenValueFragments = [
  "file://",
  "/documents/",
  "/originals/",
  "/thumbnails/",
  "/medium/",
  "/voice/",
  "/var/mobile/",
  ".heic",
  ".heif",
  ".jpg",
  ".jpeg",
  ".png",
  ".m4a",
  ".wav",
];

const rateLimitWindowMs = 60 * 60 * 1000;
const rateLimitMax = Number(Deno.env.get("AI_RATE_LIMIT_PER_HOUR") ?? "20");
const rateLimitStore = new Map<string, { count: number; resetAt: number }>();

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { headers: jsonHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("INVALID_REQUEST", "This request could not be used.", 405);
  }

  if (!isAuthorized(request)) {
    return errorResponse("UNAUTHORIZED", "Please try again after signing in.", 401);
  }

  if (isRateLimitDisabled()) {
    console.log("[MemoryInk][AI] rate limit disabled for this environment");
  } else if (!consumeRateLimit(request)) {
    return errorResponse("RATE_LIMIT_REACHED", "You've reached today's AI limit.", 429);
  }

  try {
    const body = await request.json();
    const validation = validateRecapRequest(body);
    if (!validation.valid) {
      return errorResponse("INVALID_REQUEST", "This recap could not be prepared.", 400);
    }

    const openAIKey = Deno.env.get("OPENAI_API_KEY");
    console.log(`[MemoryInk][AI] OPENAI_API_KEY exists: ${Boolean(openAIKey)}`);
    if (!openAIKey) {
      return errorResponse("INTERNAL_ERROR", "Recap will appear shortly.", 500);
    }

    const model = Deno.env.get("AI_MODEL") ?? "gpt-4o-mini";
    console.log(`[MemoryInk][AI] AI_MODEL: ${model}`);
    console.log("[MemoryInk][AI] recap generation started");

    const recap = await generateRecap(validation.value, openAIKey, model);
    console.log("[MemoryInk][AI] recap generation succeeded");

    return jsonResponse({
      success: true,
      data: {
        recap,
        generated_at: new Date().toISOString(),
        model,
        cached: false,
      },
    });
  } catch (_error) {
    console.log("[MemoryInk][AI] recap generation failed");
    return errorResponse("AI_PROVIDER_ERROR", "Couldn't generate a recap right now.", 502);
  }
});

async function generateRecap(
  body: RecapRequest,
  openAIKey: string,
  model: string,
): Promise<string> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${openAIKey}`,
    },
    body: JSON.stringify({
      model,
      instructions:
        "Write a warm, plain, grounded recap in exactly 2 short sentences, 35-60 words total. Use only date, note, mood, and ai_narrative. Do not use details only inferred from scene_labels. Do not invent new details, lessons, meanings, weather, people, places, settings, or conversations. Do not add first person unless notes use first person. Avoid report-like phrases: \"there was\", \"took place\", \"characterized as\", and \"described as\". Keep it natural, not poetic or therapy-like.",
      input: JSON.stringify({
        memories: body.memories.map((memory) => ({
          created_at: memory.created_at,
          scene_labels: memory.scene_labels,
          mood: memory.mood,
          note: memory.note ?? "",
          ai_narrative: memory.ai_narrative ?? "",
        })),
        locale: body.locale,
      }),
      temperature: 0.2,
      max_output_tokens: 120,
    }),
  });

  console.log(`[MemoryInk][AI] OpenAI response status: ${response.status}`);
  const data = await response.json().catch(() => null);

  if (!response.ok) {
    logOpenAIError(data);
    throw new Error("AI provider request failed");
  }

  logOpenAIResponseShape(data);

  const content = extractGeneratedText(data);
  if (typeof content !== "string" || content.trim().length === 0) {
    throw new Error("AI provider returned an empty recap");
  }

  return content.trim();
}

function extractGeneratedText(data: unknown): string | null {
  if (!isPlainObject(data)) {
    return null;
  }

  if (typeof data.output_text === "string") {
    return data.output_text;
  }

  if (!Array.isArray(data.output)) {
    return null;
  }

  const textParts: string[] = [];
  for (const outputItem of data.output) {
    if (!isPlainObject(outputItem) || !Array.isArray(outputItem.content)) {
      continue;
    }

    for (const contentItem of outputItem.content) {
      if (isPlainObject(contentItem) && typeof contentItem.text === "string") {
        textParts.push(contentItem.text);
      }
    }
  }

  return textParts.join("\n").trim() || null;
}

function logOpenAIError(data: unknown) {
  const error = isPlainObject(data) && isPlainObject(data.error) ? data.error : null;
  const code = typeof error?.code === "string" ? error.code : "unknown";
  const message = typeof error?.message === "string" ? error.message : "No message returned";
  console.log(`[MemoryInk][AI] OpenAI error code: ${code}`);
  console.log(`[MemoryInk][AI] OpenAI error message: ${message}`);
}

function logOpenAIResponseShape(data: unknown) {
  if (!isPlainObject(data)) {
    console.log("[MemoryInk][AI] OpenAI response shape: non_object");
    return;
  }

  const output = Array.isArray(data.output) ? data.output : [];
  const firstOutput = isPlainObject(output[0]) ? output[0] : null;
  const firstContent = firstOutput && Array.isArray(firstOutput.content) ? firstOutput.content : [];
  const contentTypes = firstContent
    .filter(isPlainObject)
    .map((item) => typeof item.type === "string" ? item.type : "unknown")
    .join(",");

  console.log(
    `[MemoryInk][AI] OpenAI response shape: has_output_text=${typeof data.output_text === "string"}, output_count=${output.length}, first_content_types=${contentTypes}`,
  );
}

function validateRecapRequest(body: unknown): { valid: true; value: RecapRequest } | { valid: false } {
  if (!isPlainObject(body) || containsForbiddenPayload(body)) {
    return { valid: false };
  }

  const keys = Object.keys(body);
  if (keys.some((key) => !allowedKeys.has(key))) {
    return { valid: false };
  }

  const value = body as Record<string, unknown>;
  if (
    typeof value.recap_id !== "string" ||
    !Array.isArray(value.entry_ids) ||
    !value.entry_ids.every((id) => typeof id === "string") ||
    !Array.isArray(value.memories) ||
    typeof value.locale !== "string"
  ) {
    return { valid: false };
  }

  const memoriesAreValid = value.memories.every((memory) => {
    if (!isPlainObject(memory)) {
      return false;
    }

    if (Object.keys(memory).some((key) => !allowedMemoryKeys.has(key))) {
      return false;
    }

    return typeof memory.entry_id === "string" &&
      typeof memory.created_at === "string" &&
      Array.isArray(memory.scene_labels) &&
      memory.scene_labels.every((label) => typeof label === "string") &&
      typeof memory.mood === "string" &&
      (memory.note == null || typeof memory.note === "string") &&
      (memory.ai_narrative == null || typeof memory.ai_narrative === "string");
  });

  if (!memoriesAreValid) {
    return { valid: false };
  }

  return { valid: true, value: value as RecapRequest };
}

function isAuthorized(request: Request): boolean {
  const expected = Deno.env.get("MEMORYINK_AI_API_KEY");
  if (!expected) {
    return true;
  }

  const header = request.headers.get("Authorization") ?? "";
  return header === `Bearer ${expected}`;
}

function consumeRateLimit(request: Request): boolean {
  console.log(`[MemoryInk][AI] rateLimitMax: ${rateLimitMax}`);
  const forwardedFor = request.headers.get("x-forwarded-for") ?? "anonymous";
  const key = forwardedFor.split(",")[0]?.trim() || "anonymous";
  const now = Date.now();
  const existing = rateLimitStore.get(key);

  if (!existing || existing.resetAt <= now) {
    rateLimitStore.set(key, { count: 1, resetAt: now + rateLimitWindowMs });
    console.log("[MemoryInk][AI] rate limit consumed");
    return true;
  }

  if (existing.count >= rateLimitMax) {
    console.log("[MemoryInk][AI] rate limit reached");
    return false;
  }

  existing.count += 1;
  console.log("[MemoryInk][AI] rate limit consumed");
  return true;
}

function isRateLimitDisabled(): boolean {
  return Deno.env.get("AI_RATE_LIMIT_DISABLED") === "true";
}

function containsForbiddenPayload(value: unknown): boolean {
  if (Array.isArray(value)) {
    return value.some(containsForbiddenPayload);
  }

  if (isPlainObject(value)) {
    return Object.entries(value).some(([key, nestedValue]) => {
      const normalizedKey = key.toLowerCase();
      return forbiddenKeyFragments.some((fragment) => normalizedKey.includes(fragment)) ||
        containsForbiddenPayload(nestedValue);
    });
  }

  if (typeof value === "string") {
    const normalizedValue = value.toLowerCase();
    return forbiddenValueFragments.some((fragment) => normalizedValue.includes(fragment));
  }

  return false;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function errorResponse(code: ErrorCode, message: string, status: number): Response {
  return jsonResponse({
    success: false,
    error: {
      code,
      message,
    },
  }, status);
}
