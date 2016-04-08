// Original code by Greg Ross
// https://code.google.com/archive/p/javascript-surface-plot/

function doGet() {
  return ShowPage();
}

function ShowPage() {
 
  var html = HtmlService.createTemplateFromFile('JS3D')
      .evaluate()
      .setSandboxMode(HtmlService.SandboxMode.IFRAME)
      .addMetaTag('viewport', 'width=device-width, initial-scale=1, maximum-scale=2.0, user-scalable=yes')
      //.setWidth(400)
      //.setHeight(300)
      .setTitle('JS 3D Plot Test')
      
  return html;
}



// required to include 3-party libraries into template
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}
