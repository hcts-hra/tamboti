xquery version "3.1";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "application.xql";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

import module namespace retrieve = "http://hra.uni-heidelberg.de/ns/tamboti/retrieve" at "retrieve.xqm";

declare option exist:serialize "method=xhtml media-type=application/xhtml+xml enforce-xhtml=yes";

session:create()
,
let $parameters := parse-json(util:binary-to-string(request:get-data()))

(: Process request parameters and generate an XML representation of the query :)
let $query-as-xml := biblio:prepare-query2($parameters)

(: Get the results :)
let $query-as-regex := biblio:get-query-as-regex($query-as-xml)
let $null := session:set-attribute('regex', $query-as-regex)

let $results := biblio:get-or-create-cached-results2($query-as-xml, $parameters)

let $start := xs:int(request:get-parameter("start", 1))
let $count := xs:int(request:get-parameter("count", $config:number-of-items-per-page))

let $cors := response:set-header("Access-Control-Allow-Origin", "*")

return retrieve:retrieve($start, $count)
