xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:set-owner($path) {
    (
    let $owner :=
        if (contains($path, $config:users-collection))
        then sm:get-permissions(xs:anyURI($path))/*/@owner
        else "editor"    
    return
        (
        sm:chown(xs:anyURI($path), $owner)
        ,
        for $collection in xmldb:get-child-collections($path)
        let $collection-path := xs:anyURI($path || "/" || $collection)
        return
            (
                <collection name="{$collection}" path="{$path}">
                    <owner>{$owner}</owner>
                </collection>
                ,
                sm:chown($collection-path, $owner)
                        ,
                sm:get-permissions($collection-path)
                ,
                local:set-owner($collection-path)
            )
        ,
        for $resource in xmldb:get-child-resources($path)
        let $resource-path := xs:anyURI($path || "/" || $resource)
        return
            (
                <resource name="{$resource}" path="{$path}">
                    <owner>{$owner}</owner>
                </resource>
                ,
                sm:chown($resource-path, $owner)
                ,
                sm:get-permissions($resource-path)
            )
        )
    )
};

<result>
    {
        for $collection-path in $reports:collections
        return
            for $collection-name in xmldb:get-child-collections(xmldb:encode-uri($collection-path))
            return local:set-owner($collection-path || "/" || $collection-name) 
    }
</result>
