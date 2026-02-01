import { Navbar, Button, Alignment } from '@blueprintjs/core';

interface TopBarProps {
  userName: string;
  userRole: string;
  darkMode: boolean;
  onToggleDarkMode: () => void;
  onLogout: () => void;
}

export function TopBar({ userName, userRole, darkMode, onToggleDarkMode, onLogout }: TopBarProps) {
  return (
    <Navbar>
      <Navbar.Group align={Alignment.LEFT}>
        <Navbar.Heading>Cobalt Platform</Navbar.Heading>
      </Navbar.Group>
      <Navbar.Group align={Alignment.RIGHT}>
        <span className="bp5-text-muted" style={{ marginRight: 12 }}>
          {userName} ({userRole})
        </span>
        <Button minimal icon={darkMode ? 'flash' : 'moon'} onClick={onToggleDarkMode} />
        <Navbar.Divider />
        <Button minimal icon="log-out" text="Logout" onClick={onLogout} />
      </Navbar.Group>
    </Navbar>
  );
}
