# classcare_user

ClassCare User application (Flutter) with AI-assisted incident moderation and triage.

## Overview

This workspace contains:

1. Flutter client app for end users to submit incident reports.
2. AI moderation endpoint in `index.ts` used to:
	- analyze report content,
	- detect spam or low-signal submissions,
	- compute urgency and severity,
	- decide whether to accept, flag, or auto-close reports.

## Main Features

1. Report intake with description, category, location, and optional images.
2. AI summary generation in the same language as user input (Thai or English).
3. Moderation policy with deterministic thresholds.
4. Duplicate submission suppression (time-window based).
5. Reanalyze mode for reprocessing an existing report.

## Repository Structure (High-Level)

1. `lib/` Flutter application source code.
2. `assets/` static assets for app UI.
3. `index.ts` server-side moderation logic (Supabase Edge Function style).
4. `pubspec.yaml` Flutter dependencies and asset registration.

## Requirements

1. Flutter SDK (stable channel).
2. Dart SDK (included with Flutter).
3. Supabase project and table `reports`.
4. LLM API key and endpoint compatible with OpenAI chat completion schema.

## Client Edge Function Fallback (No Anonymous Auth)

When Supabase Anonymous Auth is disabled, the Flutter app now falls back to invoking an Edge Function for report submission and queue sync.

1. Deploy an Edge Function (default name: `submit-report`) that validates input and inserts into `reports`.
2. Set `verify_jwt = false` for this function if you want true guest submission flow.
3. Optionally override the function name at build/run time:

```bash
flutter run --dart-define=CLASSCARE_SUBMIT_REPORT_FUNCTION=submit-report
```

The default is already `submit-report`, so `--dart-define` is only needed when using a custom function name.

Function entrypoint for this endpoint is also provided at:

1. `supabase/functions/submit-report/index.ts`

It imports the shared handler from `index.ts` so the behavior stays consistent.

## Environment Variables (Server / Edge Function)

Set the following secrets before deployment:

1. `MY_SUPABASE_URL`
2. `MY_SUPABASE_KEY`
3. `MY_LLM_API_KEY`
4. `MY_LLM_MODEL` (optional, default: `llama-3.3-70b-versatile`)
5. `MY_LLM_BASE_URL` (optional, default: `https://api.groq.com/openai/v1`)

Notes:

1. Alias `llama-3.3-70b` is normalized to `llama-3.3-70b-versatile` automatically.
2. The endpoint retries transient AI errors (`429`, `5xx`) with exponential backoff.

## API Contract

### Request Body (new report)

```json
{
  "description": "พบกลุ่มคนทะเลาะเสียงดังและขว้างของใส่กันหน้าอาคาร A",
  "location": "อาคาร A",
  "category": "Safety",
  "image_urls": [
	 "https://example.com/report-1.jpg"
  ]
}
```

### Request Body (reanalyze mode)

```json
{
  "mode": "reanalyze",
  "report_id": "123",
  "report_id_column": "id",
  "description": "ข้อความเดิมหรือข้อความที่แก้ไข",
  "location": "อาคาร A",
  "category": "Safety"
}
```

### Response Shape (success)

```json
{
  "decision": "ACCEPT",
  "triage_label": "URGENT",
  "tracking_id": "ANG-2026-AB12CD",
  "ai_summary": "สรุปเหตุการณ์จาก AI",
  "is_flagged": true,
  "urgency_score": 4.2,
  "severity_score": 4.0,
  "spam_score": 0.03,
  "message": "รับเรื่องเรียบร้อยแล้ว",
  "close_reason": null
}
```

### Response Shape (validation / error)

```json
{
  "decision": "ERROR",
  "code": "VALIDATION_ERROR",
  "message": "กรุณากรอกรายละเอียดอย่างน้อย 20 ตัวอักษร",
  "retryable": false,
  "details": null,
  "is_flagged": false,
  "urgency_score": 0.0
}
```

## Moderation Policy

Policy constants are centralized in `index.ts`:

1. `MIN_DESCRIPTION_LENGTH = 20`
2. `SPAM_AUTO_CLOSE_THRESHOLD = 0.8`
3. `URGENCY_FLAG_THRESHOLD = 4.0`
4. `SEVERE_TRIAGE_THRESHOLD = 4.5`
5. `DEDUPE_WINDOW_MS = 120000` (2 minutes)

### Decision Rules

1. `computedSpam` is true when at least one condition holds:
	- AI returns `is_spam = true`, or
	- `spam_score >= 0.8`, or
	- regex-based spam detector triggers.
2. `computedUrgencyScore = max(urgency, severity_score)`.
3. `isUrgencyFlag` is true when `computedUrgencyScore >= 4.0` and not spam.
4. Final `decision`:
	- `CLOSED` when spam.
	- `FLAG` when urgent and not spam.
	- `ACCEPT` otherwise.
5. Final `triage_label`:
	- `SPAM` when spam.
	- `SEVERE` when `severity_score >= 4.5` and not spam.
	- `URGENT` when urgency flag and not spam.
	- `GENERAL` otherwise.

### Spam Signal Heuristics (Regex)

1. Gambling and betting terms (Thai + English keywords).
2. Promotional call-to-action phrases (`Line ID`, `DM me`, `ซื้อเลย`, etc.).
3. Abnormally repeated characters in compacted text.

## Duplicate Handling

Before inserting a new report, the endpoint checks for an existing report with:

1. same `description`,
2. same `location`,
3. same `category`,
4. created within the last 2 minutes.

If duplicate is found, existing `tracking_id` is reused and insertion is skipped.

## Data Mapping to `reports` Table

Inserted/updated fields include:

1. `description`
2. `location`
3. `category`
4. `status`
5. `tracking_id`
6. `ai_summary`
7. `urgency_score`
8. `is_flagged`
9. `created_at`
10. `image_url` (PostgreSQL array-like payload string when images exist)

## Local Development

### Flutter app

```bash
flutter pub get
flutter run
```

### Lint and tests

```bash
flutter analyze
flutter test
```

### Build examples

```bash
flutter build apk
flutter build web
```

## Operational Notes

1. AI output is constrained to strict JSON but still parsed defensively.
2. Numeric fields are normalized and clamped into expected ranges.
3. CORS is enabled with permissive origin (`*`) in current setup.
4. For production, restrict CORS origin and rotate API keys regularly.

## Recommended Production Hardening

1. Add auth check before allowing moderation endpoint calls.
2. Add rate limiting by IP/user/report_id.
3. Add structured audit logs for moderation decisions.
4. Add alerting for repeated `429`/`5xx` from model provider.
5. Add integration tests for spam/urgent/severe decision boundaries.

## Troubleshooting

1. `Missing MY_LLM_API_KEY secret`
	- Verify edge function secret exists in deployment environment.
2. Frequent AI `429`
	- Reduce traffic burst, add queueing, or use a higher quota model key.
3. JSON parse errors from model output
	- Keep strict response format enabled and review model compatibility.

## References

1. Flutter docs: https://docs.flutter.dev/
2. Supabase docs: https://supabase.com/docs
