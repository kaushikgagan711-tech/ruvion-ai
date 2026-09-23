/* RUVION local-profile bridge. The browser fallback is intentionally local-only. */
(function (global) {
  const KEY = 'ruvionProfile';
  const id = () => global.crypto?.randomUUID?.() || `ruvion_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const empty = () => ({ profileId: id(), displayName: '', onboardingComplete: false });
  const normalize = (value) => {
    const displayName = typeof value?.displayName === 'string' ? value.displayName.trim().slice(0, 80) : '';
    return { profileId: typeof value?.profileId === 'string' && value.profileId ? value.profileId : id(), displayName, onboardingComplete: Boolean(value?.onboardingComplete && displayName) };
  };
  const invoke = (command, args) => global.__TAURI__?.core?.invoke?.(command, args);
  const nativeProfile = () => normalize(global.RUVION_NATIVE_PROFILE || empty());
  const nativeBridge = () => global.webkit?.messageHandlers?.ruvionProfile;

  class ProfileStore {
    async load() {
      try {
        if (nativeBridge()) return nativeProfile();
        if (global.__TAURI__?.core?.invoke) {
          const stored = await invoke('load_profile');
          return normalize(stored || empty());
        }
        return normalize(JSON.parse(global.localStorage?.getItem(KEY) || 'null') || empty());
      } catch {
        return empty();
      }
    }

    async save(profile) {
      const normalized = normalize({ ...profile, onboardingComplete: true });
      if (!normalized.displayName) throw new Error('A display name is required.');
      // Persist instantly in the preview as well as in the desktop app's app-data file.
      global.localStorage?.setItem(KEY, JSON.stringify(normalized));
      if (nativeBridge()) nativeBridge().postMessage(JSON.stringify(normalized));
      if (global.__TAURI__?.core?.invoke) await invoke('save_profile', { profile: normalized });
      return normalized;
    }
  }

  global.RuvionProfileStore = ProfileStore;
})(globalThis);
