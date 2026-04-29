import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "POST, OPTIONS",
	"Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const jsonHeaders = {
	...corsHeaders,
	"Content-Type": "application/json; charset=utf-8",
};

const jsonResponse = (body: unknown, status = 200) =>
	new Response(JSON.stringify(body), { status, headers: jsonHeaders });

const errorResponse = (
	status: number,
	code: string,
	message: string,
	retryable = false,
	details?: unknown,
) =>
	jsonResponse(
		{
			decision: "ERROR",
			code,
			message,
			retryable,
			details: details ?? null,
			is_flagged: false,
			urgency_score: 0.0,
		},
		status,
	);

type StructuredServerError = {
	status: number;
	code: string;
	message: string;
	retryable: boolean;
	details?: unknown;
};

type AnyErrorLike = {
	message?: string;
	code?: string;
	details?: string;
	hint?: string;
	status?: number;
};

type LlmAnalysis = {
	summary: string;
	urgency: number;
	severity_score: number;
	spam_score: number;
	is_spam: boolean;
	triage_label: "SPAM" | "SEVERE" | "URGENT" | "GENERAL";
};

type SpamCheckResult = {
	autoClose: boolean;
	reasons: string[];
};

const DEFAULT_AI_RESULT: LlmAnalysis = {
	summary: "รอเจ้าหน้าที่ตรวจสอบ",
	urgency: 1.0,
	severity_score: 1.0,
	spam_score: 0.0,
	is_spam: false,
	triage_label: "GENERAL",
};

const MIN_DESCRIPTION_LENGTH = 20;
const DEDUPE_WINDOW_MS = 2 * 60 * 1000;
const SPAM_AUTO_CLOSE_THRESHOLD = 0.8;
const URGENCY_FLAG_THRESHOLD = 4.0;
const SEVERE_TRIAGE_THRESHOLD = 4.5;

