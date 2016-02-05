function doGet() {
  
 return ShowPage();
  
}

function ShowPage() {
  
  var html = HtmlService.createHtmlOutputFromFile('highcharts')

      .setSandboxMode(HtmlService.SandboxMode.IFRAME)
      .addMetaTag('viewport', 'width=device-width, initial-scale=1, maximum-scale=2.0, user-scalable=yes')
      //.setWidth(400)
      //.setHeight(300)
      .setTitle('Test Highcharts')
      
  return html;
  
}
