import select from "select";

/**
 * This script provides clipboard copy functionality to elements like buttons and links.
 * The element to be copied from must be specified using a `data` attribute, and the
 * target element can be a form input, textarea, or any other HTML element containing text.
 *
 * Usage:
 *   1. Create the copy trigger element (button or link):
 *     <button class="button"
 *      data-clipboard-copy="#target-element"
 *      data-clipboard-copy-label="Copied!"
 *      data-clipboard-copy-message="The text was successfully copied to clipboard."
 *      aria-label="Copy the text to clipboard">
 *        <%= icon "clipboard", role: "presentation", "aria-hidden": true %>
 *        Copy to clipboard
 *    </button>
 *    OR
 *    <a href="#" class="copy-link"
 *      data-clipboard-copy="#target-element"
 *      data-clipboard-copy-label="Copied!"
 *      data-clipboard-copy-message="The text was successfully copied to clipboard."
 *      aria-label="Copy the text to clipboard">
 *        <%= icon "clipboard", role: "presentation", "aria-hidden": true %>
 *        Copy link
 *    </a>
 *
 *   2. Ensure the target element exists on the page:
 *     <input id="target-element" type="text" value="This text will be copied.">
 *     OR
 *     <textarea id="target-element">This text will be copied.</textarea>
 *     OR
 *     <div id="target-element">This text will be copied.</div>
 *
 * Options through data attributes:
 * - `data-clipboard-copy` = The jQuery selector for the target element (input, textarea, or any HTML element)
 *   from which text will be copied. If this element does not contain any visible text
 *   (for example, an image), this selector will be used to place the confirmation message.
 * - `data-clipboard-content` = The specific text that will be copied. If this attribute is empty or not provided,
 *   the inner text or value of the target input/element will be used instead.
 * - `data-clipboard-copy-label` = The temporary label that will be shown in the copy trigger element
 *   (button or link) after a successful copy operation.
 * - `data-clipboard-copy-message` = The text message that will be announced to screen readers after a successful copy.
 *
 * The script supports:
 * - Copying text from an input or textarea using a selection.
 * - Copying text from any other element by grabbing its inner text.
 * - Temporarily changing the label of the copy button or target element to indicate success.
 * - Announcing success messages to screen readers.
 *
 * Note: If the target is an input or textarea, it will not replace its value with the success label;
 * the success label appears in the button or link text only.
 */

const CLIPBOARD_COPY_TIMEOUT = 5000;

const getSelectedText = ($el, $input) => {
  // Get the text to be copied. If 'data-clipboard-content' is not specified,
  // use the content of the target element.
  let selectedText = $el.data("clipboard-content") || "";

  if (selectedText === "" && $input.length > 0) {
    if ($input.is("input, textarea, select")) {
      // If the target is an input, textarea, or select, use select library to get text.
      selectedText = select($input[0]);
    } else {
      // If the target is any other element, use its text.
      selectedText = $input.text();
    }
  }

  return selectedText;
};

const performCopy = (selectedText, $el) => {
  // Move the selected text to clipboard.
  const $temp = $(`<textarea>${selectedText}</textarea>`).css({
    width: 1,
    height: 1
  });
  $el.after($temp);
  $temp.select();

  const copyDone = () => {
    $temp.remove();
    $el.focus();
  };

  try {
    if (!document.execCommand("copy")) {
      return false;
    }
  } catch (err) {
    copyDone();
    return false;
  }

  copyDone();
  return true;
};

const updateLabel = ($el, $input, label) => {
  if (label) {
    let to = $el.data("clipboard-copy-label-timeout");
    if (to) {
      clearTimeout(to);
    }

    if (!$el.data("clipboard-copy-label-original")) {
      $el.data("clipboard-copy-label-original", $el.html());
    }

    // Temporarily change the element's text
    $el.html(label);

    // Restore the original text after a timeout
    to = setTimeout(() => {
      $el.html($el.data("clipboard-copy-label-original"));
      $el.removeData("clipboard-copy-label-original");
      $el.removeData("clipboard-copy-label-timeout");
    }, CLIPBOARD_COPY_TIMEOUT);

    $el.data("clipboard-copy-label-timeout", to);
  }
};

const announceToScreenReader = ($el, message) => {
  let announcementMessage = message;

  if (announcementMessage) {
    let $msg = $el.data("clipboard-message-element");
    if ($msg) {
      if ($msg.html() === message) {
        // Try to hint the screen reader to re-read the text in the message element.
        announcementMessage += "&nbsp;";
      }
    } else {
      $msg = $('<div aria-role="alert" aria-live="assertive" aria-atomic="true" class="sr-only"></div>');
      $el.after($msg);
      $el.data("clipboard-message-element", $msg);
    }

    // Add the non-breaking space always to content to try to force the screen reader to reannounce the added text.
    $msg.html(announcementMessage);
  }
};

$(() => {
  $(document).on("click", "[data-clipboard-copy]", (ev) => {
    const $el = $(ev.currentTarget);

    if (!$el.data("clipboard-copy") || $el.data("clipboard-copy").length < 1) {
      return;
    }

    const $input = $($el.data("clipboard-copy"));

    const selectedText = getSelectedText($el, $input);

    if (!selectedText || selectedText.length < 1) {
      return;
    }

    const copySuccess = performCopy(selectedText, $el);

    if (!copySuccess) {
      return;
    }

    const label = $el.data("clipboard-copy-label");

    if ($el.is("button")) {
      updateLabel($el, $el, label);
    } else if ($el.is("a") && $input.length > 0) {
      updateLabel($input, $input, label);
    }

    const message = $el.data("clipboard-copy-message");
    announceToScreenReader($el, message);
  });
});
