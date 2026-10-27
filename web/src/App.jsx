import { useState, useEffect } from 'react'
import { createClient } from '@supabase/supabase-js'
import { Lock, Eye, EyeOff, CheckCircle2, AlertCircle, ShieldCheck } from 'lucide-react'
import './App.css'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://placeholder.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'placeholder'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

function App() {
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState(null)
  const [error, setError] = useState(() => {
    if (typeof window === 'undefined') return null
    if (window.location.hash.includes('error=')) {
      const hashParams = new URLSearchParams(window.location.hash.substring(1))
      const errDesc = hashParams.get('error_description') || 'The link has expired or is invalid.'
      return errDesc.replace(/\+/g, ' ')
    }
    return null
  })
  const [isRecovery, setIsRecovery] = useState(() => {
    if (typeof window === 'undefined') return false
    const url = new URL(window.location.href)
    return Boolean(
      url.searchParams.get('code') ||
      window.location.hash.includes('error=') ||
      window.location.hash.includes('type=recovery')
    )
  })

  useEffect(() => {
    // Check if we already have an active session from a previous successful code exchange
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        setIsRecovery(true);
      }
    });

    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "PASSWORD_RECOVERY" || session || window.location.hash.includes('type=recovery')) {
        setIsRecovery(true)
      }
    })
    
    const url = new URL(window.location.href);
    const code = url.searchParams.get('code');
    
    if (code) {
      // Exchange the secure PKCE code for a logged-in session
      supabase.auth.exchangeCodeForSession(code).then(({ error }) => {
        if (error) {
          setError("This link has expired or is invalid. Please request a new one from the app.");
        } else {
          // Remove the code from the URL so a refresh doesn't trigger an error
          window.history.replaceState({}, document.title, window.location.pathname);
        }
      });
    }
  }, [])

  const handleUpdatePassword = async (e) => {
    e.preventDefault()
    
    if (password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    setLoading(true)
    setError(null)
    setMessage(null)

    try {
      // Get the user's email to test if the new password matches their current one
      const { data: { user } } = await supabase.auth.getUser()
      
      if (user?.email) {
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email: user.email,
          password: password,
        })
        
        // If signInError is null, the login succeeded, which means the new password is the exact same as their current password!
        if (!signInError) {
          setError('You cannot reuse your current password. Please choose a different one.')
          setLoading(false)
          return
        }
      }

      // If we reach here, the password is new and safe to update
      const { error } = await supabase.auth.updateUser({ password: password })
      
      if (error) {
        throw error
      }
      
      setMessage('Password updated successfully! You can now close this window and log into the PureScan AI mobile app.')
    } catch (err) {
      setError(err.message || 'An error occurred while updating your password.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="page-wrapper">
      {/* Background animated shapes */}
      <div className="shape shape-1"></div>
      <div className="shape shape-2"></div>
      <div className="shape shape-3"></div>

      <div className="container">
        <div className="card fade-in">
          <div className="brand-header">
            <div className="logo-icon">
              <ShieldCheck size={32} color="#012D1D" />
            </div>
            <h1 className="logo-text">PureScan AI</h1>
          </div>

          <div className="content">
            {message ? (
              <div className="success-content slide-up">
                <div className="success-icon-wrapper">
                  <CheckCircle2 size={56} color="#ffffff" />
                </div>
                <h2>Securely Updated</h2>
                <p className="success-message">{message}</p>
              </div>
            ) : (
              <div className="form-container slide-up">
                <h2>Reset Your Password</h2>
                
                {!isRecovery ? (
                  <div className="alert warning-alert">
                    <AlertCircle size={24} className="alert-icon" />
                    <div className="alert-text">
                      <strong>Action Required</strong>
                      <p>Please use the secure link sent to your email to reset your password.</p>
                    </div>
                  </div>
                ) : (
                  <>
                    <p className="subtitle">Enter a strong new password to secure your account.</p>
                    
                    {error && (
                      <div className="alert error-alert animate-shake">
                        <AlertCircle size={20} className="alert-icon" />
                        <span>{error}</span>
                      </div>
                    )}

                    <form onSubmit={handleUpdatePassword}>
                      <div className="input-group">
                        <label htmlFor="password">New Password</label>
                        <div className="input-wrapper">
                          <Lock className="input-icon" size={20} />
                          <input
                            id="password"
                            type={showPassword ? "text" : "password"}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="••••••••"
                            required
                          />
                          <button 
                            type="button" 
                            className="toggle-password"
                            onClick={() => setShowPassword(!showPassword)}
                          >
                            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                          </button>
                        </div>
                      </div>

                      <button 
                        type="submit" 
                        className="submit-button"
                        disabled={loading}
                      >
                        {loading ? (
                          <div className="loader"></div>
                        ) : (
                          'Save Password'
                        )}
                      </button>
                    </form>
                  </>
                )}
              </div>
            )}
          </div>
          <div className="card-footer">
            <p>&copy; {new Date().getFullYear()} PureScan AI. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
