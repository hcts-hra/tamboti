xquery version "3.1";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $cors := response:set-header("Access-Control-Allow-Origin", "*")
let $id := request:get-parameter("uuid", "i_7dbcdaf9-f5ec-49d1-8f6d-30e6e3c2f9d6")

return
    <html lang="en">
     <head>
      <meta charset="utf-8" />
      <meta name="DC.creator" content="Ruven Pillay &lt;ruven@users.sourceforge.netm&gt;"/>
      <meta name="DC.title" content="IIPMooViewer 2.0: HTML5 High Resolution Image Viewer"/>
      <meta name="DC.subject" content="IIPMooViewer; IIPImage; Visualization; HTML5; Ajax; High Resolution; Internet Imaging Protocol; IIP"/>
      <meta name="DC.description" content="IIPMooViewer is an advanced javascript HTML5 image viewer for streaming high resolution scientific images"/>
      <meta name="DC.rights" content="Copyright 2003-2012 Ruven Pillay"/>
      <meta name="DC.source" content="http://iipimage.sourceforge.net"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />
      <meta name="apple-mobile-web-app-capable" content="yes" />
      <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      <meta http-equiv="X-UA-Compatible" content="IE=9" />
    
      <link rel="stylesheet" type="text/css" media="all" href="/exist/apps/tamboti/components/iipmooviewer/css/iip.min.css" />
    <!--[if lt IE 10]>
      <meta http-equiv="X-UA-Compatible" content="IE=9" >
      <link rel="stylesheet" type="text/css" media="all" href="css/ie.min.css" />
    <![endif]-->
    
      <!-- Basic example style for a 100% view -->
    
      <link rel="shortcut icon" href="/exist/apps/tamboti/components/iipmooviewer/scripts/iipmooviewerimages/iip-favicon.png" />
      <link rel="apple-touch-icon" href="/exist/apps/tamboti/components/iipmooviewer/scripts/iipmooviewerimages/iip.png" />
    
      <title>IIPMooViewer 2.0 :: HTML5 High Resolution Image Viewer</title>
    
      <script type="text/javascript" src="/exist/apps/tamboti/components/iipmooviewer/js/mootools-core-1.5.1-full-nocompat-yc.js"></script>
      <script type="text/javascript" src="/exist/apps/tamboti/components/iipmooviewer/js/iipmooviewer-2.0-min.js"></script>
      <script type="text/javascript" src="/exist/apps/tamboti/components/iipmooviewer/src/protocols/iiif.js"></script>
    
    {
        let $js := '<script type="text/javascript">
    
        // IIPMooViewer options: See documentation at http://iipimage.sourceforge.net for more details
        // Server path: set if not using default path
        var server = ''/exist/apps/tamboti/modules/display/image.xql?schema=IIIF&amp;call='';
        // The *full* image path on the server. This path does *not* need to be in the web
        // server root directory. On Windows, use Unix style forward slash paths without
        // the "c:" prefix
        var image = "' || $id || '";
    
        // Copyright or information message
        var credit = ''copyright or information message'';
    
        // Create our iipmooviewer object
        new IIPMooViewer( "viewer", {
    	server: server,
    	image: image,
    	credit: credit,
    	protocol: "IIIF",
    	//scale: 12.0
        });
    
      </script>'
      return $js
    }
    
     </head>
    
     <body style="height: 100%;
          padding: 0;
          margin: 0;
    ">
       <div id="viewer" style="height: 100%;
          min-height: 100%;
          width: 100%;
          position: absolute;
          top: 0;
          left: 0;
          margin: 0;
          padding: 0;">
              
          </div>
     </body>
    
    </html>