xquery version "3.0";

declare function local:get-resources($collection) {
    for $resource in xmldb:get-child-resources($collection)
    
    return (
      local:date-from-dateTime(xmldb:last-modified($collection, $resource)),
      if (exists(xmldb:get-child-collections($collection)))
        then (
           for $child in xmldb:get-child-collections($collection)
           
           return local:get-resources(concat($collection, '/', $child))
           )
         else ()
    )
};

declare function local:date-from-dateTime($date-time) {
    format-dateTime($date-time, "[Y0001]-[M01]-[D01]")
};

declare function local:collection-last-modified($collection-name, $collection-path) {
    let $resources := local:get-resources($collection-path)
    let $creator := sm:get-permissions(xs:anyURI($collection-path))//@owner
    
    return string-join(($collection-name, $collection-path, $creator, count($resources), max(distinct-values($resources) ! xs:date(.))), ',') || "&#10;"
};

let $collections := ("/resources/commons/", "/resources/users")

for $collection in $collections

return
    xmldb:store("/db/resources", "collection-metadata.xml",
        <metadata>
            {
                for $child-collection-name in xmldb:get-child-collections($collection)
                
                return local:collection-last-modified($child-collection-name, $collection || $child-collection-name)                
            }
        </metadata>
    )
