// (C) Sujay Phadke 2015
//
// ref:
// https://developers.google.com/apps-script/guides/content
// http://stackoverflow.com/questions/11481222/how-do-i-make-xhr-ajax-requests-against-google-apps-script-contentservice-work
// http://stackoverflow.com/questions/27725424/content-service-for-google-apps-script-returning-html-instead-of-json

// Note: When publishing as a web-app, the authorization needs to be: Run as "myself", access for: "Anyone, even anonymous"
// for cross-domain JSONP requests to work correctly when requested by a third party webpage.
// Test out the script URL in another browser. If it still gives an authorization page,
// re-authorize, or maybe even re-publish under a new version number.

function doGet(e) {

  // If request if to CLEAR the cache, simply clear it and return
  if ((e) && (e.parameter.CLEAR == 1)) {
    ClearCache();
    if (e.parameter.JSONP == 1) {
      return ContentService.createTextOutput(e.parameter.prefix + '(' + JSON.stringify('Cache successfully cleared') + ')')
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
    }
    else {
    return ContentService.createTextOutput(JSON.stringify('Cache successfully cleared'))
      .setMimeType(ContentService.MimeType.JSON);
    }
  }
  
  // request is to GET data. Check if it exists in the cache first.
  var cached = CacheService.getScriptCache().get('testXHR');
  
  if (cached) {
    Logger.log('Fetched data from cache.');
    theContent = cached + '\n\n(cached)';
  }
  else {
    var theContent = readFile();
  }
  
  Logger.log('theContent: ' + theContent);
 
  if ((e) && (e.parameter.JSONP == 1)) {
    Logger.log('PARAM = ' + e.parameter.JSONP + ' Sending JSONP data...');
    return ContentService.createTextOutput(
      e.parameter.prefix + '(' + JSON.stringify(theContent) + ')')
      .setMimeType(ContentService.MimeType.JAVASCRIPT);
  }  
  else {
    Logger.log('Sending JSON data...');
    return ContentService.createTextOutput(JSON.stringify(theContent))
      .setMimeType(ContentService.MimeType.JSON);
  }
  
};

function readFile() {
  // This example creates a file called "testXHR.txt" and appends to it.
  // http://stackoverflow.com/questions/24066523/migrating-code-from-doclist-to-driveapp
  
  var fileName = "testXHR.txt";
  var it = DriveApp.getFilesByName(fileName);
  var hFile = '';
  if (it.hasNext()) {
    hFile = it.next();
  }
  else {
    hFile = DriveApp.createFile(fileName, "");
    // Works for content upto 10MB
    var str = "My Log File" + "\n" + "First log entry";
    hFile.setContent(str);  
  }
  
  Logger.log("File id: " + hFile.getId());
  
  var myCache = CacheService.getScriptCache();
  var content = hFile.getBlob().getDataAsString();
  // maximum amount of data that can be stored per key is 100KB
  myCache.put('testXHR', content, 20);
  
  return content;
};


function ClearCache(){
  CacheService.getScriptCache().remove('testXHR');
  Logger.log('Cleared cache');
}
