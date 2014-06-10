xquery version "1.0";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";

declare option exist:serialize "method=html5 media-type=text/html";

declare variable $modules :=
    <modules>
        <module prefix="config" uri="http://exist-db.org/mods/config" at="config.xql"/>
        <module prefix="biblio" uri="http://exist-db.org/xquery/biblio" at="search/application.xql"/>
    </modules>;


let $content := request:get-data()
(:let $log := util:log("DEBUG", ($content)):)

let $no-cache := if( request:get-parameter( 'resource','something-else') = 'browse.html') then (
                      response:set-header( "Cache-Control",  'no-cache, no-store, max-age=0, must-revalidate' ),
                      response:set-header( "X-Content-Type-Options", 'nosniff' )
                 )else()

return
    jquery:process(
        templates:apply($content, $modules, ())
    )