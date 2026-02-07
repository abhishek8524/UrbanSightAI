import { useState, useCallback } from 'react'
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { collection, addDoc, serverTimestamp } from 'firebase/firestore'
import { storage, db } from '../lib/firebase'
import { analyzeImageWithGemini } from '../lib/gemini'

export default function ReportForm() {
  const [image, setImage] = useState(null)
  const [description, setDescription] = useState('')
  const [location, setLocation] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  const getLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setError('Geolocation is not supported by your browser')
      return
    }
    setLoading(true)
    setError('')
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude })
        setLoading(false)
      },
      (err) => {
        setError('Could not get location: ' + err.message)
        setLoading(false)
      }
    )
  }, [])

  const handleImageChange = (e) => {
    const file = e.target.files?.[0]
    if (file && file.type.startsWith('image/')) {
      setImage(file)
      setError('')
    } else {
      setError('Please select an image file (JPEG, PNG, WebP)')
    }
  }

  const fileToBase64 = (file) =>
    new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result?.split(',')[1])
      reader.onerror = reject
      reader.readAsDataURL(file)
    })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess(false)

    if (!image) {
      setError('Please upload a photo')
      return
    }

    if (!location) {
      setError('Please capture your location first')
      return
    }

    setLoading(true)

    try {
      // 1. Upload image to Firebase Storage
      const filename = `reports/${Date.now()}_${image.name}`
      const storageRef = ref(storage, filename)
      await uploadBytes(storageRef, image)
      const imageURL = await getDownloadURL(storageRef)

      // 2. Analyze with Gemini Vision
      const base64 = await fileToBase64(image)
      const mime = image.type || 'image/jpeg'
      const analysis = await analyzeImageWithGemini(base64, mime, description)

      // 3. Store in Firestore
      await addDoc(collection(db, 'reports'), {
        imageURL,
        latitude: location.lat,
        longitude: location.lng,
        issueType: analysis.issueType || 'other',
        severity: analysis.severity || 'Medium',
        AI_summary: analysis.AI_summary || 'No summary generated',
        userDescription: description || '',
        timestamp: serverTimestamp(),
      })

      setSuccess(true)
      setImage(null)
      setDescription('')
      setLocation(null)
      document.querySelector('input[type="file"]').value = ''
    } catch (err) {
      setError(err.message || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold text-slate-800 mb-2">Report an Issue</h1>
      <p className="text-slate-600 mb-6">
        Upload a photo of potholes, broken streetlights, flooding, or debris. AI will analyze and categorize it.
      </p>

      {success && (
        <div className="mb-6 p-4 bg-emerald-50 border border-emerald-200 rounded-lg text-emerald-800">
          ✓ Report submitted successfully. City workers will be notified.
        </div>
      )}

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">Photo *</label>
          <input
            type="file"
            accept="image/jpeg,image/png,image/webp"
            onChange={handleImageChange}
            className="block w-full text-sm text-slate-600 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200"
          />
          {image && (
            <p className="mt-2 text-sm text-slate-500">
              Selected: {image.name}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">Description (optional)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Brief description of the issue..."
            rows={2}
            className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">Location *</label>
          <button
            type="button"
            onClick={getLocation}
            disabled={loading}
            className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-lg font-medium text-slate-700 disabled:opacity-50"
          >
            {loading && !location ? 'Getting location...' : location ? `✓ Captured (${location.lat.toFixed(5)}, ${location.lng.toFixed(5)})` : 'Capture my location'}
          </button>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition"
        >
          {loading ? 'Submitting...' : 'Submit Report'}
        </button>
      </form>
    </div>
  )
}
