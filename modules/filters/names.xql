xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";
import module namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare option output:method "text";
declare option output:media-type "text/plain";

declare variable $local:SEARCH-COLLECTION := session:get-attribute('query');

let $start := util:system-time()

let $cached :=  session:get-attribute("mods:cached")

let $records := collection("/data/commons")
let $names := $records//mods:name
let $mods-names := for $author in $names return filters:format-name($author)
let $vra-names := $cached//vra:agentSet//vra:name[1]/text()
let $distinct-names := distinct-values(($mods-names, $vra-names))

let $result := "[[&quot;" || string-join($distinct-names, "&quot;], [&quot;") || "&quot;]]"

let $stop := util:system-time()

return $result


(:("Duration of execution: " || $stop - $start, $result):)


(:    <root>:)
(:    {:)
(::)
(:                                :)
(:                                for $name in $distinct-names:)
(:                                let $advanced-search-data :=:)
(:                                    <data>:)
(:                                        <filter>Name</filter>:)
(:                                        <value>{$name}</value>:)
(:                                        <query-tabs>advanced-search-form</query-tabs>:)
(:                                        <default-operator>and</default-operator>:)
(:                                        <collection>{$local:SEARCH-COLLECTION//collection/string()}</collection>:)
(:                                    </data>                                    :)
(:                                order by upper-case($name) empty greatest:)
(:                                return:)
(:                                    <li><a onclick="tamboti.apis.advancedSearchWithData(" href="#">{$name}</a></li>:)
(:        }:)
(:    </root>    :)
        
(:<li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{$name}</a></li>:)

(:<root>:)
(:{:)
(:    for $n in $m:)
(:    return:)
(:        <json:value json:array="true"><k>{$n/@id}</k><v>{$n}</v></json:value>:)
(:}:)
(:</root>:)
  