xquery version "3.0";

module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports";

import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare function local:get-aces($collection-path as xs:anyURI) as element()* {
    (
        try {
            <collection path="{$collection-path}">{sm:get-permissions($collection-path)/*}</collection>
        } catch * {
            <error>{"Error '" || $err:description || "' at: " || $collection-path}</error>
        }
        ,
        for $subcollection in xmldb:get-child-collections($collection-path)
        return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection))
        ,
        for $resource in xmldb:get-child-resources($collection-path)
        let $resource-path := xs:anyURI($collection-path || "/" || $resource)
        return
            try {
                <resource path="{$resource-path}">{sm:get-permissions($resource-path)/*}</resource>
            } catch * {
                <error>{"Error '" || $err:description || "' at: " || $resource-path}</error>
            }
    )
};

declare function reports:get-permissions($collection-paths as xs:string*) as element()* {
    for $collection-path in $collection-paths
    return
        for $subcollection in xmldb:get-child-collections($collection-path)
            return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection))
    
};

declare variable $reports:permission-elements := reports:get-permissions(($config:mods-commons, $config:users-collection));
declare variable $reports:permission-elements-number := count($reports:permission-elements//sm:permission);
declare variable $reports:orphaned-users :=
    for $user-account-file-name in xmldb:get-child-resources("/db/system/security/LDAP/accounts")[not(contains(., '@ad.uni-heidelberg.de'))]
    return substring-before($user-account-file-name, '.xml')
;

declare variable $reports:items-with-duplicated-aces := 
    for $item in $reports:permission-elements
    let $whos := $item/*[1]//sm:ace/@who/string()
    let $duplicated-whos := $whos[index-of($whos, .)[2]]
    return
        if (count($duplicated-whos) gt 0)
        then map{
            "item" := $item,
            "duplicated-whos" := $duplicated-whos
        }
        else ()
;

declare variable $reports:items-with-orphaned-users := 
    for $item in $reports:permission-elements
    let $username-attrs := ($item/sm:permission/@owner, $item//sm:ace/@who)
    return
        for $username-attr in $username-attrs
        let $orphaned-username := data($username-attr)
        return
            if ($orphaned-username = $reports:orphaned-users)
            then map{
                "item" := $username-attr/parent::*/ancestor::*[last()],
                "orphaned-username" := $orphaned-username
            }            
            else ()
;

declare variable $reports:items-with-encoded-at-sign := 
    for $item in $reports:permission-elements
    let $item-path := $item/@path/string()
    return
        if (contains($item-path, '%40'))
        then $item
        else ()
;
