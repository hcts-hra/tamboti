xquery version "3.0";

declare function local:get-aces($collection-path as xs:anyURI) as element()* {
    (
        try {
            sm:get-permissions($collection-path)/*
        } catch * {
            <collection path="Error: {$collection-path}">{"Error '" || $err:description || "' at: " || $collection-path}</collection>
        }
        ,
        for $subcollection in xmldb:get-child-collections($collection-path)
        return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection))
    )
};

let $start := util:system-time()

let $aces-as-admin := system:as-user("admin", "Wars4Spass2$s", count(local:get-aces(xs:anyURI("/resources/users"))))

let $aces-as-guest := system:as-user("editor", "***REMOVED***", count(local:get-aces(xs:anyURI("/resources/users"))))

let $end := util:system-time()

let $duration := $end - $start


return ("aces-as-admin " || $aces-as-admin, ", aces-as-non-admin " || $aces-as-guest, ", duration " || $duration)
