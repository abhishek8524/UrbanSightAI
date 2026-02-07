const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

export async function analyzeImageWithGemini(base64Image, mimeType, userDescription) {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY
  if (!apiKey) throw new Error('VITE_GEMINI_API_KEY is not set')

  const prompt = `Analyze this image of an urban infrastructure issue. The user's description: "${userDescription || 'No description provided'}"

Respond with ONLY valid JSON in this exact format (no markdown, no extra text):
{
  "issueType": "pothole" | "broken_streetlight" | "flooding" | "debris" | "other",
  "severity": "Low" | "Medium" | "High",
  "AI_summary": "A concise 1-2 sentence summary of the issue for city workers"
}

Rules:
- issueType must be one of: pothole, broken_streetlight, flooding, debris, other
- severity: Low (minor), Medium (moderate risk), High (urgent/safety risk)
- AI_summary: brief, actionable description`

  const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{
        parts: [
          {
            inlineData: {
              mimeType: mimeType || 'image/jpeg',
              data: base64Image,
            },
          },
          { text: prompt },
        ],
      }],
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.2,
      },
    }),
  })

  if (!response.ok) {
    const err = await response.text()
    throw new Error(`Gemini API error: ${err}`)
  }

  const data = await response.json()
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text
  if (!text) throw new Error('No response from Gemini')

  return JSON.parse(text.trim())
}
