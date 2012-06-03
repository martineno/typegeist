var webpage = require('webpage');

console.log('hey what\'s up');

console.log('phantom.injectjs: ' + phantom.injectJs('./jquery.min.js'));

console.log('jquery: ' + $);

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

function sleep(milliseconds) {
  var start = new Date().getTime();
  for (var i = 0; i < 1e7; i++) {
    if ((new Date().getTime() - start) > milliseconds){
      break;
    }
  }
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