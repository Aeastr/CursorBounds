// CursorBounds Helper - Content Script
// Tracks cursor/caret position in web pages and sends to native app

(function() {
  'use strict';

  let lastPosition = null;
  let isTracking = false;

  // Get caret position from current selection
  function getCaretPosition() {
    const selection = window.getSelection();

    if (!selection || selection.rangeCount === 0) {
      return null;
    }

    const range = selection.getRangeAt(0);

    // Check if we're in an editable context
    const activeElement = document.activeElement;
    const isEditable = activeElement && (
      activeElement.isContentEditable ||
      activeElement.tagName === 'INPUT' ||
      activeElement.tagName === 'TEXTAREA'
    );

    if (!isEditable) {
      return null;
    }

    // Get the bounding rect of the caret position
    let rect;

    if (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA') {
      // For input/textarea, we need to create a temporary element to measure
      rect = getInputCaretRect(activeElement);
    } else {
      // For contenteditable, use the range directly
      if (range.collapsed) {
        // Caret (no selection) - get position at insertion point
        rect = getCollapsedRangeRect(range);
      } else {
        // Selection - get bounds of selected text
        rect = range.getBoundingClientRect();
      }
    }

    if (!rect || (rect.width === 0 && rect.height === 0 && rect.x === 0 && rect.y === 0)) {
      return null;
    }

    // Convert to screen coordinates
    const screenX = rect.x + window.screenX;
    const screenY = rect.y + window.screenY;

    return {
      x: screenX,
      y: screenY,
      width: rect.width,
      height: rect.height,
      isSelection: !range.collapsed,
      charOffset: getCharOffset(activeElement, selection)
    };
  }

  // Get rect for collapsed range (caret position)
  function getCollapsedRangeRect(range) {
    // Try to get rect directly
    let rects = range.getClientRects();
    if (rects.length > 0) {
      return rects[0];
    }

    // Fallback: insert a zero-width space and measure it
    const span = document.createElement('span');
    span.textContent = '\u200B'; // Zero-width space

    range.insertNode(span);
    const rect = span.getBoundingClientRect();
    span.parentNode.removeChild(span);

    // Normalize the range after our modification
    range.collapse(true);

    return rect;
  }

  // Get caret rect for input/textarea elements
  function getInputCaretRect(element) {
    const selStart = element.selectionStart;
    const selEnd = element.selectionEnd;

    if (selStart === null) {
      return null;
    }

    // Create a mirror div to measure text
    const mirror = document.createElement('div');
    const computed = window.getComputedStyle(element);

    // Copy styles
    const stylesToCopy = [
      'font-family', 'font-size', 'font-weight', 'font-style',
      'letter-spacing', 'text-transform', 'word-spacing',
      'text-indent', 'padding-left', 'padding-right', 'padding-top', 'padding-bottom',
      'border-left-width', 'border-right-width', 'border-top-width', 'border-bottom-width',
      'box-sizing', 'line-height'
    ];

    stylesToCopy.forEach(style => {
      mirror.style[style] = computed[style];
    });

    mirror.style.position = 'absolute';
    mirror.style.visibility = 'hidden';
    mirror.style.whiteSpace = 'pre-wrap';
    mirror.style.wordWrap = 'break-word';

    if (element.tagName === 'INPUT') {
      mirror.style.whiteSpace = 'pre';
    }

    // Set width for textarea
    if (element.tagName === 'TEXTAREA') {
      mirror.style.width = computed.width;
    }

    // Get text up to caret
    const text = element.value.substring(0, selStart);
    mirror.textContent = text;

    // Add a span for measurement
    const span = document.createElement('span');
    span.textContent = element.value.substring(selStart, selStart + 1) || '.';
    mirror.appendChild(span);

    document.body.appendChild(mirror);

    const inputRect = element.getBoundingClientRect();
    const spanRect = span.getBoundingClientRect();
    const mirrorRect = mirror.getBoundingClientRect();

    document.body.removeChild(mirror);

    // Calculate position relative to input
    const x = inputRect.left + (spanRect.left - mirrorRect.left) - element.scrollLeft;
    const y = inputRect.top + (spanRect.top - mirrorRect.top) - element.scrollTop;

    return {
      x: x,
      y: y,
      width: 1,
      height: parseFloat(computed.lineHeight) || parseFloat(computed.fontSize) * 1.2
    };
  }

  // Get character offset
  function getCharOffset(element, selection) {
    if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
      return element.selectionStart;
    }

    // For contenteditable
    const range = selection.getRangeAt(0);
    const preCaretRange = range.cloneRange();
    preCaretRange.selectNodeContents(element);
    preCaretRange.setEnd(range.endContainer, range.endOffset);
    return preCaretRange.toString().length;
  }

  // Check if position changed significantly
  function positionChanged(newPos) {
    if (!lastPosition || !newPos) return true;

    const threshold = 1;
    return Math.abs(newPos.x - lastPosition.x) > threshold ||
           Math.abs(newPos.y - lastPosition.y) > threshold ||
           newPos.charOffset !== lastPosition.charOffset;
  }

  // Send position to background script
  function sendPosition(position) {
    if (!position) return;

    chrome.runtime.sendMessage({
      type: 'CURSOR_POSITION',
      data: position
    });

    lastPosition = position;
  }

  // Handle selection changes
  function onSelectionChange() {
    if (!isTracking) return;

    const position = getCaretPosition();
    if (position && positionChanged(position)) {
      sendPosition(position);
    }
  }

  // Handle input events (for immediate feedback)
  function onInput(event) {
    if (!isTracking) return;

    // Small delay to let the DOM update
    requestAnimationFrame(() => {
      const position = getCaretPosition();
      if (position) {
        sendPosition(position);
      }
    });
  }

  // Start tracking
  function startTracking() {
    if (isTracking) return;
    isTracking = true;

    document.addEventListener('selectionchange', onSelectionChange);
    document.addEventListener('input', onInput, true);
    document.addEventListener('keyup', onSelectionChange, true);
    document.addEventListener('mouseup', onSelectionChange, true);

    // Send initial position
    const position = getCaretPosition();
    if (position) {
      sendPosition(position);
    }
  }

  // Stop tracking
  function stopTracking() {
    isTracking = false;
    document.removeEventListener('selectionchange', onSelectionChange);
    document.removeEventListener('input', onInput, true);
    document.removeEventListener('keyup', onSelectionChange, true);
    document.removeEventListener('mouseup', onSelectionChange, true);
  }

  // Listen for messages from background script
  chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === 'START_TRACKING') {
      startTracking();
      sendResponse({ success: true });
    } else if (message.type === 'STOP_TRACKING') {
      stopTracking();
      sendResponse({ success: true });
    } else if (message.type === 'GET_POSITION') {
      const position = getCaretPosition();
      sendResponse({ position: position });
    }
    return true;
  });

  // Auto-start tracking
  startTracking();

  console.log('[CursorBounds] Content script loaded');
})();
