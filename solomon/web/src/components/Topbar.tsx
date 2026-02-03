import { Button, Navbar, Popover, Menu, MenuItem, Tag, Icon } from '@blueprintjs/core';
import { useAppStore } from '../stores/useAppStore';

export function Topbar() {
  const { user, setUser } = useAppStore();

  const handleLogout = () => {
    localStorage.removeItem('solomon_token');
    setUser(null);
    window.location.href = '/login';
  };

  return (
    <header className="topbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <Tag intent="success" minimal>
          <Icon icon="tick-circle" size={12} style={{ marginRight: 4 }} />
          All Systems Operational
        </Tag>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Button
          minimal
          icon="notifications"
          aria-label="Notifications"
        />

        <Popover
          content={
            <Menu>
              <MenuItem icon="user" text={user?.name || 'User'} disabled />
              <MenuItem icon="envelope" text={user?.email || ''} disabled />
              <MenuItem icon="log-out" text="Logout" onClick={handleLogout} />
            </Menu>
          }
          placement="bottom-end"
        >
          <Button
            minimal
            icon="user"
            rightIcon="caret-down"
            text={user?.name || 'User'}
          />
        </Popover>
      </div>
    </header>
  );
}
