import { Menu, MenuItem, MenuDivider, type IconName } from '@blueprintjs/core';
import type { UserRole } from '@cobalt/api-client';

export interface NavItem {
  id: string;
  label: string;
  icon: IconName;
  path: string;
  roles?: UserRole[];
}

interface SidebarProps {
  items: NavItem[];
  userRole: UserRole;
  activePath: string;
  onNavigate: (path: string) => void;
}

export function Sidebar({ items, userRole, activePath, onNavigate }: SidebarProps) {
  const filteredItems = items.filter((item) => !item.roles || item.roles.includes(userRole));

  return (
    <div style={{ padding: '16px 0' }}>
      <div style={{ padding: '0 16px 16px', fontWeight: 600, fontSize: 18 }}>Cobalt</div>
      <MenuDivider />
      <Menu>
        {filteredItems.map((item) => (
          <MenuItem
            key={item.id}
            icon={item.icon}
            text={item.label}
            active={activePath.startsWith(item.path)}
            onClick={() => onNavigate(item.path)}
          />
        ))}
      </Menu>
    </div>
  );
}
