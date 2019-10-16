import puppeteer from 'puppeteer';
import _ from 'lodash';
import parse from 'csv-parse';
import { promises as fsP} from 'fs';

const VERBOSE = true;

async function parseCsv(path) {
  const domainsRaw = await fsP.readFile(path);
  const domainsParsed = await new Promise((resolve, reject) => {
    parse(domainsRaw, { columns: true}, (err, output) => {
      if (err) {
        reject(err);
      } else {
        resolve(output);
      }
    });
  });
  return domainsParsed.map(({ Domain }) => `http://${Domain}` );
}

async function getFontDescription(url, browser) {
  const page = await browser.newPage();
  await page.goto(url);
  const fontDescription = await page.$$eval('body *', el => el.map( e => {
    const cssProps = [
      'font-style',
      'font-variant',
      'font-weight',
      'font-stretch',
      'line-height',
      'font-size',
      'font-family',
      // Technically the above properties contain this, but we can
      // conveniently use this as a key to do dedupe the list of rules
      'font',
    ];
    const elComputedStyle = window.getComputedStyle(e);
    const fontData = cssProps.map(cssProp => {
      const propValue = elComputedStyle[cssProp];
      if (cssProp === 'font-family') {
        return [cssProp, propValue.split(',').map(font => font.trim())];
      }

      return [cssProp, propValue];
    });
    return Object.fromEntries(fontData);
  }));
  page.close();
  return {
    url,
    // Remove duplicate rules using the full 'font' shorthand declaration
    // as a key
    fontDescription: _.uniqBy(fontDescription, 'font'),
  };
}

async function getDescriptionForDomains(domains, browser) {
  const examinedDomains = {};

  for (const domain of domains) {
    try {
      console.log(`Now processing ${domain}`);
      const { fontDescription } = await getFontDescription(domain, browser);
      if (VERBOSE) {
        console.log(fontDescription);
      }
      examinedDomains[domain] = fontDescription;
    } catch (e) {
      console.error(`Unabled to process domain ${domain} due to error ${e}`);
    }
  }

  return examinedDomains;
}


(async () => {
  const browser = await puppeteer.launch();
  const domainsToExamine = _.take(await parseCsv('./assets/top1000.csv'), 100);
  const domainsFontDescriptions = await getDescriptionForDomains(domainsToExamine, browser);
  await fsP.writeFile('./fontData.json', JSON.stringify(domainsFontDescriptions));
  await browser.close();
})();