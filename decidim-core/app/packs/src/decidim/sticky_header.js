let prevScroll = window.scrollY;
const stickyHeader = document.getElementById("sticky-header");

if (stickyHeader) {
  document.addEventListener("scroll", () => {
    // if a subelement is not visible it has no offsetParent
    const header = document.getElementById("main-bar").offsetParent;
    if (header) {
      let currentScroll = window.scrollY;
      if (prevScroll > currentScroll || currentScroll < stickyHeader.offsetHeight) {
        stickyHeader.style.top = 0;
      } else {
        stickyHeader.style.top = `-${stickyHeader.offsetHeight}px`;
      }
      prevScroll = currentScroll;
    }
  });
};
