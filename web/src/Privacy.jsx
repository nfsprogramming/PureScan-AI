import { ShieldCheck } from 'lucide-react';
import './App.css';

const Privacy = () => {
  return (
    <div className="page-wrapper" style={{ overflowY: 'auto' }}>
      <div className="shape shape-1"></div>
      <div className="shape shape-2"></div>
      
      <div className="container" style={{ maxWidth: '800px', margin: '40px auto', padding: '20px' }}>
        <div className="card fade-in" style={{ padding: '40px', textAlign: 'left' }}>
          <div className="brand-header" style={{ justifyContent: 'flex-start', marginBottom: '30px' }}>
            <div className="logo-icon">
              <ShieldCheck size={32} color="#012D1D" />
            </div>
            <h1 className="logo-text">PureScan AI</h1>
          </div>
          
          <h2 style={{ color: '#012D1D', marginBottom: '20px', fontSize: '28px' }}>Privacy Policy</h2>
          <p style={{ color: '#414844', marginBottom: '20px' }}>Last updated: June 2026</p>
          
          <div style={{ color: '#0A1128', lineHeight: '1.6' }}>
            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>1. Introduction</h3>
            <p>Welcome to PureScan AI. We respect your privacy and are committed to protecting your personal data and health information. This privacy policy will inform you as to how we look after your personal data when you use our mobile application and tell you about your privacy rights and how the law protects you.</p>
            
            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>2. Data We Collect</h3>
            <p>We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:</p>
            <ul style={{ paddingLeft: '20px', margin: '10px 0' }}>
              <li><strong>Identity Data:</strong> First name, last name, username.</li>
              <li><strong>Health Data:</strong> Dietary preferences, allergens, age, blood type, sugar levels, blood pressure, and related medical profile metrics you explicitly provide.</li>
              <li><strong>Scan Data:</strong> Barcode scans, product analysis history, and OCR data extracted from food labels.</li>
              <li><strong>Contact Data:</strong> Email address and telephone numbers.</li>
            </ul>

            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>3. How We Use Your Data</h3>
            <p>We will only use your personal data when the law allows us to. Most commonly, we will use your personal data in the following circumstances:</p>
            <ul style={{ paddingLeft: '20px', margin: '10px 0' }}>
              <li>To provide you with the PureScan AI service (analyzing food ingredients against your specific health profile).</li>
              <li>To manage your account and family profiles.</li>
              <li>To improve our scanning algorithms and ingredient database accuracy (using anonymized scan data).</li>
            </ul>

            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>4. Data Security</h3>
            <p>We have put in place appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way, altered, or disclosed. Your health data is securely stored in our encrypted database using Row Level Security (RLS) to ensure only you and authorized family members can access it.</p>
            
            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>5. Contact Us</h3>
            <p>If you have any questions about this privacy policy or our privacy practices, please contact our Data Protection Officer at privacy@purescanai.com.</p>
          </div>
          
          <div className="card-footer" style={{ marginTop: '40px', borderTop: '1px solid #eee', paddingTop: '20px' }}>
            <a href="/" style={{ color: '#005F73', textDecoration: 'none', fontWeight: 'bold' }}>&larr; Back to App</a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Privacy;
