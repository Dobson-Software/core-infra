import { Menu, MenuItem, MenuDivider, Icon } from '@blueprintjs/core';
import { useLocation, useNavigate } from 'react-router-dom';

interface NavItem {
  path: string;
  label: string;
  icon: string;
}

const navItems: NavItem[] = [
  { path: '/', label: 'Dashboard', icon: 'dashboard' },
  { path: '/services', label: 'Service Catalog', icon: 'applications' },
  { path: '/deployments', label: 'Deployments', icon: 'cloud-upload' },
  { path: '/incidents', label: 'Incidents', icon: 'warning-sign' },
  { path: '/costs', label: 'Cost Explorer', icon: 'dollar' },
  { path: '/ai', label: 'AI Console', icon: 'chat' },
];

const adminItems: NavItem[] = [
  { path: '/audit', label: 'Audit Log', icon: 'history' },
  { path: '/settings', label: 'Settings', icon: 'cog' },
];

export function Sidebar() {
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => {
    if (path === '/') return location.pathname === '/';
    return location.pathname.startsWith(path);
  };

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <img src="/solomon.svg" alt="Solomon" />
        <h1>Solomon</h1>
      </div>

      <nav className="sidebar-nav">
        <Menu>
          {navItems.map((item) => (
            <MenuItem
              key={item.path}
              icon={<Icon icon={item.icon as never} />}
              text={item.label}
              active={isActive(item.path)}
              onClick={() => navigate(item.path)}
            />
          ))}

          <MenuDivider title="Administration" />

          {adminItems.map((item) => (
            <MenuItem
              key={item.path}
              icon={<Icon icon={item.icon as never} />}
              text={item.label}
              active={isActive(item.path)}
              onClick={() => navigate(item.path)}
            />
          ))}
        </Menu>
      </nav>
    </aside>
  );
}
