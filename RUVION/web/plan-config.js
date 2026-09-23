/* The one place RUVION defines product entitlements and their UI language. */
(function (global) {
  global.RUVION_PLAN_CONFIG = Object.freeze({
    free: Object.freeze({
      id: 'free', label: 'Free', sidebarLabel: 'Free plan', price: '₹0', description: 'RUVION Normal plus starter task completion.',
      features: ['500 chat messages per day', 'Unlimited Work for 2 days', '5 image/video/file credits per day', 'Unused media credits roll forward'], action: 'Current Plan', workMode: 'Starter'
    }),
    plus: Object.freeze({
      id: 'plus', label: 'RUVION Plus', sidebarLabel: 'RUVION Plus', price: '₹0 for 6 months', description: 'Free for everyone for six months; optional ₹499/month afterward.',
      features: ['1,000 chat messages per day', 'Unlimited Work for 10 days', '10 image/video/file credits per day', 'Unused media credits roll forward'], action: 'Upgrade to Plus', workMode: 'Plus'
    }),
    student_pro: Object.freeze({
      id: 'student_pro', label: 'Student Plus', sidebarLabel: 'Student Plus', price: '₹0 for 6 months', description: 'Included in the universal six-month Plus and Pro trial. No verification required.',
      features: ['Included in the universal six-month trial', 'No student upload required', 'Optional upgrade after the trial'], action: 'Included', futureOnly: true, workMode: 'Plus'
    }),
    pro: Object.freeze({
      id: 'pro', label: 'RUVION Pro', sidebarLabel: 'RUVION Pro', price: '₹0 for 6 months', description: 'Pro is free for everyone for six months; optional ₹1,499/month afterward.',
      features: ['10,000 chat messages per day', 'Unlimited Work for 50 days', '25 image/video/file credits per day', 'Unused media credits roll forward'], action: 'Upgrade to Pro', workMode: 'Pro'
    })
  });
})(globalThis);
