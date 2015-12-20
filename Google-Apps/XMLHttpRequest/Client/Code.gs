// (C) Sujay Phadke 2015

function doGet() {
  var html = HtmlService.createHtmlOutputFromFile('xhr')
    .setSandboxMode(HtmlService.SandboxMode.IFRAME)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1, maximum-scale=2.0, user-scalable=yes')
    //.setWidth(400)
    //.setHeight(300)
    .setTitle('XHR Client');
  
  return html;
}
