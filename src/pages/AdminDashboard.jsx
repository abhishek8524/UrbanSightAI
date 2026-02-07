import { useState, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import { collection, getDocs, query, orderBy } from 'firebase/firestore'
import { db } from '../lib/firebase'
import L from 'leaflet'

const severityColors = {
  High: 'bg-red-500',
  Medium: 'bg-amber-500',
  Low: 'bg-green-500',
}

const severityOrder = { High: 0, Medium: 1, Low: 2 }

function MapFitBounds({ reports }) {
  const map = useMap()
  useEffect(() => {
    if (reports.length === 0) return
    const bounds = L.latLngBounds(reports.map((r) => [r.latitude, r.longitude]))
    map.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 })
  }, [map, reports])
  return null
}

function createMarkerIcon(severity) {
  const color = severity === 'High' ? '#ef4444' : severity === 'Medium' ? '#f59e0b' : '#22c55e'
  return L.divIcon({
    className: 'custom-marker',
    html: `<div style="background:${color};width:16px;height:16px;border-radius:50%;border:2px solid white;box-shadow:0 1px 3px rgba(0,0,0,0.3)"></div>`,
    iconSize: [20, 20],
    iconAnchor: [10, 10],
  })
}

export default function AdminDashboard() {
  const [reports, setReports] = useState([])
  const [loading, setLoading] = useState(true)
  const [sortBy, setSortBy] = useState('urgency') // urgency | date
  const [filterSeverity, setFilterSeverity] = useState('all')

  useEffect(() => {
    const fetchReports = async () => {
      try {
        const q = query(collection(db, 'reports'), orderBy('timestamp', 'desc'))
        const snap = await getDocs(q)
        const data = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }))
        setReports(data)
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    fetchReports()
  }, [])

  const sorted = [...reports]
    .filter((r) => filterSeverity === 'all' || r.severity === filterSeverity)
    .sort((a, b) => {
      if (sortBy === 'urgency') {
        return (severityOrder[a.severity] ?? 1) - (severityOrder[b.severity] ?? 1)
      }
      return (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0)
    })

  const formatDate = (ts) => {
    if (!ts?.seconds) return '—'
    return new Date(ts.seconds * 1000).toLocaleString()
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-2">Admin Dashboard</h1>
      <p className="text-slate-600 mb-6">View and prioritize urban infrastructure reports.</p>

      {loading ? (
        <div className="py-12 text-center text-slate-500">Loading reports...</div>
      ) : (
        <div className="space-y-6">
          <div className="h-[400px] rounded-xl overflow-hidden border border-slate-200 bg-white shadow-sm">
            <MapContainer
              center={[37.7749, -122.4194]}
              zoom={12}
              className="h-full w-full"
              scrollWheelZoom={true}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <MapFitBounds reports={reports} />
              {reports.map((r) => (
                <Marker
                  key={r.id}
                  position={[r.latitude, r.longitude]}
                  icon={createMarkerIcon(r.severity)}
                >
                  <Popup>
                    <div className="min-w-[200px]">
                      <span className={`inline-block px-2 py-0.5 rounded text-xs text-white ${severityColors[r.severity] || 'bg-slate-500'}`}>
                        {r.severity}
                      </span>
                      <span className="ml-2 text-xs text-slate-500">{r.issueType}</span>
                      <p className="mt-2 text-sm">{r.AI_summary}</p>
                      <p className="mt-1 text-xs text-slate-400">{formatDate(r.timestamp)}</p>
                      {r.imageURL && (
                        <a href={r.imageURL} target="_blank" rel="noreferrer" className="text-xs text-emerald-600 mt-2 block">
                          View photo →
                        </a>
                      )}
                    </div>
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
          </div>

          <div className="flex flex-wrap gap-4 items-center">
            <label className="flex items-center gap-2">
              <span className="text-sm font-medium text-slate-700">Sort:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value)}
                className="px-3 py-2 border border-slate-300 rounded-lg text-sm"
              >
                <option value="urgency">By urgency (High → Low)</option>
                <option value="date">By date (newest first)</option>
              </select>
            </label>
            <label className="flex items-center gap-2">
              <span className="text-sm font-medium text-slate-700">Filter:</span>
              <select
                value={filterSeverity}
                onChange={(e) => setFilterSeverity(e.target.value)}
                className="px-3 py-2 border border-slate-300 rounded-lg text-sm"
              >
                <option value="all">All severities</option>
                <option value="High">High</option>
                <option value="Medium">Medium</option>
                <option value="Low">Low</option>
              </select>
            </label>
          </div>

          <div className="rounded-xl border border-slate-200 bg-white overflow-hidden shadow-sm">
            <div className="overflow-x-auto max-h-[400px] overflow-y-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 sticky top-0">
                  <tr>
                    <th className="text-left px-4 py-3 font-semibold text-slate-700">Severity</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-700">Type</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-700">Summary</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-700">Date</th>
                    <th className="text-left px-4 py-3 font-semibold text-slate-700">Location</th>
                  </tr>
                </thead>
                <tbody>
                  {sorted.map((r) => (
                    <tr key={r.id} className="border-t border-slate-100 hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium text-white ${severityColors[r.severity] || 'bg-slate-500'}`}>
                          {r.severity}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-slate-600">{r.issueType}</td>
                      <td className="px-4 py-3 text-slate-700 max-w-xs truncate">{r.AI_summary}</td>
                      <td className="px-4 py-3 text-slate-500 text-xs">{formatDate(r.timestamp)}</td>
                      <td className="px-4 py-3 text-slate-500 text-xs">
                        {r.latitude?.toFixed(4)}, {r.longitude?.toFixed(4)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {sorted.length === 0 && (
              <div className="py-12 text-center text-slate-500">No reports yet.</div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
