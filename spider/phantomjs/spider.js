var webpage = require('webpage');

var styleOfInterest = [ 'font-family', 'font-size', 'font-style', 'font-variant', 'font-weight' ];

console.log('hey what\'s up');

console.log('phantom.injectjs: ' + phantom.injectJs('./jquery.min.js'));

console.log('jquery: ' + $);

function processPage() {
    var allElements = document.querySelectorAll('*'),
        styleDigest = {};

    var getStyles = function(element) {
        var computedStyle = window.getComputedStyle(element);
        var style = {};

        for (var i = 0; i < styleOfInterest.length; i++) {
            style[styleOfInterest[i]] = computedStyle[styleOfInterest[i]];
        }

        return style;
    };

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

        var text = $.grep(element.childNodes, function (node) { return node.nodeType == Node.TEXT_NODE; });

        for (var i = 0; i < text.length; i++) {
            styles.characters += text[i].length;
        }

        styles.elements++;

        styleDigest[styleString] = styles;
        return styles;
    };

    for (var i = 0; i < allElements.length; i++) {
        updateAccounting(allElements[i]);
    }

    return styleDigest;
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

            submit_wu(siteFontRecord);
            // For troubleshooting, saves a pic of the page
            // page.render(url + '.png');
        });
}

// main loop: call the spider API, get a workunit, process that workunit, submit that workunit
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