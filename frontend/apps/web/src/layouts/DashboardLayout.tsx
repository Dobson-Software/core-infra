import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { AppShell, Sidebar, TopBar } from '@cobalt/ui';
import type { NavItem } from '@cobalt/ui';
import { useAuth } from '../auth/AuthProvider';
import { useThemeStore } from '../stores/useThemeStore';

const navItems: NavItem[] = [
  { id: 'dashboard', label: 'Dashboard', icon: 'dashboard', path: '/dashboard' },
  { id: 'jobs', label: 'Jobs', icon: 'wrench', path: '/jobs' },
  { id: 'schedule', label: 'Schedule', icon: 'calendar', path: '/schedule' },
  { id: 'customers', label: 'Customers', icon: 'people', path: '/customers' },
  { id: 'invoices', label: 'Invoices', icon: 'dollar', path: '/invoices' },
  { id: 'violations', label: 'Violations', icon: 'warning-sign', path: '/violations' },
  { id: 'settings', label: 'Settings', icon: 'cog', path: '/settings', roles: ['ADMIN'] },
];

export function DashboardLayout() {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const { darkMode, toggleDarkMode } = useThemeStore();

  if (!user) {
    return null;
  }

  return (
    <AppShell
      sidebar={
        <Sidebar
          items={navItems}
          userRole={user.role}
          activePath={location.pathname}
          onNavigate={navigate}
        />
      }
      topbar={
        <TopBar
          userName={`${user.firstName} ${user.lastName}`}
          userRole={user.role}
          darkMode={darkMode}
          onToggleDarkMode={toggleDarkMode}
          onLogout={logout}
        />
      }
    >
      <Outlet />
    </AppShell>
  );
}
