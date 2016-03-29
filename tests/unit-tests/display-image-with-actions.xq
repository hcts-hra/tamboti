xquery version "3.0";

import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "/apps/tamboti/frameworks/vra-hra/vra-hra.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $uuid := "i_56c3ef80-0f9a-4842-911d-4a47ba24dd77"
return
    <html>
        <head>
            <script type="text/javascript" src="//code.jquery.com/jquery-1.11.3.min.js"/>
            <link rel="stylesheet" type="text/css" href="/exist/apps/tamboti/themes/default/css/biblio.css"/>
        </head>
        <body>
            <div class="img-container" onmouseenter="$(this).find('.img-actions-overlay').fadeIn(200);" onmouseleave="$(this).find('.img-actions-overlay').fadeOut(200);" style="max-width:128px; max-height:128px;width:128px;height:128px;">
                {vra-hra-framework:create-thumbnail-span($uuid, false(), 128, 128)}
                <span class="img-actions-overlay">
                    <img src="/exist/apps/tamboti/themes/default/images/page_edit.png" style="width:16px;height:16px;cursor:pointer" alt="edit"/>
                </span>
            </div>
            <div>somethingsome</div>
        </body>
    </html>