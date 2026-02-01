import { Spinner, SpinnerSize } from '@blueprintjs/core';

export function FullPageSpinner() {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
      }}
    >
      <Spinner size={SpinnerSize.LARGE} />
    </div>
  );
}
