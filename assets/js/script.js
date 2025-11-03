'use strict';



/**
 * add event on element
 */

const addEventOnElem = function (elem, type, callback) {
  if (elem.length > 1) {
    for (let i = 0; i < elem.length; i++) {
      elem[i].addEventListener(type, callback);
    }
  } else {
    elem.addEventListener(type, callback);
  }
}



/**
 * navbar toggle
 */

const navbar = document.querySelector("[data-navbar]");
const navTogglers = document.querySelectorAll("[data-nav-toggler]");
const navLinks = document.querySelectorAll("[data-nav-link]");

const toggleNavbar = function () { navbar.classList.toggle("active"); }

addEventOnElem(navTogglers, "click", toggleNavbar);

const closeNavbar = function () { navbar.classList.remove("active"); }

addEventOnElem(navLinks, "click", closeNavbar);



/**
 * header & back top btn active
 */

const header = document.querySelector("[data-header]");
const backTopBtn = document.querySelector("[data-back-top-btn]");

// Verificar si la página tiene hero o es una página como productos
const hasHero = document.querySelector(".hero") !== null;
const isPageWithoutHero = document.body.classList.contains("page-productos") || !hasHero;

// Si no hay hero, activar el header desde el inicio
if (isPageWithoutHero && header) {
  header.classList.add("active");
}

window.addEventListener("scroll", function () {
  if (window.scrollY >= 100) {
    header.classList.add("active");
    backTopBtn.classList.add("active");
  } else {
    // Solo remover "active" si hay hero, para páginas sin hero mantenerlo siempre activo
    if (hasHero && !isPageWithoutHero) {
      header.classList.remove("active");
    }
    backTopBtn.classList.remove("active");
  }
});



/**
 * pricing carousel 3d effect
 */

const carouselLists = document.querySelectorAll("[data-carousel-3d]");
const media3d = window.matchMedia("(max-width: 991px)");

const updateCarouselPositions = function (list) {
  const items = list.querySelectorAll(".scrollbar-item");
  if (!items.length) return;

  if (!media3d.matches) {
    items.forEach((item, index) => {
      const card = item.querySelector(".pricing-card");
      if (card) card.dataset.position = index === 0 ? "active" : "behind";
    });
    return;
  }

  const listRect = list.getBoundingClientRect();
  const listCenter = listRect.left + (listRect.width / 2);
  let activeIndex = 0;
  let minDistance = Infinity;

  items.forEach((item, index) => {
    const cardRect = item.getBoundingClientRect();
    const cardCenter = cardRect.left + (cardRect.width / 2);
    const distance = Math.abs(listCenter - cardCenter);

    if (distance < minDistance) {
      minDistance = distance;
      activeIndex = index;
    }
  });

  // Asegurar que siempre se muestren prev y next si existen
  items.forEach((item, index) => {
    const card = item.querySelector(".pricing-card");
    if (!card) return;

    if (index === activeIndex) {
      card.dataset.position = "active";
    } else if (index === activeIndex - 1 && index >= 0) {
      card.dataset.position = "prev";
    } else if (index === activeIndex + 1 && index < items.length) {
      card.dataset.position = "next";
    } else {
      card.dataset.position = "behind";
    }
  });
}

const initCarousel3D = function () {
  if (!carouselLists.length) return;

  carouselLists.forEach((list) => {
    updateCarouselPositions(list);

    list.addEventListener("scroll", () => {
      window.requestAnimationFrame(() => updateCarouselPositions(list));
    });
  });

  window.addEventListener("resize", () => {
    carouselLists.forEach((list) => updateCarouselPositions(list));
  });

  if (typeof media3d.addEventListener === "function") {
    media3d.addEventListener("change", () => {
      carouselLists.forEach((list) => updateCarouselPositions(list));
    });
  } else if (typeof media3d.addListener === "function") {
    media3d.addListener(() => {
      carouselLists.forEach((list) => updateCarouselPositions(list));
    });
  }
}

initCarousel3D();

/**
 * Scroll indicator for pricing cards on mobile
 */
const pricingList = document.querySelector("#planes .pricing-list");
if (pricingList) {
  const checkScrollEnd = function() {
    const isAtEnd = pricingList.scrollWidth - pricingList.scrollLeft <= pricingList.clientWidth + 10;
    if (isAtEnd) {
      pricingList.classList.add("scrolled-to-end");
    } else {
      pricingList.classList.remove("scrolled-to-end");
    }
  };

  // Check on scroll
  pricingList.addEventListener("scroll", checkScrollEnd);
  
  // Check on load and resize
  checkScrollEnd();
  window.addEventListener("resize", checkScrollEnd);
}