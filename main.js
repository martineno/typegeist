import puppeteer from 'puppeteer';
import _ from 'lodash';
import parse from 'csv-parse';
import { promises as fsP} from 'fs';

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
    return window.getComputedStyle(e).getPropertyValue('font');
  }));

  return {
    url,
    fontDescription: _.uniq(fontDescription),
  };
}

async function getDescriptionForDomains(domains, browser) {
  const examinedDomains = {};

  for (const domain of domains) {
    try {
      console.log(`Now processing ${domain}`);
      const { fontDescription } = await getFontDescription(domain, browser);
      examinedDomains[domain] = fontDescription;
    } catch (e) {
      console.error(`Unabled to process domain ${domain} due to error ${e}`);
    }
  }

  return examinedDomains;
}


(async () => {
  const browser = await puppeteer.launch();
  const domainsToExamine = _.take(await parseCsv('./assets/top1000.csv'), 5);
  const domainsFontDescriptions = await getDescriptionForDomains(domainsToExamine, browser);
  await fsP.writeFile('./fontData.json', JSON.stringify(domainsFontDescriptions));
  await browser.close();
})();