function mapServerError(err: unknown): StructuredServerError {
	const fallback: StructuredServerError = {
		status: 500,
		code: "UNEXPECTED_ERROR",
		message: "Unexpected server error",
		retryable: true,
		details: err,
	};

	const raw: AnyErrorLike = err instanceof Error
		? {
				message: err.message,
				code: (err as AnyErrorLike).code,
				details: (err as AnyErrorLike).details,
				hint: (err as AnyErrorLike).hint,
				status: (err as AnyErrorLike).status,
			}
		: typeof err === "object" && err !== null
		? err as AnyErrorLike
		: {};

	const code = String(raw.code ?? "").toUpperCase();
	const details = raw.details ?? raw.hint ?? raw.message ?? null;

	if (code === "23505") {
		return {
			status: 409,
			code: "DUPLICATE_REPORT",
			message: "พบรายงานซ้ำในระบบ",
			retryable: false,
			details,
		};
	}

	if (code === "23502" || code === "23514" || code === "22P02") {
		return {
			status: 422,
			code: "VALIDATION_ERROR",
			message: "ข้อมูลรายงานไม่ถูกต้อง",
			retryable: false,
			details,
		};
	}

	if (code === "42501" || code === "PGRST301" || code === "PGRST302") {
		return {
			status: 403,
			code: "FORBIDDEN",
			message: "ไม่สามารถดำเนินการได้ด้วยสิทธิ์ปัจจุบัน",
			retryable: false,
			details,
		};
	}

	if (code.startsWith("PGRST")) {
		return {
			status: raw.status != null && raw.status >= 400 && raw.status < 500 ? raw.status : 400,
			code: "REQUEST_REJECTED",
			message: raw.message ?? "Request rejected",
			retryable: false,
			details,
		};
	}

	if (raw.message?.toLowerCase().includes("timeout")) {
		return {
			status: 504,
			code: "TIMEOUT",
			message: "Backend request timed out",
			retryable: true,
			details,
		};
	}

	if (raw.message?.toLowerCase().includes("not authenticated")) {
		return {
			status: 401,
			code: "NOT_AUTHENTICATED",
			message: "Not authenticated",
			retryable: false,
			details,
		};
	}

	return {
		...fallback,
		message: raw.message ?? fallback.message,
		details,
	};
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function detectSpamSignals(description: string, category: string): SpamCheckResult {
	const text = `${description} ${category}`.toLowerCase().trim();
	const reasons: string[] = [];

	const gamblingPattern =
		/(พนัน|คาสิโน|บาคาร่า|สล็อต|หวย|แทงบอล|เว็บพนัน|ufa|bet\b|พนันออนไลน์|สายปั่น|เครดิตฟรี)/i;
	if (gamblingPattern.test(text)) {
		reasons.push("พบเนื้อหาเชิงพนันหรือชักชวนเล่นพนัน");
	}

	const promoSpamPattern =
		/(แอดไลน์|ทักไลน์|line\s?id|โปรโมชัน|โปรโมชั่น|ซื้อเลย|click here|dm me|แอดมาเลย|ฝากถอน)/i;
	if (promoSpamPattern.test(text)) {
		reasons.push("พบลักษณะข้อความโฆษณา/ชักชวน");
	}

	const compact = description.replace(/\s+/g, "").toLowerCase();
	const repeatedCharPattern = /(.)\1{7,}/;
	if (repeatedCharPattern.test(compact)) {
		reasons.push("พบข้อความซ้ำผิดปกติหรือมั่ว");
	}

	return {
		autoClose: reasons.length > 0,
		reasons,
	};
}

function generateTrackingId() {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	const code = Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
	return `ANG-2026-${code}`;
}

function normalizeModelName(rawModel?: string) {
	const model = (rawModel ?? "").trim();
	if (!model) return "llama-3.3-70b-versatile";
	if (model === "llama-3.3-70b") return "llama-3.3-70b-versatile";
	return model;
}

function toPgTextArray(values: string[]) {
	return `{${values.map((v) => `"${v.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`).join(",")}}`;
}

function clampNumber(value: unknown, min: number, max: number, fallback: number) {
	const parsed = typeof value === "number" ? value : parseFloat(String(value ?? ""));
	if (Number.isNaN(parsed)) return fallback;
	return Math.min(max, Math.max(min, parsed));
}

async function callLlamaWithRetry(
	baseUrl: string,
	apiKey: string,
	payload: unknown,
	requestId: string,
	maxAttempts = 3,
) {
	let lastResponse: Response | null = null;

	for (let attempt = 1; attempt <= maxAttempts; attempt++) {
		console.log(`[${requestId}] [Llama] Attempt ${attempt}/${maxAttempts} - sending request`);

		const response = await fetch(`${baseUrl}/chat/completions`, {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${apiKey}`,
			},
			body: JSON.stringify(payload),
		});

		lastResponse = response;
		console.log(`[${requestId}] [Llama] Attempt ${attempt}/${maxAttempts} - status ${response.status}`);

		if (response.status === 429 || response.status >= 500) {
			if (attempt < maxAttempts) {
				const backoffMs = 700 * Math.pow(2, attempt - 1);
				console.warn(`[${requestId}] [Llama] transient status ${response.status}, retrying in ${backoffMs}ms`);
				await sleep(backoffMs);
				continue;
			}
			console.error(`[${requestId}] [Llama] exhausted retries with transient status ${response.status}`);
		}

		return response;
	}

	console.error(`[${requestId}] [Llama] no response returned, using last response fallback`);
	return lastResponse!;
}

async function analyzeWithLlm(
	description: string,
	category: string,
	location: string,
	requestId: string,
): Promise<LlmAnalysis> {
	const llmApiKey = Deno.env.get("MY_LLM_API_KEY");
	if (!llmApiKey) {
		console.warn(`[${requestId}] MY_LLM_API_KEY missing; continue with default AI result.`);
		return DEFAULT_AI_RESULT;
	}

	const modelName = normalizeModelName(Deno.env.get("MY_LLM_MODEL"));
	const baseUrl = Deno.env.get("MY_LLM_BASE_URL") ?? "https://api.groq.com/openai/v1";

	const aiPayload = {
		model: modelName,
		messages: [
			{
				role: "system",
				content:
					[
						"You analyze incident reports for moderation and priority triage.",
						"Return strict JSON only with keys:",
						"summary (string), urgency (number 1.0-5.0), severity_score (number 1.0-5.0), spam_score (number 0.0-1.0), is_spam (boolean), triage_label (SPAM|SEVERE|URGENT|GENERAL).",
						"Rules:",
						"- SPAM: ads, nonsense, harassment, or fabricated/low-signal content.",
						"- SEVERE: violent threat, weapon, self-harm risk, active danger, or major safety incident.",
						"- URGENT: needs quick intervention but not as severe as SEVERE.",
						"- GENERAL: normal/non-urgent report.",
					].join(" "),
			},
			{
				role: "user",
				content: [
					"Analyze this incident report:",
					`Description: \"${description}\"`,
					`Category: ${category}, Location: ${location}`,
					"The report may be in Thai or English. Reply in the SAME language as the description.",
					"Reply in JSON only, no markdown:",
					'{"summary":"1-2 sentence summary","urgency":3.5,"severity_score":2.5,"spam_score":0.02,"is_spam":false,"triage_label":"GENERAL"}',
					"urgency must be a number between 1.0 and 5.0",
					"severity_score must be a number between 1.0 and 5.0",
					"spam_score must be a number between 0.0 and 1.0",
				].join("\n"),
			},
		],
		temperature: 0.1,
		response_format: { type: "json_object" },
	};

	try {
		const aiRes = await callLlamaWithRetry(baseUrl, llmApiKey, aiPayload, requestId, 3);

		if (!aiRes.ok) {
			const errBody = await aiRes.text();
			console.error(`[${requestId}] Llama HTTP error: ${aiRes.status}, body: ${errBody}`);
			return {
				...DEFAULT_AI_RESULT,
				summary: aiRes.status === 429 ? "AI คิวเต็ม (ประมวลผลภายหลัง)" : `AI error ${aiRes.status}`,
			};
		}

		const data = await aiRes.json();
		const rawText: string = data.choices?.[0]?.message?.content ?? "";
		const cleaned = rawText.replace(/```json|```/gi, "").trim();

		try {
			const parsed = JSON.parse(cleaned);
			const normalizedTriage = (parsed.triage_label ?? "")
				.toString()
				.trim()
				.toUpperCase();

			return {
				summary: typeof parsed.summary === "string" && parsed.summary.trim()
					? parsed.summary.trim()
					: DEFAULT_AI_RESULT.summary,
				urgency: clampNumber(parsed.urgency, 1.0, 5.0, 1.0),
				severity_score: clampNumber(parsed.severity_score, 1.0, 5.0, 1.0),
				spam_score: clampNumber(parsed.spam_score, 0.0, 1.0, 0.0),
				is_spam: parsed.is_spam === true,
				triage_label: ["SPAM", "SEVERE", "URGENT", "GENERAL"].includes(normalizedTriage)
					? normalizedTriage as LlmAnalysis["triage_label"]
					: "GENERAL",
			};
		} catch (parseErr) {
			console.error(`[${requestId}] JSON parse error from LLM:`, parseErr, "raw:", rawText);
			return DEFAULT_AI_RESULT;
		}
	} catch (err) {
		console.error(`[${requestId}] LLM call exception:`, err);
		return DEFAULT_AI_RESULT;
	}
}

