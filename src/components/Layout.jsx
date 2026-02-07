import { Link, useLocation } from 'react-router-dom'

export default function Layout({ children }) {
  const location = useLocation()
  const isReport = location.pathname === '/'
  const isAdmin = location.pathname === '/admin'

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white border-b border-slate-200 shadow-sm">
        <nav className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2">
            <span className="text-2xl">🏙️</span>
            <span className="font-bold text-xl text-slate-800">Urbansight</span>
          </Link>
          <div className="flex gap-4">
            <Link
              to="/"
              className={`px-4 py-2 rounded-lg font-medium transition ${
                isReport ? 'bg-emerald-100 text-emerald-800' : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Report
            </Link>
            <Link
              to="/admin"
              className={`px-4 py-2 rounded-lg font-medium transition ${
                isAdmin ? 'bg-emerald-100 text-emerald-800' : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              Admin
            </Link>
          </div>
        </nav>
      </header>
      <main className="max-w-6xl mx-auto px-4 py-8">{children}</main>
    </div>
  )
}
