import { NonIdealState, Button } from '@blueprintjs/core';
import { useNavigate } from 'react-router-dom';

export function NotFoundPage() {
  const navigate = useNavigate();

  return (
    <div
      style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}
    >
      <NonIdealState
        icon="search"
        title="Page Not Found"
        description="The page you are looking for does not exist or has been moved."
        action={
          <Button intent="primary" icon="home" onClick={() => navigate('/')}>
            Go to Home
          </Button>
        }
      />
    </div>
  );
}
