xquery version "3.0";

declare namespace ns="http://exist-db.org/Configuration";
declare namespace sm="http://exist-db.org/xquery/securitymanager";

declare variable $local:security-uri := xs:anyURI("/db/system/security/");
declare variable $local:data-collection := xs:anyURI("/db/");


declare function local:set-security-permissions($uri) {
    for $file in xmldb:get-child-resources($uri)
    let $path := xs:anyURI($uri || "/" || $file)
        return
            (
            sm:chown($path, "SYSTEM")
            ,
            sm:chgrp($path, "dba")
            ,
            sm:chmod($path, "rwxrwx---")
            ,
            for $subdir in xmldb:get-child-collections($uri)
            return
                local:set-security-permissions(xs:anyURI($uri || "/" || $subdir))
            )
};

declare function local:search-duplicate-user-ids() {
    let $col := collection($local:security-uri)
    let $user-ids := data($col//ns:account/@id)
    return
        $user-ids[index-of($user-ids,.)[2]]
};

declare function local:search-duplicate-user-names() {
    let $col := collection($local:security-uri)
    let $user-names := data($col//ns:account/ns:name)
    let $duplicate-names := $user-names[index-of($user-names,.)[2]]
    for $name in $duplicate-names
    return
        <duplicate-username>
            <name>{$name}</name>
            {
                for $node in $col//ns:account[ns:name = $name]
                return
                    <document>
                        {
                            util:document-name($node)
                        }
                    </document>
            }
        </duplicate-username>
};

declare function local:search-duplicate-group-names() {
    let $col := collection($local:security-uri)
    let $group-names := data($col//ns:group/ns:name)
    let $duplicate-names := $group-names[index-of($group-names,.)[2]]
    for $name in $duplicate-names
    return
        <duplicate-groupname>
            <name>{$name}</name>
            {
                for $node in $col//ns:group[ns:name = $name]
                return
                    <document>
                        {
                            util:document-name($node)
                        }
                    </document>
            }
        </duplicate-groupname>
};


declare function local:search-duplicate-group-ids() {
    let $col := collection($local:security-uri)
    let $group-ids := data($col//ns:group/@id)
    return
        $group-ids[index-of($group-ids,.)[2]]
};


declare function local:recursively-remove-all-aces-for-user($user-id, $collection-uri as xs:anyURI) {
        let $index-col := sm:get-permissions($collection-uri)//sm:ace[@target="USER" and @who=$user-id]
        return
        (
            if($index-col) then
                (
                    sm:remove-ace($collection-uri, data($index-col/@index))
                    ,
                    <removed-ace-from>{$collection-uri}</removed-ace-from>
                )
            else
                ()
            ,
            for $resource in xmldb:get-child-resources($collection-uri)
                let $fullpath := xs:anyURI($collection-uri || "/" || $resource)
                let $index := sm:get-permissions($fullpath)//sm:ace[@target="USER" and @who=$user-id]
                return
                    if($index) then
                        (
                            sm:remove-ace($fullpath, data($index/@index))
                            ,
                            <removed-ace-from>{$fullpath}</removed-ace-from>
                        )
                    else 
                        ()
                        
        ,
        for $child in xmldb:get-child-collections($collection-uri)
        return
            local:recursively-remove-all-aces-for-user($user-id, xs:anyURI($collection-uri || "/" || $child))
)
};

declare function local:recursively-get-all-aces-for-user($user-id, $collection-uri as xs:anyURI) {
        let $index-col := sm:get-permissions($collection-uri)//sm:ace[@target="USER" and @who=$user-id]
        return
        (
            if($index-col) then
            <collection>
                <path>
                    {$collection-uri}
                </path>
                <index>
                {
                    data($index-col/@index)
                }
                </index>
            </collection>
            else
                ()
            ,
            for $resource in xmldb:get-child-resources($collection-uri)
                let $fullpath := xs:anyURI($collection-uri || "/" || $resource)
                let $index := sm:get-permissions($fullpath)//sm:ace[@target="USER" and @who=$user-id]
                return
                    if($index) then
                        <resource>
                            <path>
                            {
                                $fullpath
                            }
                            </path>
                            <index>
                            {
                                data($index/@index)
                            }
                            </index>
                        </resource>
                    else 
                        ()
                        
        ,
        for $child in xmldb:get-child-collections($collection-uri)
        return
            local:recursively-get-all-aces-for-user($user-id, xs:anyURI($collection-uri || "/" || $child))
)
};

declare function local:recursively-get-all-aces-for-group($group-id, $collection-uri as xs:anyURI) {
    let $index-col := sm:get-permissions($collection-uri)//sm:ace[@target="GROUP" and @who=$group-id]
    return
    (
        if($index-col) then
            <collection>
                <path>
                    {$collection-uri}
                </path>
                <index>
                {
                    data($index-col/@index)
                }
                </index>
            </collection>
        else
            ()
        ,
        for $resource in xmldb:get-child-resources($collection-uri)
            let $fullpath := xs:anyURI($collection-uri || "/" || $resource)
            let $index := sm:get-permissions($fullpath)//sm:ace[@target="GROUP" and @who=$group-id]
            return
                if($index) then
                    <resource>
                        <path>
                        {
                            $fullpath
                        }
                        </path>
                        <index>
                        {
                            data($index/@index)
                        }
                        </index>
                    </resource>
                else 
                    ()
                    
    ,
    for $child in xmldb:get-child-collections($collection-uri)
    return
        local:recursively-get-all-aces-for-group($group-id, xs:anyURI($collection-uri || "/" || $child))
)
};


<div>
    <div>Checking for duplicate users and groups (names and IDs)</div>
    <div>
    {
        local:search-duplicate-user-names(),
        local:search-duplicate-group-names()
        ,
        <div>
            {
            local:search-duplicate-group-ids()
            }
        </div>
        ,
        <div>
            {
            local:search-duplicate-user-ids()
            }
        </div>
    }
    </div>
</div>

