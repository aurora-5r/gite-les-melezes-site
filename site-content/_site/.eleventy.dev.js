"use strict";

var fs = require("fs");

var path = require("path");

var livePosts = function livePosts(p) {
  return p.date <= now && !p.data.draft;
};

var now = new Date();
var isProduction = process.env.NODE_ENV === "production";
var manifestPath = path.resolve(__dirname, "dist", "scripts", "webpack.json");
var manifest = JSON.parse(fs.readFileSync(manifestPath, {
  encoding: "utf8"
}));

var pluginSEO = require("eleventy-plugin-seo");

var embedYouTube = require("eleventy-plugin-youtube-embed");

var eleventyNavigationPlugin = require("@11ty/eleventy-navigation");

var readingTime = require("eleventy-plugin-reading-time");

var readerBar = require("eleventy-plugin-reader-bar");

var imagesResponsiver = require("eleventy-plugin-images-responsiver");

var markdownIt = require("markdown-it");

var markdownItAnchor = require("markdown-it-anchor");

var pluginTOC = require("eleventy-plugin-toc");

var languages = [{
  label: "English",
  code: "en"
}, {
  label: "Français",
  code: "fr"
}];

module.exports = function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy("src/images");
  var presets = {
    "default": {
      sizes: "(max-width: 340px) 250px, 50vw",
      minWidth: 250,
      maxWidth: 1200,
      fallbackWidth: 725,
      attributes: {
        loading: "lazy"
      }
    },
    "small-img": {
      fallbackWidth: 250,
      minWidth: 250,
      maxWidth: 250,
      steps: 1,
      sizes: "250px",
      attributes: {
        loading: "lazy"
      }
    }
  };

  if (process.env.ELEVENTY_ENV === "production") {
    eleventyConfig.addPlugin(imagesResponsiver, presets);
  }

  eleventyConfig.addPassthroughCopy("src/**/images/*.*");
  eleventyConfig.setLibrary("md", markdownIt().use(markdownItAnchor));
  eleventyConfig.addPlugin(eleventyNavigationPlugin);
  eleventyConfig.addPlugin(pluginTOC, {
    tags: ["h2", "h3"],
    wrapper: "div"
  });
  eleventyConfig.addPlugin(readingTime);
  eleventyConfig.addPlugin(readerBar);
  eleventyConfig.addPlugin(embedYouTube, {
    embedClass: "post-video"
  });
  eleventyConfig.addPlugin(pluginSEO, {
    title: "AuRorA-5R",
    description: "Transcubateur. AuRorA-5R accompagne les PME de la région AURA dans leurs projets innovants pour des transitions responsables",
    url: "https://aurora-5r.fr",
    author: "Laurent Maumet",
    twitter: "aurora-5r"
  });
  eleventyConfig.addPassthroughCopy("src/robots.txt");
  eleventyConfig.addShortcode("bundledCss", function () {
    return manifest["main"]["css"] ? "<link href=\"".concat(manifest["main"]["css"], "  \" rel=\"stylesheet\" />") : "";
  });
  eleventyConfig.addShortcode("bundledJs", function () {
    return manifest["main"]["js"] ? "<script src=\"".concat(manifest["main"]["js"], "\" async></script>") : "";
  });

  for (lgg in languages) {
    console.log(languages[lgg].code);
    eleventyConfig.addCollection("posts_" + languages[lgg].code, function (collection) {
      return collection.getFilteredByGlob("./src/" + languages[lgg].code + "/posts/**/*.md").filter(function (_) {
        return livePosts(_);
      }).reverse();
    });
    eleventyConfig.addCollection("pages_" + languages[lgg].code, function (collection) {
      return collection.getFilteredByGlob("./src/" + languages[lgg].code + "/pages/**/*.md");
    });
    eleventyConfig.addCollection("slides_" + languages[lgg].code, function (collection) {
      return collection.getFilteredByGlob("./src/" + languages[lgg].code + "/slides/**/*.md");
    });
  }

  module.exports = {
    eleventyComputed: {
      eleventyNavigation: {
        key: function key(data) {
          return data.title;
        },
        parent: function parent(data) {
          return data.parent;
        },
        title: function title(data) {
          if (data.titlenavigation) return data.titlenavigation;else return data.title;
        },
        order: function order(data) {
          if (data.ordernavigation) return data.ordernavigation;else return 0;
        }
      }
    }
  };
  return {
    dir: {
      input: "src",
      output: "dist"
    },
    pathPrefix: isProduction ? "/" : "/gitelesmelezes/",
    templateFormats: ["njk", "md"],
    htmlTemplateEngine: "njk",
    markdownTemplateEngine: "njk"
  };
};