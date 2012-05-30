var webpage = require('webpage'),
    page,
    fs = require('fs'),
    f, t, url, url;

function processPage() {
    // Get all the elements
    var allElements = document.querySelectorAll('*'),
        fonts = {
            fontNames: {},
            fontSizes: {}
        },
        computedStyle;

    var incOrCreate = function(object, property) {
        if (object[property] === undefined) {
            object[property] = 1;
        } else {
            object[property]++;
        }
    };

    for (var i = 0; i < allElements.length; i++) {
        computedStyle = window.getComputedStyle(allElements[i]);
        incOrCreate(fonts.fontNames, computedStyle['font-family']);
        incOrCreate(fonts.fontSizes, computedStyle['font-size']);
    }
    return fonts;
}


if (phantom.args.length === 0) {
    console.log('Usage: dumpfonts.js pathToFile');
    phantom.exit();
} else {
    console.log('Reading URLs from: ' + phantom.args[0]);
    urls = fs.open(phantom.args[0], 'r');

    // Right now things are just done serially. Probably multiple pages
    // can be open at a time
    var processNext = function() {
        if (url = urls.readLine()) {
            page = webpage.create();
            page.viewportSize = { width: 900, height: 800 }
            // For reasons that are not entirely clear, sometimes the same set of pages
            // can be loaded fine, other times it fails. Could be that the networking
            // component freaks out? Not sure
            page.open('http://' + url, function (status) {
                var siteFontRecord = {
                    site: url,
                    retrievedOn: new Date(),
                    status: 'failed',
                    fontNames: {},
                    fontSizes: {}
                }
                if (status !== 'success') {
                    console.log(JSON.stringify(siteFontRecord));
                } else {
                    // Evaluate runs a script in the context of a page.
                    var fontSpec = page.evaluate(processPage);

                    siteFontRecord.fontNames = fontSpec.fontNames;
                    siteFontRecord.fontSizes = fontSpec.fontSizes;
                    siteFontRecord.status = 'success';
                    console.log(JSON.stringify(siteFontRecord));
                }
                // For troubleshooting, saves a pic of the page
                // page.render(url + '.png');
                processNext();
            });            
        } else {
            phantom.exit();
        }
    };
    processNext();
}