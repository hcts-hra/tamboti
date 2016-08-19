xquery version "3.0";

import module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/" at "filters.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "text";
declare option output:media-type "text/plain";

let $cached :=  session:get-attribute("mods:cached")

let $keywords := filters:keywords($cached)

let $result := "[[&quot;" || string-join($keywords, "&quot;], [&quot;") || "&quot;]]"

return $result
