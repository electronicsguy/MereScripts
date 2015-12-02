/*
Find emails in a specific date range, spanning multiple years
eg: If you want to find all emails between 14th Aug to 16th Aug for all the
years between 2009 to 2013.
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

// --- Globals ---
var monthShortNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

var ss = SpreadsheetApp.getActiveSpreadsheet();
var sheet = ss.getSheetByName("Sheet1");
var ui = SpreadsheetApp.getUi();

// ---------------

function showHelp() {
  var html = HtmlService.createHtmlOutputFromFile('help')
  .setTitle("Help")
  .setWidth(400)
  .setHeight(200);
  ui.showModalDialog(html, 'Help');
}

function onOpen() {
  var menu = [
    {name: "Help",functionName: "showHelp"},
    null,
    {name: "Search", functionName: "ReadInput"},
    //{name: "Search", functionName: "ReadHTMLInput"},
    {name: "Remove Labels", functionName: "removeLabels"},
    {name: "Uninstall", functionName: "Uninstall"},
    null
  ];  
  ss.addMenu("DReaMY", menu);
  Initialize()
}

function Initialize() {
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
  ss.toast("Initialized.", "DReaMY", 10);
  
  
}

function ReadHTMLInput() {
  var html = HtmlService.createHtmlOutputFromFile('inputpage')
      .setSandboxMode(HtmlService.SandboxMode.IFRAME)
      .setWidth(400)
      .setHeight(300);
  ui.showModalDialog(html, 'Enter search Parameters');
}

function ReadInput() {
  ss.toast("Performing search...", "DReaMY", 5);
  var m1 = ss.getRange('B5').getValue();
  var d1 = ss.getRange('A5').getValue();
  var m2 = ss.getRange('E5').getValue();
  var d2 = ss.getRange('D5').getValue();
  var y1 = ss.getRange('G5').getValue();
  var y2 = ss.getRange('H5').getValue();

  // Check for values entered
  var checksum = isInt(d1) && isInt(m1) && isInt(d2) && isInt(m2) && isInt(y1) && isInt(y2);
  
  if (!checksum){
    ui.alert('Error!', 'Please enter all required numeric values', ui.ButtonSet.OK);
    return false;
  }
  
  retval = Search(d1,m1,y1,d2,m2,y2);
  if (retval == false){
    ss.toast('Error running search. Please check input and gmail authorization.', "DReaMY", 10);
  }
  else{
    ss.toast('Search Complete. Please check for the label "DReaMY" in your gmail account.', "DReaMY", 10);
  }
  
}

function SanityChecks(d1, m1, y1, d2, m2, y2){
  //ss.toast(d1 + ' ' + m1 + ' ' + y1 + ' ' + d2 + ' ' + m2 + ' ' + y2 + ' ', "DReaMY", 10);
  
  // add checks for the date and month values (0-31, 1-12)
  if ((d1 > 31) || (d1 < 1) || (d2 > 31) || (d2 < 1)){
    ui.alert('Error!', 'Date values out of allowed range', ui.ButtonSet.OK);
    return false;
  }
  if ((m1 > 12) || (m1 < 1) || (m2 > 12) || (m2 < 1)){
    ui.alert('Error!', 'Month values out of allowed range', ui.ButtonSet.OK);
    return false;
  }
  if ((y1 < 0) || (y2 < 0)){
    ui.alert('Error!', 'Year values out of allowed range', ui.ButtonSet.OK);
    return false;
  }
  
  // stupid Javascript Month numbers start from 0
  // ref: http://stackoverflow.com/questions/15685190/google-apps-script-returning-wrong-month-subtracting-1
  var dateBegin = new Date(y1, m1-1, d1);
  var dateEnd = new Date(y2, m2-1, d2);
  
  // date check sanity
  if (dateEnd < dateBegin){
    ui.alert('Error!', 'Start Date must not be after End Date', ui.ButtonSet.OK);
    return false;
  }
  
  if (y2 < y1){
    ui.alert('Error!', 'Start Year must not be after End Year', ui.ButtonSet.OK);
    return false;
  }

  return true;
}

function Search(d1, m1, y1, d2, m2, y2){
  //ss.toast(d1 + ' ' + m1 + ' ' + y1 + ' ' + d2 + ' ' + m2 + ' ' + y2 + ' ', "DReaMY", 10);
  
  if (!(SanityChecks(d1, m1, y1, d2, m2, y2))){
    return false;
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
      // Parent label must be present or else create it
      getGmailLabel('DReaMY');
      getGmailLabel(queryLabel);
      
      labelYear = getGmailLabel(queryLabel + '/' + currYear);
      
      for (var i=0; i < numThreads; i++){
        threads[i].addLabel(labelYear);
      }
      
    }
  }
  
  return numThreads;
  
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
  
  ss.toast("All custom labels removed.", "DReaMY", 5);
  
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


// ref: http://stackoverflow.com/questions/3885817/how-to-check-that-a-number-is-float-or-integer
function isInt(value) {

    var er = /^-?[0-9]+$/;

    return er.test(value);
}
