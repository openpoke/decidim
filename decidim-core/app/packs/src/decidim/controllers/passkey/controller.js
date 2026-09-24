import { Controller } from "@hotwired/stimulus"

const base64UrlToBuffer = (value) => {
  const base64 = value.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (base64.length % 4)) % 4);
  const binary = window.atob(`${base64}${padding}`);

  return Uint8Array.from(binary, (character) => character.charCodeAt(0)).buffer;
};

const bufferToBase64Url = (buffer) => {
  const binary = Array.from(new Uint8Array(buffer), (byte) => String.fromCharCode(byte)).join("");

  return window.btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/[=]+$/, "");
};

const decodedCreationOptions = (options) => ({
  ...options,
  challenge: base64UrlToBuffer(options.challenge),
  user: { ...options.user, id: base64UrlToBuffer(options.user.id) },
  excludeCredentials: (options.excludeCredentials || []).map((credential) => ({ ...credential, id: base64UrlToBuffer(credential.id) }))
});

const decodedRequestOptions = (options) => ({
  ...options,
  challenge: base64UrlToBuffer(options.challenge),
  allowCredentials: (options.allowCredentials || []).map((credential) => ({ ...credential, id: base64UrlToBuffer(credential.id) }))
});

const credentialPayload = (credential, response) => ({
  type: credential.type,
  id: credential.id,
  rawId: bufferToBase64Url(credential.rawId),
  response
});

const registrationPayload = (credential) => credentialPayload(credential, {
  attestationObject: bufferToBase64Url(credential.response.attestationObject),
  clientDataJSON: bufferToBase64Url(credential.response.clientDataJSON)
});

const assertionPayload = (credential) => credentialPayload(credential, {
  clientDataJSON: bufferToBase64Url(credential.response.clientDataJSON),
  authenticatorData: bufferToBase64Url(credential.response.authenticatorData),
  signature: bufferToBase64Url(credential.response.signature),
  userHandle: credential.response.userHandle
    ? bufferToBase64Url(credential.response.userHandle)
    : null
});

/**
 * Runs the WebAuthn ceremony of a passkey form: the options come from the
 * options value and the credential the browser returns goes back in the
 * credential target before the form is submitted.
 *
 * Example:
 *
 *   <form data-controller="passkey" data-passkey-ceremony-value="registration" data-passkey-options-value="{...}" data-action="submit->passkey#submit">
 *     <p data-passkey-target="unsupported" hidden>...</p>
 *     <p data-passkey-target="duplicate" hidden>...</p>
 *     <p data-passkey-target="error" hidden>...</p>
 *     <input type="hidden" name="credential" data-passkey-target="credential">
 *     <input type="submit" data-passkey-target="submit">
 *   </form>
 */
export default class extends Controller {
  static get targets() {
    return ["credential", "submit", "unsupported", "duplicate", "error"];
  }

  static get values() {
    return {
      ceremony: String,
      options: Object
    };
  }

  connect() {
    if (window.PublicKeyCredential) {
      return;
    }

    this.unsupportedTarget.hidden = false;
    this.submitTarget.disabled = true;
  }

  submit(event) {
    event.preventDefault();
    this.hideMessages();
    this.submitTarget.disabled = true;

    this.runCeremony().then((payload) => {
      this.credentialTarget.value = JSON.stringify(payload);
      this.element.submit();
    }).catch((error) => {
      this.submitTarget.disabled = false;
      this.showMessage(error);
    });
  }

  async runCeremony() {
    if (this.ceremonyValue === "registration") {
      const credential = await navigator.credentials.create({ publicKey: decodedCreationOptions(this.optionsValue) });

      return registrationPayload(credential);
    }

    const credential = await navigator.credentials.get({ publicKey: decodedRequestOptions(this.optionsValue) });

    return assertionPayload(credential);
  }

  hideMessages() {
    this.errorTarget.hidden = true;
    if (this.hasDuplicateTarget) {
      this.duplicateTarget.hidden = true;
    }
  }

  showMessage(error) {
    if (error.name === "InvalidStateError" && this.hasDuplicateTarget) {
      this.duplicateTarget.hidden = false;
    } else {
      this.errorTarget.hidden = false;
    }
  }
}
