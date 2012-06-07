var webpage = require('webpage');

console.log('hey what\'s up');

console.log('phantom.injectjs: ' + phantom.injectJs('./jquery.min.js'));

console.log('jquery: ' + $);

function processPage() {
    var allElements = document.querySelectorAll('*'),
        styleDigest = {};
    var styleOfInterest = 
        [ 'font-family', 'font-size', 'font-style', 'font-variant', 
          'font-weight' ];

    var getStyles = function(element) {
        var computedStyle = window.getComputedStyle(element);
        var style = {};

        for (var i = 0; i < styleOfInterest.length; i++) {
            style[styleOfInterest[i]] = computedStyle[styleOfInterest[i]];
        }

        return style;
    };

    // merge all of the styles of interest into a single string so we can 
    // search for identical sets without walking a tree or something
    var buildStyleString = function(element) {
        var computedStyle = window.getComputedStyle(element);
        var result = "";

        for (var i = 0; i < styleOfInterest.length; i++) {
            result += "/" + computedStyle[styleOfInterest[i]].toLowerCase();
        }

        return result;
    };

    var updateAccounting = function(element) {
        var styleString = buildStyleString(element),
            styles;

        if (styleDigest[styleString] === undefined) {
            styles = getStyles(element);
            styles.characters = styles.elements = 0;
        } else {
            styles = styleDigest[styleString];
        }

        // count the number of characters included within this element alone
        // (unlike innerText, this doesn't include descendants)
        var children = element.childNodes;

        for (var i = 0; i < children.length; i++) {
            if (children[i].nodeType === Node.TEXT_NODE) {
                styles.characters += children[i].length;
            }
        }

        styles.elements++;

        styleDigest[styleString] = styles;
        return styles;
    };

    for (var i = 0; i < allElements.length; i++) {
        updateAccounting(allElements[i]);
    }

    // pull out all of the style strings, since they're redundant information
    // now no longer used for identifying matching styles
    compactDigest = [];

    for (var styleString in styleDigest) {
        compactDigest = compactDigest.concat(styleDigest[styleString]);
    }

    return compactDigest;
}

function submit_wu(work_unit) {
	$.ajax({ url: api_endpoint + '/work', 
		type: 'POST',
		dataType: 'json',
		data: { work_unit: work_unit },
		success: function (json) {
			console.log('XHR succeeded: ' + JSON.stringify(json));
		},
		error: function() {
			console.log('XHR failed');
		}
		});
}

function spider(uri, wuid) {
	var page = webpage.create();

	page.open(uri, 
		function (status) {
            var siteFontRecord = {
            	wuid: wuid,
                site: uri,
                retrievedOn: new Date(),
                status: 'failed',
                styleDigest: {}
            }
            if (status !== 'success') {
                console.log(JSON.stringify(siteFontRecord));
            } else {
                // Evaluate runs a script in the context of a page.
                var fontSpec = page.evaluate(processPage);

                siteFontRecord.styleDigest = fontSpec;
                siteFontRecord.status = 'success';
                console.log(JSON.stringify(siteFontRecord));
            }

            submit_wu(siteFontRecord);
            // For troubleshooting, saves a pic of the page
            // page.render(url + '.png');
        });
}

// main loop: call the spider API, get a workunit, process that workunit, 
// submit that workunit
console.log('new xhr: ' + new XMLHttpRequest());

var api_endpoint = 'http://localhost:9292/api'; 

function do_next_wu() {
	// use jquery ajax to fetch from the spider API
	// console.log('doing xhr to ' + api_endpoint);
	$.ajax({ url: api_endpoint + '/work', 
		dataType: 'json',
		success: function (json) {
			console.log('XHR succeeded: ' + JSON.stringify(json));
			console.log('spidering ' + json.uri);
			spider(json.uri, json.work_unit);
			do_next_wu();
		},
		error: function() {
			console.log('XHR failed');
		}
		});
}

do_next_wu();