function computeDecision(aiResult: LlmAnalysis, spamCheck: SpamCheckResult) {
	const computedSpam =
		aiResult.is_spam === true || aiResult.spam_score >= SPAM_AUTO_CLOSE_THRESHOLD || spamCheck.autoClose;
	const computedUrgencyScore = Math.max(aiResult.urgency, aiResult.severity_score);
	const isUrgencyFlag = computedUrgencyScore >= URGENCY_FLAG_THRESHOLD && computedSpam !== true;
	const autoCloseReason = computedSpam
		? `ปิดอัตโนมัติ: ${[
				...(aiResult.is_spam || aiResult.spam_score >= SPAM_AUTO_CLOSE_THRESHOLD
					? ["AI จัดว่าเป็นสแปม"]
					: []),
				...spamCheck.reasons,
			].join("; ")}`
		: null;

	const decision = computedSpam ? "CLOSED" : isUrgencyFlag ? "FLAG" : "ACCEPT";
	const triageLabel = computedSpam
		? "SPAM"
		: aiResult.severity_score >= SEVERE_TRIAGE_THRESHOLD
		? "SEVERE"
		: isUrgencyFlag
		? "URGENT"
		: "GENERAL";

	return {
		computedSpam,
		computedUrgencyScore,
		isUrgencyFlag,
		autoCloseReason,
		decision,
		triageLabel,
	};
}

type CanonicalStatus = "PENDING" | "IN REVIEW" | "RESOLVED" | "CLOSED";

function normalizeReportStatus(rawStatus: unknown, fallback: CanonicalStatus = "PENDING"): CanonicalStatus {
	const compact = String(rawStatus ?? "")
		.trim()
		.toUpperCase()
		.replace(/[\s_-]+/g, "");

	if (["PENDING", "SUBMITTED", "NEW", "OPEN", "QUEUED"].includes(compact)) {
		return "PENDING";
	}
	if (["INREVIEW", "REVIEWING", "UNDERREVIEW", "TRIAGED"].includes(compact)) {
		return "IN REVIEW";
	}
	if (["RESOLVED", "DONE", "SUCCESS", "COMPLETED"].includes(compact)) {
		return "RESOLVED";
	}
	if (["CLOSED", "CLOSE", "REJECTED", "SPAM"].includes(compact)) {
		return "CLOSED";
	}

	return fallback;
}

