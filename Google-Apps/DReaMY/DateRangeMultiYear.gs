/*
Find emails in a (common) specific date range for multiple years
eg: If you want to find all emails between 14th Aug to 16th Aug for the
years 2009 - 2013.
I wrote this script since it isn't possible to do a search like that
within gmail directly.

This script will find the required emails and create a new label 
called 'DReaMY'. All the searches will be tagged with this label.
The label can be deleted at will. No emails will be deleted or modified.

Written by Sujay Phadke, 2015
Github: @electronicsguy

For help, send me an email: electronicsguy123@gmail.com
*/

// ref: http://jonathan-kim.com/2013/gmail-no-response/
// ref: http://www.labnol.org/internet/advanced-gmail-filters/4875/

/*function createTrigger() {
  
  var triggers = ScriptApp.getScriptTriggers();
  
  for(var i in triggers) {
    ScriptApp.deleteTrigger(triggers[i]);
  }
    
  ScriptApp.newTrigger('readGmail')
  .timeBased()
  .everyMinutes(10)
  .create();   
}
*/

var monthShortNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function help() {
  var html = HtmlService.createHtmlOutputFromFile('help')
  .setTitle("Help")
  .setWidth(400)
  .setHeight(200);
  var ss = SpreadsheetApp.getActive();
  ss.show(html);
}

function onOpen() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var menu = [
    {name: "Help",functionName: "help"},
    null,
    {name: "Search", functionName: "Search"},
    {name: "Remove Labels", functionName: "removeLabels"},
    {name: "Uninstall", functionName: "Uninstall"},
    null
  ];  
  ss.addMenu("Actions", menu);
  Initialize()
}

function Initialize() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName("Sheet1");
  sheet.clear()
  ss.getRange('A1').setValue('Welcome to gmail-search: Date Ranges extended around Multiple Years (DReaMY)');
  ss.getRange('A3').setValue('Start Dates');
  ss.getRange('A3:B3').mergeAcross();
  ss.getRange('D3').setValue('End Dates');
  ss.getRange('D3:E3').mergeAcross();
  ss.getRange('G3').setValue('Years');
  ss.getRange('G3:H3').mergeAcross();
  ss.getRange('A4').setValue('Day');
  ss.getRange('B4').setValue('Month');
  ss.getRange('D4').setValue('Day');
  ss.getRange('E4').setValue('Month');
  ss.getRange('G4').setValue('Start');
  ss.getRange('H4').setValue('End');
  ss.getRange('A3:H5').setHorizontalAlignment("center");
  SpreadsheetApp.flush();
  ss.toast("Initialized.", "DateRangeMultiYear", 10);
  
  
}

