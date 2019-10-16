Typegeist

This is an experiment with Typegeist using JavaScript on node.

# Requirements

* Node 12 or later (due to using `--experimental-modules`)
* Platforms that will run headless Chrome via [puppeteer](https://github.com/GoogleChrome/puppeteer)

# Setup

1. Install dependencies using `npm install`

# Running

Run:

`npm run start`

This will run the main scraping loop in `main.js` and output data to `fontData.json`. Currently hardcoded to just run on top 5 domains.

# Observations

Asking for just the `font` shorthand property gives us all the font data in one go, but then we have to parse it out. So maybe this is too clever for its own good.

