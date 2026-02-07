# Urbansight – Smart City Reports

A demo-ready Smart City web app where citizens report urban infrastructure issues (potholes, broken streetlights, flooding, debris) via photo upload, location capture, and AI-powered analysis.

## Features

- **Report Form**: Upload a photo → capture location → add description → submit
- **Gemini Vision**: Classifies issue type, severity (Low/Medium/High), and generates an AI summary
- **Firebase Firestore**: Stores reports with `imageURL`, `latitude`, `longitude`, `issueType`, `severity`, `AI_summary`, `timestamp`
- **Admin Dashboard**: Map with color-coded severity markers + sortable list prioritized by urgency

## Setup

1. **Clone and install**
   ```bash
   npm install
   ```

2. **Firebase**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Enable Firestore and Storage
   - Add a web app and copy the config
   - Create `.env` from `.env.example` and fill in Firebase values

3. **Gemini API**
   - Get an API key at [Google AI Studio](https://aistudio.google.com/apikey)
   - Add `VITE_GEMINI_API_KEY=your_key` to `.env`

4. **Firestore rules** (for demo)
   - Firestore: allow read, write for testing (tighten for production)
   - Storage: allow read, write for testing (tighten for production)

5. **Run**
   ```bash
   npm run dev
   ```

## Project structure

```
src/
  pages/ReportForm.jsx    # Citizen report form
  pages/AdminDashboard.jsx # Admin map + list
  components/Layout.jsx   # App shell
  lib/firebase.js         # Firebase config
  lib/gemini.js           # Gemini Vision API
```

## Tech stack

- React + Vite
- Firebase (Firestore, Storage)
- Gemini Vision API
- React Leaflet
- Tailwind CSS
