import { ShieldCheck } from 'lucide-react';
import './App.css';

const Terms = () => {
  return (
    <div className="page-wrapper" style={{ overflowY: 'auto' }}>
      <div className="shape shape-3"></div>
      
      <div className="container" style={{ maxWidth: '800px', margin: '40px auto', padding: '20px' }}>
        <div className="card fade-in" style={{ padding: '40px', textAlign: 'left' }}>
          <div className="brand-header" style={{ justifyContent: 'flex-start', marginBottom: '30px' }}>
            <div className="logo-icon">
              <ShieldCheck size={32} color="#012D1D" />
            </div>
            <h1 className="logo-text">PureScan AI</h1>
          </div>
          
          <h2 style={{ color: '#012D1D', marginBottom: '20px', fontSize: '28px' }}>Terms of Service</h2>
          <p style={{ color: '#414844', marginBottom: '20px' }}>Last updated: June 2026</p>
          
          <div style={{ color: '#0A1128', lineHeight: '1.6' }}>
            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>1. Agreement to Terms</h3>
            <p>By accessing or using the PureScan AI mobile application, you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the service.</p>
            
            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>2. Medical Disclaimer</h3>
            <div className="alert warning-alert" style={{ margin: '15px 0' }}>
              <strong>Not Medical Advice</strong>
              <p>PureScan AI is an informational tool designed to assist with identifying ingredients. It does NOT provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider for medical conditions or severe allergies.</p>
            </div>

            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>3. User Accounts</h3>
            <p>When you create an account with us, you must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account on our Service.</p>
            <p>You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.</p>

            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>4. Accuracy of Information</h3>
            <p>While we strive to keep our food ingredient database as accurate and up-to-date as possible, manufacturers frequently change product formulas. We do not warrant that product descriptions, ingredients, or other content is accurate, complete, reliable, current, or error-free. Always read the physical label on the product before consumption.</p>

            <h3 style={{ marginTop: '24px', marginBottom: '12px' }}>5. Limitation of Liability</h3>
            <p>In no event shall PureScan AI, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service; including any physical harm resulting from undeclared allergens or incorrect product information.</p>
          </div>
          
          <div className="card-footer" style={{ marginTop: '40px', borderTop: '1px solid #eee', paddingTop: '20px' }}>
            <a href="/" style={{ color: '#005F73', textDecoration: 'none', fontWeight: 'bold' }}>&larr; Back to App</a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Terms;
