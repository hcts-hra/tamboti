xquery version "3.0";

declare function local:get-aces($collection-path as xs:anyURI) as element()* {
    (
        try {
            <collection path="{$collection-path}">{sm:get-permissions($collection-path)/*}</collection>
        } catch * {
            <error>{"Error at: " || $collection-path}</error>
        },
        for $subcollection in xmldb:get-child-collections($collection-path)
        return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection)),
        for $resource in xmldb:get-child-resources($collection-path)
        let $resource-path := xs:anyURI($collection-path || "/" || $resource)
        return
            try {
                <resource path="{$resource-path}">{sm:get-permissions($resource-path)/*}</resource>
            } catch * {
                <error>{"Error at: " || $resource-path}</error>
            }            
            
            
    )
};

let $permissions := local:get-aces(xs:anyURI("/resources/users"))

let $items-with-duplicated-aces := 
    for $item in $permissions
    let $who-attribute-values := $item/*[1]//sm:ace/@who/string()
    let $multiplicated-who-attribute-values := count($who-attribute-values[index-of($who-attribute-values, .)[2]])
    return 
        if ($multiplicated-who-attribute-values gt 0)
        then 
            for $i in (1, $multiplicated-who-attribute-values - 1)
            return $i
        else () 
        
return $items-with-duplicated-aces