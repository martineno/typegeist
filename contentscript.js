function gatherNodes() {
    var bodyNodes = document.body.getElementsByTagName('*');
    var textNodes = [];
    
    for (var nodeIndex = 0; nodeIndex < bodyNodes.length; nodeIndex++) {
        var aNode = bodyNodes[nodeIndex];
            // Does the node have any text in it?
        if (aNode.textContent && aNode.textContent.length != 0 &&
            // Does the node have any font-family information?
            window.getComputedStyle(aNode)['font-family'] &&
            window.getComputedStyle(aNode)['font-family'].length != 0) {
                textNodes.push(aNode);
        }
    }    
    return textNodes;
}

// Compute a histogram from all the the text nodes
function computeHistogram(onNodes) {
    var font_familyHistogram = {};
    
    for (var nodeIndex = 0; nodeIndex < onNodes.length; nodeIndex++) {
        var aNode = onNodes[nodeIndex];
        var font_family = window.getComputedStyle(aNode)['font-family'].toLowerCase();
        if (font_familyHistogram.hasOwnProperty(font_family)) {
            font_familyHistogram[font_family]++;
        } else {
            font_familyHistogram[font_family] = 1;
        }
    }
    
    return font_familyHistogram;
}

chrome.extension.sendRequest(computeHistogram(gatherNodes()));
