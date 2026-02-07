# Urbansight — Smart City Reporting (SDG 11)

**Urbansight** is a hackathon-ready Smart City web application for **SDG 11: Sustainable Cities & Communities**. It lets citizens report city infrastructure issues (potholes, streetlights, flooding, debris, sidewalk hazards) with photos and location, and uses **Google Gemini Vision** to classify and prioritize reports for city staff.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | **Angular** (latest stable, v19+) |
| Styling | **Angular Material** + custom SCSS |
| State | **Services + RxJS** |
| Backend | **Firebase** (Firestore, Storage) |
| Server logic | **Firebase Cloud Functions** (Node.js / TypeScript) |
| AI | **Google Gemini Vision** (Vertex AI or Google AI Studio) |
| Maps | **Google Maps JavaScript API** |
| Auth | Optional (simple admin flag for demo) |

All API keys and secrets are loaded from **environment files**; nothing is hardcoded.

---

## SDG 11: Sustainable Cities & Communities

Urbansight supports **Sustainable Development Goal 11** by:

- Enabling citizens to report infrastructure issues that affect safety, accessibility, and quality of life.
- Using AI to **triage** reports (issue type, severity, action-ready summary) so city staff can prioritize and act faster.
- Providing a **priority queue** and **map view** for staff to resolve potholes, broken streetlights, flooding, debris, and sidewalk hazards efficiently.

This is **AI-powered triage**, not just reporting.

---

## Project structure

```
urbansight-app/
├── src/
│   ├── app/
│   │   ├── core/services/     # Firebase, Report, Toast
│   │   ├── features/         # Landing, Report wizard, Map, Admin
│   │   ├── layout/            # Main layout with nav
│   │   ├── models/            # Report interfaces
│   │   └── shared/components/ # Chips, skeleton, card
│   ├── environments/         # environment.ts, environment.prod.ts
│   └── styles.scss            # Global + Material theme
├── functions/                 # Firebase Cloud Functions (Gemini)
│   ├── src/
│   │   └── index.ts           # analyzeReport callable
│   ├── package.json
│   └── tsconfig.json
├── angular.json
├── package.json
└── README.md
```

---

## Setup

### 1. Prerequisites

- **Node.js** 20+
- **Angular CLI** 19+: `npm i -g @angular/cli@19`
- **Firebase CLI**: `npm i -g firebase-tools`
- **Google Cloud** project with Firebase and (optionally) Vertex AI enabled

### 2. Clone and install

```bash
cd urbansight-app
npm install
```

### 3. Environment variables

**Frontend (Angular)**  
Copy and fill in:

- `src/environments/environment.ts` (development)
- `src/environments/environment.prod.ts` (production)

Required keys:

- **Firebase**: `apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, `appId`
- **Google Maps**: `googleMapsApiKey`

Do **not** commit real keys; use `.env` or CI secrets and document in your own checklist.

**Google Maps in the app**

- In `src/index.html`, replace `YOUR_GOOGLE_MAPS_API_KEY` with your key, or load the script dynamically from `environment.googleMapsApiKey` in your app.

**Cloud Functions (Gemini)**

- In the Firebase project, set a **secret** or **config** for the Gemini API key:
  - e.g. `firebase functions:config:set gemini.apikey="YOUR_GEMINI_API_KEY"`
  - Or use **Firebase Functions config** / **Secret Manager** and read it in the function as `process.env.GEMINI_API_KEY` (see `functions/src/index.ts`).

### 4. Firebase project

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com).
2. Enable **Firestore**, **Storage**, and **Functions**.
3. Register a web app and copy the config into `environment.ts` / `environment.prod.ts`.
4. Deploy Functions (see below).

### 5. Cloud Functions (analyzeReport)

```bash
cd functions
npm install
npm run build
```

Set the Gemini API key (e.g. from [Google AI Studio](https://aistudio.google.com/)):

- Either: `firebase functions:config:set gemini.apikey="YOUR_KEY"` and in code read `functions.config().gemini.apikey`.
- Or: use **Secret Manager** and pass the key into the function as `GEMINI_API_KEY` (as in the provided sample).

Deploy:

```bash
firebase deploy --only functions
```

The client calls the **analyzeReport** callable function after uploading a report image; the function uses Gemini Vision and writes `issueType`, `severity`, and `aiSummary` back to the report document.

---

## Demo steps

1. **Run the app**
   ```bash
   npm start
   ```
   Open `http://localhost:4200`.

2. **Landing**  
   Navigate to **Report** and submit a report (photo + location + optional description).

3. **Report flow**  
   After submit, the app shows “AI analyzing…” then displays **issue type**, **severity**, and **AI summary**. Results are stored in Firestore.

4. **Map**  
   Open **Map** to see all reports; click a marker to open the report detail.

5. **Admin**  
   Open **Admin** → **Dashboard** for a priority-sorted table (severity → upvotes → time). Use **Admin** → **Map** for color-coded markers. Open a report to change **status** (New → In Review → Resolved).

6. **Report detail**  
   Use **View report** from the wizard or open `/report/:id` to see image, AI summary, and upvote.

---

## Routes

| Path | Description |
|------|-------------|
| `/` | Landing (branding + CTA) |
| `/report` | Issue reporting wizard |
| `/map` | Public map of reports |
| `/report/:id` | Public report detail |
| `/admin/dashboard` | Admin priority queue + stats |
| `/admin/map` | Admin map (color-coded) |
| `/admin/report/:id` | Admin report detail + status update |

---

## Firestore data model

**Collection:** `reports`

| Field | Type | Description |
|-------|------|-------------|
| `imageUrl` | string | Storage URL of the report image |
| `lat`, `lng` | number | Location |
| `userDescription` | string | Optional citizen description |
| `issueType` | string | e.g. pothole, broken_streetlight, flooding, debris_garbage, sidewalk_hazard, other |
| `severity` | string | Low, Medium, High |
| `aiSummary` | string | Action-ready summary from Gemini |
| `status` | string | New, InReview, Resolved |
| `createdAt` | number | Timestamp (ms) |
| `upvotes` | number | Count |

---

## License

Use for hackathon and demo purposes. Adjust branding and deployment to your organization’s rules.
