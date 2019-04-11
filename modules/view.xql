xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";

declare option exist:serialize "method=xml media-type=application/xml";

declare variable $modules :=
    <modules>
        <module prefix="config" uri="http://exist-db.org/mods/config" at="config.xql"/>
        <module prefix="biblio" uri="http://exist-db.org/xquery/biblio" at="search/application.xql"/>
    </modules>;


let $content := request:get-data()

return
    jquery:process(
        templates:apply($content, $modules, ())
    )
