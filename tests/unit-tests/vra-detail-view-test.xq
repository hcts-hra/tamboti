xquery version "3.0";

import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "/db/apps/tamboti/frameworks/vra-hra/vra-hra.xqm";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";

(:declare option output:method "html5";:)
(:declare option output:media-type "text/html";:)

declare option exist:serialize "method=html5 media-type=text/html";

let $testvra := collection("/db/data/users/editor")//vra:work[@id="w_c501fff7-28cc-4710-8ba5-ed6cfe195674"]

return
    <html>
        <head>
            <script src="/exist/apps/tamboti/resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
            <script type="text/javascript" src="/exist/apps/tamboti/resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
            <link rel="stylesheet" type="text/css" href="/exist/apps/tamboti/resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css"/>
            <script type="text/javascript" src="$shared/resources/scripts/jquery/jquery-utils.js">/**/</script>
            <script type="text/javascript" src="/exist/apps/tamboti/resources/scripts/qtip/jquery.qtip.min.js">/**/</script>
            <link rel="stylesheet" href="/exist/apps/tamboti/resources/scripts/qtip/jquery.qtip.min.css" type="text/css"/>
            <script type="text/javascript" src="/exist/apps/tamboti/modules/apis/apis.js">/**/</script>
            <script type="text/javascript" src="/exist/apps/tamboti/resources/scripts/query.js">/**/</script>
            <!--<link rel="stylesheet" type="text/css" href="/exist/apps/tamboti/themes/default/css/theme.css"/>-->
            <link rel="stylesheet" type="text/css" href="/exist/apps/tamboti/themes/default/css/biblio.css"/>
        </head>
        <body>
            <table>
                {
                    vra-hra-framework:detail-view-table(root($testvra)/vra:vra, 1)
                }
            </table>
        </body>
    </html>