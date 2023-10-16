import icon from "src/decidim/icon"

export default class PasswordToggler {
  constructor(password) {
    this.password = password;
    this.input = this.password.querySelector('input[type="password"]');
    this.form = this.input.closest("form");
    this.texts = {
      showPassword: this.password.getAttribute("data-show-password") || "Show password",
      hidePassword: this.password.getAttribute("data-hide-password") || "Hide password",
      hiddenPassword: this.password.getAttribute("data-hidden-password") || "Your password is hidden",
      shownPassword: this.password.getAttribute("data-shown-password") || "Your password is shown"
    }
    this.icons = {
      show: icon("eye-line"),
      hide: icon("eye-off-line")
    }
    this.buttonClass = {
      onValid: "mt-5",
      onInvalid: "mb-2"
    }
  }

  // Call init() to hide the password confirmation and add a "view password" inline button
  init() {
    this.createControls();
    this.button.addEventListener("click", (evt) => {
      this.toggleVisibiliy(evt);
    });
    // to prevent browsers trying to use autocomplete, turn the type back to password before submitting
    this.form.addEventListener("submit", () => {
      this.hidePassword();
    });

    // to fix the button margin if there are or not errors
    // as foundation abide needs jQuery, we need to do it with 'on' instead of 'addEventListener'
    $(this.input).on("invalid.zf.abide", () => {
      this.button.classList.remove(this.buttonClass.onValid);
      this.button.classList.add(this.buttonClass.onInvalid);
    });

    $(this.input).on("valid.zf.abide", () => {
      this.button.classList.add(this.buttonClass.onValid);
      this.button.classList.remove(this.buttonClass.onInvalid);
    });
  }

  // Call destroy() to switch back to the original password box
  destroy() {
    this.button.removeEventListener("click");
    this.input.removeEventListener("change");
    this.form.removeEventListener("submit");
    const input = this.input.detach();
    this.inputGroup.replaceWith(input);
  }

  createControls() {
    this.createButton();
    this.createStatusText();
    this.addInputGroupWrapperAsParent();
  }

  createButton() {
    const button = document.createElement("button");
    button.classList.add(this.buttonClass.onValid);
    button.setAttribute("type", "button");
    button.setAttribute("aria-controls", this.input.getAttribute("id"));
    button.setAttribute("aria-label", this.texts.showPassword);
    button.innerHTML = this.icons.show;
    this.button = button;
  }

  createStatusText() {
    const statusText = document.createElement("span");
    statusText.classList.add("sr-only");
    statusText.setAttribute("aria-live", "polite");
    statusText.textContent = this.texts.hiddenPassword;
    this.statusText = statusText;
  }

  addInputGroupWrapperAsParent() {
    const inputGroupWrapper = document.createElement("div");
    inputGroupWrapper.classList.add("filter-search", "filter-container");

    this.input.parentNode.replaceChild(inputGroupWrapper, this.input);
    inputGroupWrapper.appendChild(this.input);
    this.input.after(this.button);

    const formError = this.password.querySelector(".form-error");
    if (formError) {
      this.input.after(formError);
    }
  }

  toggleVisibiliy(evt) {
    evt.preventDefault();
    if (this.isText()) {
      this.hidePassword();
    } else {
      this.showPassword();
    }
  }

  showPassword() {
    this.statusText.textContent = this.texts.shownPassword;
    this.button.setAttribute("aria-label", this.texts.hidePassword);
    this.button.innerHTML = this.icons.hide;
    this.input.setAttribute("type", "text");
  }

  hidePassword() {
    this.statusText.textContent = this.texts.hiddenPassword;
    this.button.setAttribute("aria-label", this.texts.showPassword);
    this.button.innerHTML = this.icons.show;
    this.input.setAttribute("type", "password");
  }

  isText() {
    return this.input.getAttribute("type") === "text"
  }
}
