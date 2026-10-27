import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

import Privacy from './Privacy.jsx'
import Terms from './Terms.jsx'

const path = window.location.pathname;

createRoot(document.getElementById('root')).render(
  <StrictMode>
    {path === '/privacy' ? <Privacy /> : path === '/terms' ? <Terms /> : <App />}
  </StrictMode>,
)
