import { useEffect, useRef, useCallback, useState } from 'react';
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { WebLinksAddon } from 'xterm-addon-web-links';
import { Button, Tag, Icon, Callout } from '@blueprintjs/core';
import { createAIWebSocket } from '../api';

interface AITerminalProps {
  sessionId: string;
  onSessionEnd?: () => void;
}

interface PendingAction {
  id: string;
  toolName: string;
  input: Record<string, unknown>;
}

export function AITerminal({ sessionId, onSessionEnd }: AITerminalProps) {
  const terminalRef = useRef<HTMLDivElement>(null);
  const terminal = useRef<Terminal | null>(null);
  const fitAddon = useRef<FitAddon | null>(null);
  const ws = useRef<WebSocket | null>(null);
  const inputBuffer = useRef('');
  const [isConnected, setIsConnected] = useState(false);
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);

  const handleApprove = useCallback(() => {
    if (ws.current && pendingAction) {
      ws.current.send(
        JSON.stringify({ type: 'approve', actionId: pendingAction.id })
      );
      setPendingAction(null);
    }
  }, [pendingAction]);

  const handleReject = useCallback(() => {
    if (ws.current && pendingAction) {
      ws.current.send(
        JSON.stringify({ type: 'reject', actionId: pendingAction.id })
      );
      setPendingAction(null);
    }
  }, [pendingAction]);

  useEffect(() => {
    if (!terminalRef.current) return;

    // Initialize terminal
    terminal.current = new Terminal({
      fontFamily: 'JetBrains Mono, Consolas, monospace',
      fontSize: 14,
      theme: {
        background: '#0d1117',
        foreground: '#c9d1d9',
        cursor: '#6366f1',
        cursorAccent: '#0d1117',
        selectionBackground: '#264f78',
        black: '#484f58',
        red: '#ff7b72',
        green: '#3fb950',
        yellow: '#d29922',
        blue: '#6366f1',
        magenta: '#a855f7',
        cyan: '#58a6ff',
        white: '#c9d1d9',
        brightBlack: '#6e7681',
        brightRed: '#ffa198',
        brightGreen: '#56d364',
        brightYellow: '#e3b341',
        brightBlue: '#8b5cf6',
        brightMagenta: '#d946ef',
        brightCyan: '#79c0ff',
        brightWhite: '#f0f6fc',
      },
    });

    fitAddon.current = new FitAddon();
    terminal.current.loadAddon(fitAddon.current);
    terminal.current.loadAddon(new WebLinksAddon());

    terminal.current.open(terminalRef.current);
    fitAddon.current.fit();

    // Welcome message
    terminal.current.writeln('\x1b[1;35m╔════════════════════════════════════════╗\x1b[0m');
    terminal.current.writeln('\x1b[1;35m║     Solomon AI Console                 ║\x1b[0m');
    terminal.current.writeln('\x1b[1;35m║     Powered by Claude                  ║\x1b[0m');
    terminal.current.writeln('\x1b[1;35m╚════════════════════════════════════════╝\x1b[0m');
    terminal.current.writeln('');
    terminal.current.writeln('\x1b[90mConnecting to session...\x1b[0m');
    terminal.current.writeln('');

    // Connect WebSocket
    ws.current = createAIWebSocket(sessionId);

    ws.current.onopen = () => {
      setIsConnected(true);
      terminal.current?.writeln('\x1b[32m✓ Connected\x1b[0m');
      terminal.current?.writeln('');
      terminal.current?.write('\x1b[36msolomon>\x1b[0m ');
    };

    ws.current.onmessage = (event) => {
      const message = JSON.parse(event.data);

      switch (message.type) {
        case 'text':
          terminal.current?.write(message.content);
          break;

        case 'tool_call':
          terminal.current?.writeln('');
          terminal.current?.writeln(
            `\x1b[33m⚙ Tool: ${message.toolName}\x1b[0m`
          );
          if (message.requiresApproval) {
            setPendingAction({
              id: message.actionId,
              toolName: message.toolName,
              input: message.input,
            });
          }
          break;

        case 'tool_result':
          terminal.current?.writeln(
            `\x1b[32m✓ ${message.toolName} completed\x1b[0m`
          );
          break;

        case 'error':
          terminal.current?.writeln(`\x1b[31m✗ Error: ${message.message}\x1b[0m`);
          break;

        case 'end':
          terminal.current?.writeln('');
          terminal.current?.writeln('\x1b[90mSession ended.\x1b[0m');
          onSessionEnd?.();
          break;

        case 'prompt':
          terminal.current?.writeln('');
          terminal.current?.write('\x1b[36msolomon>\x1b[0m ');
          break;
      }
    };

    ws.current.onclose = () => {
      setIsConnected(false);
      terminal.current?.writeln('');
      terminal.current?.writeln('\x1b[31m✗ Disconnected\x1b[0m');
    };

    ws.current.onerror = () => {
      terminal.current?.writeln('\x1b[31m✗ Connection error\x1b[0m');
    };

    // Handle user input
    terminal.current.onData((data) => {
      if (!ws.current || ws.current.readyState !== WebSocket.OPEN) return;

      if (data === '\r') {
        // Enter key
        terminal.current?.writeln('');
        if (inputBuffer.current.trim()) {
          ws.current.send(
            JSON.stringify({
              type: 'message',
              content: inputBuffer.current,
            })
          );
        }
        inputBuffer.current = '';
      } else if (data === '\x7f') {
        // Backspace
        if (inputBuffer.current.length > 0) {
          inputBuffer.current = inputBuffer.current.slice(0, -1);
          terminal.current?.write('\b \b');
        }
      } else if (data >= ' ' && data <= '~') {
        // Printable characters
        inputBuffer.current += data;
        terminal.current?.write(data);
      }
    });

    // Handle resize
    const handleResize = () => fitAddon.current?.fit();
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      ws.current?.close();
      terminal.current?.dispose();
    };
  }, [sessionId, onSessionEnd]);

  return (
    <div className="terminal-container">
      <div className="terminal-header">
        <div className="session-info">
          <Icon icon="console" />
          <span>Session: {sessionId.slice(0, 8)}</span>
          <Tag intent={isConnected ? 'success' : 'danger'} minimal>
            {isConnected ? 'Connected' : 'Disconnected'}
          </Tag>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Button small minimal icon="clipboard" text="Copy" />
          <Button small minimal icon="cross" text="End Session" />
        </div>
      </div>

      {pendingAction && (
        <Callout intent="warning" style={{ margin: 8, borderRadius: 4 }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <div>
              <strong>Action requires approval:</strong>{' '}
              {pendingAction.toolName}
              <pre
                style={{
                  margin: '8px 0 0',
                  fontSize: 12,
                  maxHeight: 100,
                  overflow: 'auto',
                }}
              >
                {JSON.stringify(pendingAction.input, null, 2)}
              </pre>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <Button intent="success" text="Approve" onClick={handleApprove} />
              <Button intent="danger" text="Reject" onClick={handleReject} />
            </div>
          </div>
        </Callout>
      )}

      <div className="terminal-body" ref={terminalRef} />
    </div>
  );
}
