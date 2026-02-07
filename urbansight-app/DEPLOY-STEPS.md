# What to do after upgrading to Blaze

Run these in order from the **urbansight-app** folder.

## 1. Login to Firebase (if you haven’t)

```bash
firebase login
```

## 2. Set the Gemini API key for Cloud Functions

```bash
firebase functions:config:set gemini.apikey="AIzaSyBgA--NyauKApnDFLuNz0XYYLeR59JO1Rw"
```

## 3. Deploy Cloud Functions

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

## 4. (Optional) Deploy Firestore & Storage rules

So your DB and storage use the rules in the repo:

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## 5. Run the Angular app

```bash
npm start
```

Then open **http://localhost:4200** and try submitting a report with a photo. The “AI analyzing…” step will use your deployed function and Gemini key.

---

**Already done for you:** Firebase project is set to `urbansight-a4ff3` in `.firebaserc`, and your Firebase + Maps keys are in the app environment files.
