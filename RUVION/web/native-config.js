/* The desktop app only speaks to this fixed public RUVION API. Never put a Gemini
   or Razorpay key here: those belong exclusively on the HTTPS backend. */
// The signed desktop build uses its local server process. A hosted release can
// replace this with the HTTPS RUVION API without changing the UI or shipping keys.
window.RUVION_API_URL = window.RUVION_API_URL || 'http://127.0.0.1:18766/v1/chat';

// A stable local identifier lets the public API rate-limit a device as well as an
// IP address. It is not a credential and cannot grant an entitlement.
const ruvionFetch = window.fetch.bind(window);
window.fetch = (input, init = {}) => {
  const url = typeof input === 'string' ? input : input?.url || '';
  if (url.startsWith('https://api.ruvion.app/') || url.startsWith('http://127.0.0.1:18766/')) {
    let profileId = window.RUVION_NATIVE_PROFILE?.profileId || '';
    try { profileId ||= JSON.parse(localStorage.getItem('ruvionProfile') || '{}').profileId || ''; } catch (_) {}
    init.headers = { ...(init.headers || {}), 'X-RUVION-Device-ID': profileId };
  }
  return ruvionFetch(input, init);
};
