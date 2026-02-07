import { BrowserRouter, Routes, Route } from 'react-router-dom'
import ReportForm from './pages/ReportForm'
import AdminDashboard from './pages/AdminDashboard'
import Layout from './components/Layout'

function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<ReportForm />} />
          <Route path="/admin" element={<AdminDashboard />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App
