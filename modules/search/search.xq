xquery version "3.0";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "application.xql";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

import module namespace retrieve = "http://hra.uni-heidelberg.de/ns/tamboti/retrieve" at "retrieve.xqm";

declare option exist:serialize "method=xhtml media-type=application/xhtml+xml enforce-xhtml=yes";

session:create()
,

(: We receive an HTML template as input :)
(:the search field passed in the url:)
let $filter := request:get-parameter("filter", ())
(:the search term for added filters passed in the url:)
let $search-field := request:get-parameter("search-field", ())
(:the search term for new sarches passed in the url:)
let $value := request:get-parameter("value", ())
let $history := request:get-parameter("history", ())
let $reload := request:get-parameter("reload", ())
let $clear := request:get-parameter("clear", ())
let $mylist := request:get-parameter("mylist", ()) (:clear, display:)

let $collection := xmldb:encode-uri(request:get-parameter("collection", $config:mods-root))

let $collection := if (starts-with($collection, "/db")) then $collection else concat("/db", $collection)


let $id := request:get-parameter("id", ())
let $sort := request:get-parameter("sort", ())

(: Process request parameters and generate an XML representation of the query :)
let $query-as-xml := biblio:prepare-query($id, $collection, $reload, $history, $clear, $filter, $search-field, $mylist, $value)
(: Get the results :)
let $query-as-regex := biblio:get-query-as-regex($query-as-xml)
let $null := session:set-attribute('regex', $query-as-regex)
let $results := biblio:get-or-create-cached-results($mylist, $query-as-xml, $sort)

let $start := xs:int(request:get-parameter("start", 1))
let $count := xs:int(request:get-parameter("count", $config:number-of-items-per-page))

let $cors := response:set-header("Access-Control-Allow-Origin", "*")

return retrieve:retrieve($start, $count)
