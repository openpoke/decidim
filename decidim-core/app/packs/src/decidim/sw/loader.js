// check if the browser supports serviceWorker at all
window.addEventListener("load", async () => {
  if ("serviceWorker" in navigator) {
    await navigator.serviceWorker.register("/sw.js", { scope: "/" });
  } else {
    const mandatoryElements = document.querySelector(".sw-mandatory")

    if (mandatoryElements) {
      mandatoryElements.remove();
    }
    console.log("Your browser doesn't support service workers 🤷‍♀️");
  }
});