function Search() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var ui = SpreadsheetApp.getUi();
  //var sheet = ss.getSheetByName("Sheet1");
  ss.toast("Performing search...", "DateRangeMultiYear", 5);
  var m1 = ss.getRange('B5').getValue();
  var d1 = ss.getRange('A5').getValue();
  var m2 = ss.getRange('E5').getValue();
  var d2 = ss.getRange('D5').getValue();
  var y1 = ss.getRange('G5').getValue();
  var y2 = ss.getRange('H5').getValue();

  // stupid Javascript numbers months from 0
  // ref: http://stackoverflow.com/questions/15685190/google-apps-script-returning-wrong-month-subtracting-1
  var dateBegin = new Date(y1, m1-1, d1);
  var dateEnd = new Date(y2, m2-1, d2);
  
  // sanityChecks
  var checksum = isInt(d1) && isInt(m1) && isInt(d2) && isInt(m2) && isInt(y1) && isInt(y2);
  
  if (!checksum){
    ui.alert('Error!', 'Please enter all required numeric values', ui.ButtonSet.OK);
  
    return;
    
  }
  
  // date check sanity
  if (dateEnd < dateBegin){
    ui.alert('Error!', 'Start Date must not be after End Date', ui.ButtonSet.OK);
  
    return;
    
  }
  
  if (y2 < y1){
    ui.alert('Error!', 'Start Year must not be after End Year', ui.ButtonSet.OK);
  
    return;
   
  }

  // Loop over the years
  for (var currYear = parseInt(y1); currYear <= parseInt(y2); currYear++){
    var date1 = currYear + '/' + m1 + '/' + d1;
    var date2 = currYear + '/' + m2 + '/' + d2;
    
    var queryStr1 = ' after:' + date1;
    var queryStr2 = ' before:' + date2;
    
    var queryStr = queryStr1 + queryStr2;
    
    //var queryLabel = 'DReaMY' + '/' + m1 + '.' + d1 + ' to ' + m2 + '.' + d2;
    var queryLabel = 'DReaMY' + '/' + d1 + '.' + monthShortNames[parseInt(m1-1)] + ' to ' + d2 + '.' + monthShortNames[parseInt(m2-1)];
    var threads = GmailApp.search(queryStr);
    var numThreads = threads.length
    //ui.alert('Search Result: ' + queryStr, 'Number of threads found: ' + numThreads, ui.ButtonSet.OK);
    
    // ref: hierarchical labels
    // http://ctrlq.org/code/19895-create-nested-gmail-labels
    if (numThreads > 0){
      // Parent label must be present
      getGmailLabel('DReaMY');
      getGmailLabel(queryLabel);
      
      labelYear = getGmailLabel(queryLabel + '/' + currYear);
      
      for (var i=0; i < numThreads; i++){
        threads[i].addLabel(labelYear);
      }
      
    }
  }
  // something about label being processed here
  // http://stackoverflow.com/questions/31261134/inconsistencies-between-app-scripts-gmailapp-search-and-the-search-in-gmail-inte
  
  ss.toast('Search Complete. Please check for the label "DReaMY" in your gmail account.', "DateRangeMultiYear", 10);
  
}

function readGmail(query) {  
  try {    
    var threads = GmailApp.search(query);
    return threads.length
     
  } catch (e) {
    Logger.log(e.toString());
  }
}

function removeLabels(){
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var ui = SpreadsheetApp.getUi();
  var retval = ui.alert('Alert!', 'Do you wish to remove the custom labels created by this app from your gmail?\n \
                        Note:No emails will be deleted', ui.ButtonSet.OK_CANCEL);
  
  if (retval == ui.Button.CANCEL){
    return;
  }
  
  var matchCount = 0;
  var matchList = [];
  var labelRoot = /DReaMY/
  var existingLabels = GmailApp.getUserLabels();
  for (var i = 0; i < existingLabels.length; i++){
    if (labelRoot.test(existingLabels[i].getName())){
      ++matchCount;
      matchList.push(existingLabels[i])
    }
  }
  
  while(matchCount > 0){
    matchList[matchCount-1].deleteLabel();
    --matchCount;
  }
  
  ss.toast("All custom labels removed.", "DateRangeMultiYear", 5);
  
}

function getGmailLabel(name) {
  
  var label = GmailApp.getUserLabelByName(name);
  
  if (!label) {
    label = GmailApp.createLabel(name);
  }
  
  return label;  
}

function Uninstall() {
  
  var triggers = ScriptApp.getScriptTriggers();
  
  for(var i in triggers) {
    ScriptApp.deleteTrigger(triggers[i]);
  }  
  
    SpreadsheetApp.getActiveSpreadsheet().toast("Your script is no longer active. For help, visit electronicsguy.wordpress.com", "Deactivated");
  
}

function isProcessed(msgs) {
  
  var key = "DReaMY";
  var props = PropertiesService.getScriptProperties();  
  var when = msgs[0].getDate().getTime();  
  var last = props.getProperty(key) ? parseInt(props.getProperty(key)) : 0;
  props.setProperty(key, when.toString());    
  if ( (msgs.length == 1) && (parseInt(when) >= parseInt(last)) ) {
    return false;
  } else {
    return true;
  }
}

// ref: http://stackoverflow.com/questions/3885817/how-to-check-that-a-number-is-float-or-integer
function isInt(value) {

    var er = /^-?[0-9]+$/;

    return er.test(value);
}
