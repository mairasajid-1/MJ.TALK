'use client';

import { AlertTriangle, Database, Key, ExternalLink } from 'lucide-react';

export function SetupRequired() {
  const envVars = [
    { name: 'NEXT_PUBLIC_SUPABASE_URL', description: 'Project URL' },
    { name: 'NEXT_PUBLIC_SUPABASE_ANON_KEY', description: 'Anonymous Key' },
    { name: 'SUPABASE_SERVICE_ROLE_KEY', description: 'Service Role Key' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
      <div className="max-w-2xl w-full bg-white rounded-lg shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="bg-amber-500 p-6 text-white">
          <div className="flex items-center space-x-3">
            <AlertTriangle className="h-8 w-8" />
            <div>
              <h1 className="text-2xl font-bold">Setup Required</h1>
              <p className="text-amber-100">Configure Supabase to continue</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-800">
              <strong>Missing Supabase Configuration:</strong> The application cannot start without proper database credentials.
            </p>
          </div>

          <div>
            <h2 className="text-lg font-semibold mb-3 flex items-center">
              <Database className="h-5 w-5 mr-2 text-green-600" />
              Step 1: Get Supabase Credentials
            </h2>
            <ol className="space-y-2 text-sm">
              <li>1. Go to <a href="https://app.supabase.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline inline-flex items-center">Supabase Dashboard <ExternalLink className="h-3 w-3 ml-1" /></a></li>
              <li>2. Select your project (or create a new one)</li>
              <li>3. Navigate to <strong>Settings → API</strong></li>
              <li>4. Copy the Project URL and API Keys</li>
            </ol>
          </div>

          <div>
            <h2 className="text-lg font-semibold mb-3 flex items-center">
              <Key className="h-5 w-5 mr-2 text-blue-600" />
              Step 2: Update .env.local
            </h2>
            <p className="text-sm text-gray-600 mb-3">Replace the placeholder values with your actual credentials:</p>
            
            <div className="bg-gray-900 rounded-lg p-4 text-green-400 font-mono text-sm space-y-1">
              {envVars.map((envVar) => (
                <div key={envVar.name}>
                  <span className="text-gray-500"># {envVar.description}</span><br />
                  <span className="text-yellow-400">{envVar.name}</span>=<span className="text-white">your_actual_value_here</span>
                </div>
              ))}
            </div>
          </div>

          <div>
            <h2 className="text-lg font-semibold mb-3">Step 3: Apply Database Schema</h2>
            <p className="text-sm text-gray-600 mb-2">Run these migration files in Supabase Dashboard → SQL Editor:</p>
            <ul className="text-sm space-y-1">
              <li>• <code>001_phase1_enhanced_schema.sql</code></li>
              <li>• <code>002_phase3_realtime.sql</code></li>
              <li>• <code>003_phase5_ai_hybrid.sql</code></li>
              <li>• <code>004_phase8_rbac.sql</code></li>
              <li>• <code>005_fix_realtime_rls.sql</code></li>
              <li className="font-semibold text-red-600">• <code>007_fix_rls_recursion.sql</code> ⚠️ <strong>Important!</strong></li>
            </ul>
          </div>

          <div>
            <h2 className="text-lg font-semibold mb-3">Step 4: Restart Server</h2>
            <div className="bg-gray-100 rounded p-3 font-mono text-sm">
              npm run dev
            </div>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-blue-800 text-sm">
              <strong>💡 Tip:</strong> See <code>SETUP.md</code> for detailed instructions and troubleshooting.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}