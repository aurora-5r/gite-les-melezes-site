"use strict";

var _aos = _interopRequireDefault(require("aos"));

require("owl.carousel");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

// HEADER ANIMATION
window.onscroll = function () {
  scrollFunction();
};

var element = document.getElementById("body");

function scrollFunction() {
  if (document.body.scrollTop > 400 || document.documentElement.scrollTop > 400) {
    $(".navbar").addClass("fixed-top");
    element.classList.add("header-small");
    $("body").addClass("body-top-padding");
  } else {
    $(".navbar").removeClass("fixed-top");
    element.classList.remove("header-small");
    $("body").removeClass("body-top-padding");
  }
} // OWL-CAROUSAL


$(".owl-carousel").owlCarousel({
  items: 3,
  loop: true,
  nav: false,
  dots: false,
  autoplay: true,
  slideTransition: "linear",
  autoplayHoverPause: true,
  responsive: {
    0: {
      items: 1
    },
    600: {
      items: 1
    },
    1000: {
      items: 1
    }
  }
}); // SCROLLSPY

$(document).ready(function () {
  $(".nav-link").click(function () {
    var t = $(this).attr("href");
    $("html, body").animate({
      scrollTop: $(t).offset().top - 75
    }, {
      duration: 1000
    });
    $("body").scrollspy({
      target: ".navbar",
      offset: $(t).offset().top
    });
    return false;
  });
}); // AOS

_aos["default"].init({
  offset: 120,
  delay: 0,
  duration: 1200,
  easing: "ease",
  once: true,
  mirror: false,
  anchorPlacement: "top-bottom",
  disable: "mobile"
}); //SIDEBAR-OPEN


$("#navbarSupportedContent").on("hidden.bs.collapse", function () {
  $("body").removeClass("sidebar-open");
});
$("#navbarSupportedContent").on("shown.bs.collapse", function () {
  $("body").addClass("sidebar-open");
});

window.onresize = function () {
  var w = window.innerWidth;

  if (w >= 992) {
    $("body").removeClass("sidebar-open");
    $("#navbarSupportedContent").removeClass("show");
  }
};