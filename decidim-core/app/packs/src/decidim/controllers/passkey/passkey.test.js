/* global jest */
import { Application } from "@hotwired/stimulus"
import PasskeyController from "src/decidim/controllers/passkey/controller";

describe("PasskeyController", () => {
  const nextTick = () => new Promise((resolve) => setTimeout(resolve, 0));
  const bytes = Uint8Array.from([1, 2, 3]).buffer;
  const options = { challenge: "AQID", user: { id: "AQID", name: "user@example.org" }, excludeCredentials: [{ type: "public-key", id: "AQID" }] };
  let application = null;
  let form = null;
  let credentialField = null;
  let submitButton = null;

  const render = (ceremony) => {
    document.body.innerHTML = `
      <form data-controller="passkey" data-passkey-ceremony-value="${ceremony}" data-passkey-options-value='${JSON.stringify(options)}' data-action="submit->passkey#submit">
        <p data-passkey-target="unsupported" hidden>Unsupported</p>
        <p data-passkey-target="duplicate" hidden>Duplicate</p>
        <p data-passkey-target="error" hidden>Error</p>
        <input type="hidden" name="credential" data-passkey-target="credential">
        <input type="submit" data-passkey-target="submit">
      </form>
    `;
    form = document.querySelector("form");
    credentialField = form.querySelector("[name='credential']");
    submitButton = form.querySelector("[type='submit']");
  };

  const submit = async () => {
    const event = new Event("submit", { bubbles: true, cancelable: true });
    form.dispatchEvent(event);
    await nextTick();

    return event;
  };

  beforeEach(() => {
    window.PublicKeyCredential = () => {};
    Reflect.defineProperty(window.navigator, "credentials", { value: { create: jest.fn(), get: jest.fn() }, configurable: true });
    HTMLFormElement.prototype.submit = jest.fn();
    application = Application.start();
    application.register("passkey", PasskeyController);
  });

  afterEach(() => {
    application.stop();
    document.body.innerHTML = "";
  });

  it("disables the form when the browser has no WebAuthn", async () => {
    Reflect.deleteProperty(window, "PublicKeyCredential");
    render("registration");
    await nextTick();

    expect(form.querySelector("[data-passkey-target='unsupported']").hidden).toBe(false);
    expect(submitButton.disabled).toBe(true);
  });

  it("registers a passkey and submits the encoded credential", async () => {
    render("registration");
    await nextTick();
    navigator.credentials.create.mockResolvedValue({ type: "public-key", id: "AQID", rawId: bytes, response: { attestationObject: bytes, clientDataJSON: bytes } });

    const event = await submit();

    expect(event.defaultPrevented).toBe(true);
    const publicKey = navigator.credentials.create.mock.calls[0][0].publicKey;
    expect(Array.from(new Uint8Array(publicKey.challenge))).toEqual([1, 2, 3]);
    expect(Array.from(new Uint8Array(publicKey.excludeCredentials[0].id))).toEqual([1, 2, 3]);
    expect(JSON.parse(credentialField.value)).toEqual({ type: "public-key", id: "AQID", rawId: "AQID", response: { attestationObject: "AQID", clientDataJSON: "AQID" } });
    expect(HTMLFormElement.prototype.submit).toHaveBeenCalled();
  });

  it("asserts a passkey with the stored credentials", async () => {
    render("authentication");
    await nextTick();
    navigator.credentials.get.mockResolvedValue({ type: "public-key", id: "AQID", rawId: bytes, response: { clientDataJSON: bytes, authenticatorData: bytes, signature: bytes, userHandle: null } });

    await submit();

    expect(navigator.credentials.get).toHaveBeenCalled();
    expect(JSON.parse(credentialField.value).response).toEqual({ clientDataJSON: "AQID", authenticatorData: "AQID", signature: "AQID", userHandle: null });
  });

  it("tells the user when the passkey is already registered", async () => {
    render("registration");
    await nextTick();
    navigator.credentials.create.mockRejectedValue(Object.assign(new Error("exists"), { name: "InvalidStateError" }));

    await submit();

    expect(form.querySelector("[data-passkey-target='duplicate']").hidden).toBe(false);
    expect(submitButton.disabled).toBe(false);
    expect(HTMLFormElement.prototype.submit).not.toHaveBeenCalled();
  });

  it("shows the error when the ceremony is cancelled", async () => {
    render("authentication");
    await nextTick();
    navigator.credentials.get.mockRejectedValue(new Error("cancelled"));

    await submit();

    expect(form.querySelector("[data-passkey-target='error']").hidden).toBe(false);
    expect(submitButton.disabled).toBe(false);
  });

  it("lets the form through once the credential is filled in", async () => {
    render("registration");
    await nextTick();
    credentialField.value = "{}";

    const event = await submit();

    expect(event.defaultPrevented).toBe(false);
    expect(navigator.credentials.create).not.toHaveBeenCalled();
  });
});
