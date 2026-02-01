import type { ReactNode } from 'react';

interface AppShellProps {
  sidebar: ReactNode;
  topbar: ReactNode;
  children: ReactNode;
}

export function AppShell({ sidebar, topbar, children }: AppShellProps) {
  return (
    <div style={{ display: 'flex', height: '100vh' }}>
      <aside
        style={{
          width: 240,
          flexShrink: 0,
          borderRight: '1px solid var(--bp5-divider-black)',
        }}
      >
        {sidebar}
      </aside>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <header>{topbar}</header>
        <main style={{ flex: 1, overflow: 'auto', padding: 20 }}>{children}</main>
      </div>
    </div>
  );
}
