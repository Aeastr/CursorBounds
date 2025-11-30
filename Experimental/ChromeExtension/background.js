// CursorBounds Helper - Background Service Worker
// Bridges content scripts with native messaging host

const NATIVE_HOST_NAME = 'com.cursorbounds.helper';

let nativePort = null;
let lastPosition = null;

// Connect to native messaging host
function connectNative() {
  if (nativePort) {
    return;
  }

  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);

    nativePort.onMessage.addListener((message) => {
      console.log('[CursorBounds] Native message:', message);

      if (message.type === 'REQUEST_POSITION') {
        // Native app is requesting current position
        if (lastPosition) {
          nativePort.postMessage({
            type: 'CURSOR_POSITION',
            data: lastPosition
          });
        }
      }
    });

    nativePort.onDisconnect.addListener(() => {
      console.log('[CursorBounds] Native port disconnected');
      if (chrome.runtime.lastError) {
        console.error('[CursorBounds] Disconnect error:', chrome.runtime.lastError.message);
      }
      nativePort = null;
    });

    console.log('[CursorBounds] Connected to native host');
  } catch (error) {
    console.error('[CursorBounds] Failed to connect to native host:', error);
  }
}

// Send position to native host
function sendToNative(position) {
  if (!nativePort) {
    connectNative();
  }

  if (nativePort && position) {
    try {
      nativePort.postMessage({
        type: 'CURSOR_POSITION',
        data: position
      });
    } catch (error) {
      console.error('[CursorBounds] Failed to send to native:', error);
      nativePort = null;
    }
  }
}

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'CURSOR_POSITION') {
    lastPosition = {
      ...message.data,
      tabId: sender.tab?.id,
      url: sender.tab?.url,
      timestamp: Date.now()
    };

    // Forward to native host
    sendToNative(lastPosition);

    sendResponse({ received: true });
  }
  return true;
});

// Handle external connections (from native apps via extension ID)
chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  if (message.type === 'GET_POSITION') {
    sendResponse({ position: lastPosition });
  } else if (message.type === 'CONNECT') {
    connectNative();
    sendResponse({ connected: !!nativePort });
  }
  return true;
});

// Try to connect on startup
connectNative();

console.log('[CursorBounds] Background service worker started');
