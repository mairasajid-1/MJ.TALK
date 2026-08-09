'use client';

import { useEffect, useState } from 'react';
import { AlertTriangle, CheckCircle, XCircle, RefreshCw } from 'lucide-react';

interface StatusChecks {
  environment: string;
  supabase: string;
  timestamp: string;
  [key: string]: string;
}

export default function ConfigDebugPage() {
  const [status, setStatus] = useState<StatusChecks | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const checkStatus = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/status');
      const data = await response.json();
      setStatus(data.checks);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch status');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    checkStatus();
  }, []);

  const getIcon = (check: string) => {
    if (check === 'OK') {
      return <CheckCircle className="w-5 h-5 text-green-600" />;
    } else if (check.startsWith('ERROR') || check.startsWith('MISSING') || check.startsWith('PLACEHOLDER') || check.startsWith('CONFIG_ERROR')) {
      return <XCircle className="w-5 h-5 text-red-600" />;
    } else {
      return <AlertTriangle className="w-5 h-5 text-yellow-600" />;
    }
  };

  const getColor = (check: string) => {
    if (check === 'OK') return 'bg-green-50 border-green-200';
    if (check.startsWith('ERROR') || check.startsWith('MISSING') || check.startsWith('PLACEHOLDER') || check.startsWith('CONFIG_ERROR')) {
      return 'bg-red-50 border-red-200';
    }
    return 'bg-yellow-50 border-yellow-200';
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-6">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Configuration Debug</h1>
          <p className="text-gray-400">Check if your Supabase is properly configured</p>
        </div>

        {/* Status Card */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          {/* Controls */}
          <div className="p-6 border-b border-gray-200 flex justify-between items-center">
            <h2 className="text-lg font-semibold">System Status</h2>
            <button
              onClick={checkStatus}
              disabled={loading}
              className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              <span>Refresh</span>
            </button>
          </div>

          {/* Content */}
          <div className="p-6 space-y-4">
            {loading && !status ? (
              <div className="flex items-center justify-center py-8">
                <div className="animate-spin">
                  <RefreshCw className="w-6 h-6 text-blue-600" />
                </div>
              </div>
            ) : error ? (
              <div className="bg-red-50 border border-red-200 rounded p-4">
                <p className="text-red-800">
                  <strong>Error:</strong> {error}
                </p>
              </div>
            ) : status ? (
              <>
                {/* Checks */}
                {Object.entries(status)
                  .filter(([key]) => key !== 'timestamp')
                  .map(([key, value]) => (
                    <div
                      key={key}
                      className={`border rounded-lg p-4 flex items-start space-x-3 ${getColor(value as string)}`}
                    >
                      <div className="mt-0.5">{getIcon(value as string)}</div>
                      <div className="flex-1">
                        <div className="font-semibold text-gray-900 capitalize">
                          {key.replace(/_/g, ' ')}
                        </div>
                        <div className="text-sm text-gray-700 mt-1">{value}</div>
                      </div>
                    </div>
                  ))}

                {/* Timestamp */}
                <div className="text-xs text-gray-500 text-right mt-4">
                  Last checked: {status.timestamp}
                </div>
              </>
            ) : null}
          </div>
        </div>

        {/* Quick Fix Guide */}
        <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
          <h3 className="text-lg font-semibold mb-4">Quick Setup Guide</h3>

          <div className="space-y-4 text-sm">
            <div>
              <h4 className="font-semibold text-gray-900 mb-2">1. Get Supabase Credentials</h4>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                <li>Go to <a href="https://app.supabase.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">supabase.com</a></li>
                <li>Select your project → Settings → API</li>
                <li>Copy Project URL and API Keys</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-gray-900 mb-2">2. Update .env.local</h4>
              <div className="bg-gray-100 rounded p-3 font-mono text-xs overflow-x-auto">
                <div>NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co</div>
                <div>NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...</div>
                <div>SUPABASE_SERVICE_ROLE_KEY=eyJ...</div>
              </div>
            </div>

            <div>
              <h4 className="font-semibold text-gray-900 mb-2">3. Restart Server</h4>
              <p className="text-gray-700">Stop and restart your development server after updating .env.local</p>
            </div>
          </div>
        </div>

        {/* Info */}
        <div className="text-center mt-8 text-gray-400 text-sm">
          <p>See SETUP.md for detailed instructions</p>
        </div>
      </div>
    </div>
  );
}