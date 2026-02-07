import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();

const VALID_ISSUE_TYPES = [
  "pothole",
  "broken_streetlight",
  "flooding",
  "debris_garbage",
  "sidewalk_hazard",
  "other",
] as const;
const VALID_SEVERITIES = ["Low", "Medium", "High"] as const;

type IssueType = (typeof VALID_ISSUE_TYPES)[number];
type Severity = (typeof VALID_SEVERITIES)[number];

interface GeminiAnalysis {
  issueType: IssueType;
  severity: Severity;
  aiSummary: string;
}

export const analyzeReport = functions.https.onCall(
  async (data: {
    reportId: string;
    imageUrl: string;
    userDescription?: string;
  }) => {
    const { reportId, imageUrl, userDescription } = data;
    if (!reportId || !imageUrl) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "reportId and imageUrl are required"
      );
    }

    const apiKey =
      process.env.GEMINI_API_KEY ||
      (functions.config().gemini?.apikey as string | undefined);
    if (!apiKey) {
      await applyFallback(reportId);
      return { success: false, fallback: true };
    }

    try {
      const analysis = await runGeminiAnalysis(imageUrl, userDescription);
      if (analysis) {
        await admin.firestore().collection("reports").doc(reportId).update({
          issueType: analysis.issueType,
          severity: analysis.severity,
          aiSummary: analysis.aiSummary,
        });
        return { success: true, ...analysis };
      }
    } catch (e) {
      functions.logger.warn("Gemini analysis failed", e);
    }

    await applyFallback(reportId);
    return { success: false, fallback: true };
  }
);

async function runGeminiAnalysis(
  imageUrl: string,
  userDescription?: string
): Promise<GeminiAnalysis | null> {
  const apiKey =
    process.env.GEMINI_API_KEY ||
    (functions.config().gemini?.apikey as string | undefined);
  if (!apiKey) return null;

  const imageBase64 = await fetchImageAsBase64(imageUrl);
  if (!imageBase64) return null;

  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `You are a city infrastructure analyst. Analyze this image of a reported urban issue.

${userDescription ? `Citizen description: ${userDescription}` : ""}

Respond with ONLY a valid JSON object (no markdown, no code block), with exactly these keys:
- "issueType": one of: pothole, broken_streetlight, flooding, debris_garbage, sidewalk_hazard, other
- "severity": one of: Low, Medium, High
- "aiSummary": a short, action-ready summary (1-2 sentences) for city staff

Example: {"issueType":"pothole","severity":"High","aiSummary":"Large pothole on main road near intersection. Recommend temporary signage and repair within 48 hours."}`;

  const result = await model.generateContent([
    {
      inlineData: {
        mimeType: "image/jpeg",
        data: imageBase64,
      },
    },
    { text: prompt },
  ]);

  const response = result.response;
  const text = response.text();
  if (!text) return null;

  const parsed = parseJsonResponse<GeminiAnalysis>(text);
  if (!parsed) return null;

  if (
    !VALID_ISSUE_TYPES.includes(parsed.issueType) ||
    !VALID_SEVERITIES.includes(parsed.severity) ||
    typeof parsed.aiSummary !== "string"
  ) {
    return null;
  }

  return {
    issueType: parsed.issueType,
    severity: parsed.severity,
    aiSummary: parsed.aiSummary.slice(0, 500),
  };
}

async function fetchImageAsBase64(url: string): Promise<string | null> {
  try {
    const res = await fetch(url);
    const buf = await res.arrayBuffer();
    const b64 = Buffer.from(buf).toString("base64");
    return b64;
  } catch {
    return null;
  }
}

function parseJsonResponse<T>(text: string): T | null {
  const cleaned = text.replace(/```json\s?|\s?```/g, "").trim();
  try {
    return JSON.parse(cleaned) as T;
  } catch {
    return null;
  }
}

async function applyFallback(reportId: string): Promise<void> {
  await admin.firestore().collection("reports").doc(reportId).update({
    issueType: "other",
    severity: "Medium",
    aiSummary: "Analysis unavailable. Manual review required.",
  });
}
