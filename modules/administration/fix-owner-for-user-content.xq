xquery version "3.0";

import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";

declare function local:set-owner($path) {
    (
    let $owner := tamboti-utils:get-username-from-path($path) 
    return
        (
        for $collection in xmldb:get-child-collections($path)
        let $collection-path := xs:anyURI($path || "/" || $collection)
        return
            (
                <collection name="{$collection}" path="{$path}">
                    <owner>{$owner}</owner>
                </collection>
            ,
                if (ends-with($collection-path, 'VRA_images'))
                then
                    (
                        sm:chown($collection-path, $owner)
                        ,
                        sm:get-permissions($collection-path)
                    )
                else ()
                ,
                local:set-owner($collection-path)
            )
        ,
        for $resource in xmldb:get-child-resources($path)
        return
            <resource name="{$resource}" path="{$path}">
                <owner>{$owner}</owner>
            </resource>
        )
    )
};

let $path := "/resources/users" 
return
    <result>
        {
            for $user-collection-name in xmldb:get-child-collections($path)
            return local:set-owner($path || "/" || $user-collection-name)
        }
    </result>