function buildLifecycleTimestamps(status: CanonicalStatus, nowIso: string) {
	const updates: Record<string, string> = {
		ai_triaged_at: nowIso,
	};

	if (status === "IN REVIEW" || status === "RESOLVED" || status === "CLOSED") {
		updates.review_started_at = nowIso;
	}
	if (status === "RESOLVED") {
		updates.resolved_at = nowIso;
	}
	if (status === "CLOSED") {
		updates.closed_at = nowIso;
	}

	return updates;
}

export async function handleSubmitReport(req: Request) {
	if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
	if (req.method !== "POST") {
		return errorResponse(405, "METHOD_NOT_ALLOWED", "Method not allowed", false);
	}

	const requestId = crypto.randomUUID();
	console.log(`[${requestId}] moderate-report request started`);

	try {
		let payload: Record<string, unknown>;
		try {
			payload = await req.json();
		} catch {
			return errorResponse(400, "INVALID_JSON", "Invalid JSON payload", false);
		}

		const {
			description,
			location,
			category,
			mode,
			report_id,
			report_id_column,
			image_urls,
			tracking_id,
			title,
		} = payload;

		const normalizedDescription = String(description ?? "").trim();
		const normalizedLocation = String(location ?? "Not specified").trim() || "Not specified";
		const normalizedCategory = String(category ?? title ?? "General").trim() || "General";

		if (mode !== "reanalyze" && normalizedDescription.length < MIN_DESCRIPTION_LENGTH) {
			return errorResponse(
				400,
				"VALIDATION_ERROR",
				"กรุณากรอกรายละเอียดอย่างน้อย 20 ตัวอักษร",
				false,
			);
		}

		const supabaseUrl = Deno.env.get("MY_SUPABASE_URL");
		const supabaseServiceRoleKey =
			Deno.env.get("MY_SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
		if (!supabaseUrl || !supabaseServiceRoleKey) {
			return errorResponse(
				500,
				"SERVER_MISCONFIGURED",
				"Missing MY_SUPABASE_URL or service role key secret",
				false,
			);
		}

		const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);
		const spamCheck = detectSpamSignals(normalizedDescription, normalizedCategory);
		const aiResult = await analyzeWithLlm(
			normalizedDescription,
			normalizedCategory,
			normalizedLocation,
			requestId,
		);

		if (mode === "reanalyze") {
			if (!report_id) {
				return errorResponse(
					400,
					"VALIDATION_ERROR",
					"Missing report_id for reanalyze mode",
					false,
				);
			}

			const reportIdColumn =
				typeof report_id_column === "string" && report_id_column.trim()
					? report_id_column.trim()
					: "id";

			const computed = computeDecision(aiResult, spamCheck);
			const normalizedStatus = normalizeReportStatus(
				computed.computedSpam ? "CLOSED" : "IN REVIEW",
				"IN REVIEW",
			);
			const nowIso = new Date().toISOString();
			const lifecycleTimestamps = buildLifecycleTimestamps(normalizedStatus, nowIso);

			const { error: updateError } = await supabase
				.from("reports")
				.update({
					ai_summary: computed.autoCloseReason
						? `${aiResult.summary} | ${computed.autoCloseReason}`
						: aiResult.summary,
					urgency_score: computed.computedUrgencyScore,
					is_flagged: computed.computedSpam ? true : computed.isUrgencyFlag,
					status: normalizedStatus,
					...lifecycleTimestamps,
				})
				.eq(reportIdColumn, report_id);

			if (updateError) {
				console.error(`[${requestId}] reanalyze update error:`, updateError);
				throw updateError;
			}

			return jsonResponse({
				decision: computed.decision,
				triage_label: computed.triageLabel,
				status: normalizedStatus,
				ai_summary: computed.autoCloseReason
					? `${aiResult.summary} | ${computed.autoCloseReason}`
					: aiResult.summary,
				is_flagged: computed.computedSpam ? true : computed.isUrgencyFlag,
				urgency_score: computed.computedUrgencyScore,
				severity_score: aiResult.severity_score,
				spam_score: aiResult.spam_score,
				message: computed.computedSpam ? "งานถูกปิดอัตโนมัติเนื่องจากเข้าข่ายสแปม" : "AI analysis updated",
				close_reason: computed.autoCloseReason,
			});
		}

		const sinceIso = new Date(Date.now() - DEDUPE_WINDOW_MS).toISOString();
		const { data: recentDup, error: dedupeError } = await supabase
			.from("reports")
			.select("tracking_id, ai_summary, urgency_score, is_flagged, status, created_at")
			.eq("description", normalizedDescription)
			.eq("location", normalizedLocation)
			.eq("category", normalizedCategory)
			.gte("created_at", sinceIso)
			.order("created_at", { ascending: false })
			.limit(1)
			.maybeSingle();

		if (dedupeError) {
			console.error(`[${requestId}] dedupe lookup error:`, dedupeError);
		}

		if (recentDup?.tracking_id) {
			const dupStatus = normalizeReportStatus(recentDup.status, "PENDING");
			const duplicateCloseReason =
				dupStatus === "CLOSED" && (recentDup.ai_summary ?? "").toString().includes("ปิดอัตโนมัติ:")
					? "พบรายการซ้ำที่ปิดอัตโนมัติไว้ก่อนหน้า"
					: null;

			return jsonResponse({
				decision: dupStatus === "CLOSED"
					? "CLOSED"
					: (recentDup.is_flagged === true ? "FLAG" : "ACCEPT"),
				status: dupStatus,
				tracking_id: recentDup.tracking_id,
				ai_summary: recentDup.ai_summary ?? aiResult.summary,
				is_flagged: recentDup.is_flagged === true,
				urgency_score: Number(recentDup.urgency_score ?? aiResult.urgency),
				message: duplicateCloseReason ?? "Duplicate report detected; reused existing tracking ID",
				close_reason: duplicateCloseReason,
			});
		}

		const requestedTrackingId = String(tracking_id ?? "").trim();
		const trackingId = requestedTrackingId || generateTrackingId();

		const normalizedImageUrls = Array.isArray(image_urls)
			? image_urls
					.map((u) => String(u ?? "").trim())
					.filter((u) => u.length > 0)
			: [];

		const pgImageArray = normalizedImageUrls.length > 0
			? toPgTextArray(normalizedImageUrls)
			: null;

		const computed = computeDecision(aiResult, spamCheck);
		const normalizedStatus = normalizeReportStatus(
			computed.computedSpam ? "CLOSED" : "PENDING",
			"PENDING",
		);
		const nowIso = new Date().toISOString();
		const lifecycleTimestamps = buildLifecycleTimestamps(normalizedStatus, nowIso);

		const insertData: Record<string, unknown> = {
			description: normalizedDescription,
			location: normalizedLocation,
			category: normalizedCategory,
			status: normalizedStatus,
			tracking_id: trackingId,
			ai_summary: computed.autoCloseReason
				? `${aiResult.summary} | ${computed.autoCloseReason}`
				: aiResult.summary,
			urgency_score: computed.computedUrgencyScore,
			is_flagged: computed.computedSpam ? true : computed.isUrgencyFlag,
			created_at: nowIso,
			...lifecycleTimestamps,
		};

		if (pgImageArray !== null) {
			insertData.image_url = pgImageArray;
		}

		const { error: dbError } = await supabase.from("reports").insert(insertData);
		if (dbError) {
			console.error(`[${requestId}] insert error:`, dbError);
			throw dbError;
		}

		console.log(`[${requestId}] insert success tracking_id=${trackingId}`);

		return jsonResponse({
			decision: computed.decision,
			triage_label: computed.triageLabel,
			status: normalizedStatus,
			tracking_id: trackingId,
			ai_summary: computed.autoCloseReason
				? `${aiResult.summary} | ${computed.autoCloseReason}`
				: aiResult.summary,
			is_flagged: computed.computedSpam ? true : computed.isUrgencyFlag,
			urgency_score: computed.computedUrgencyScore,
			severity_score: aiResult.severity_score,
			spam_score: aiResult.spam_score,
			message: computed.computedSpam
				? "ระบบปิดงานอัตโนมัติเนื่องจากเข้าข่ายสแปม"
				: "รับเรื่องเรียบร้อยแล้ว",
			close_reason: computed.autoCloseReason,
		});
	} catch (err) {
		const mapped = mapServerError(err);
		console.error(`[${requestId}] handler error mapped:`, mapped);
		return errorResponse(
			mapped.status,
			mapped.code,
			mapped.message,
			mapped.retryable,
			mapped.details,
		);
	}
}

if (import.meta.main) {
	serve(handleSubmitReport);
}
