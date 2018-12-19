xquery version "3.1";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

declare variable $user-folder-icon := "../skin/ltFld.user.gif";
declare variable $groups-folder-icon := "../skin/ltFld.groups.gif";
declare variable $writeable-folder-icon := "../skin/ltFld.page.png";
declare variable $not-writeable-folder-icon := "../skin/ltFld.locked.png";
declare variable $writeable-and-shared-folder-icon := "../skin/ltFld.page.link.png";
declare variable $not-writeable-and-shared-folder-icon := "../skin/ltFld.locked.link.png";
declare variable $commons-folder-icon := "../skin/ltFld.png";
declare variable $collections-to-skip-for-all := ('VRA_images');

declare function local:lazy-read($collection-uri as xs:anyURI) {
    (: if searching for shared collections, do not display shares in own home collection:)
    let $skip-collections :=
        if ( ($collection-uri = $config:users-collection) ) then
            ($collections-to-skip-for-all, xmldb:encode(security:get-user-credential-from-session()[1]))
        else
            $collections-to-skip-for-all

    (: elevate rights for going into the collection structure :)
    let $subcollections := 
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], (
                xmldb:get-child-collections($collection-uri)
            )
        )

    for $subcol in $subcollections
    order by lower-case($subcol)
    return
        let $fullpath := xs:anyURI($collection-uri || "/" || $subcol)
        let $readable := security:can-read-collection($fullpath)
        let $executeable := security:can-execute-collection($fullpath) 
        let $writeable := security:can-write-collection($fullpath) 
        let $readable-children := local:has-readable-children($fullpath)
        let $is-owner := security:is-collection-owner(security:get-user-credential-from-session()[1],  $fullpath)
        let $extra-classes := (
            if ($writeable)
            then 'fancytree-writeable' 
            else 'fancytree-readable'
            ,
            if ($is-owner and count(security:get-acl($fullpath)) > 0 )
            then 'fancytree-shared'
(:                            <icon>{$writeable-and-shared-folder-icon}</icon>:)
            else ()
        )
        return
            if (not($skip-collections = $subcol) and (($readable and $executeable) or not(empty($readable-children))))
            then map:merge((
                map {
                    "title": xmldb:decode($subcol),
                    "key": xmldb:decode($fullpath),
                    "folder": true(),
                    "writeable": $writeable,
                    "lazy": true(),
                    "extraClasses": $extra-classes
                }                
                ,
                if (exists($readable-children))
                then map {"children": $readable-children}
                else ()
                ,
                if ($is-owner and count(security:get-acl($fullpath)) > 0)
                then () (: "icon": $writeable-and-shared-folder-icon :)
                else ()                
            ))                
            else array {()}
};

declare function local:has-readable-children($collection-uri as xs:anyURI) {
    (: if searching for shared collections, do not display shares in own home collection:)
    let $collections-to-skip-for-all := ('VRA_images')
    let $skip-collections :=
        if ($collection-uri = $config:users-collection)
        then ($collections-to-skip-for-all, xmldb:encode(security:get-user-credential-from-session()[1]))
        else $collections-to-skip-for-all

    (: elevate rights for going into the collection structure :)
    let $subcollections := 
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], (
                xmldb:get-child-collections($collection-uri)
            )
        )
    for $subcol in $subcollections
    order by lower-case($subcol)
    return
        let $fullpath := xs:anyURI($collection-uri || "/" || $subcol)
        let $readable := security:can-read-collection($fullpath)
        let $executeable := security:can-execute-collection($fullpath) 
        let $writeable := security:can-write-collection($fullpath) 
        let $readable-children := local:has-readable-children($fullpath)
        let $is-owner := security:is-collection-owner(security:get-user-credential-from-session()[1],  $fullpath)
        let $extra-classes := (
            if ($writeable)
            then 'fancytree-writeable' 
            else 'fancytree-readable'
            ,
            if ($is-owner and count(security:get-acl($fullpath)) > 0 )
            then
(:                            <icon>{$writeable-and-shared-folder-icon}</icon>:)
                'fancytree-shared'
            else ()
        )
        
        return
            if (not($skip-collections = $subcol) and (($readable and $executeable) or not(empty($readable-children))))
            then map:merge((
                map {
                    "title": xmldb:decode($subcol),
                    "key": xmldb:decode($fullpath),
                    "folder": true(),
                    "writeable": $writeable,
                    "lazy": true(),
                    "extraClasses": $extra-classes
                }
                ,
                if (exists($readable-children))
                then map {"children": $readable-children}
                else ()
                ,
                if ($is-owner and count(security:get-acl($fullpath)) > 0)
                then () (: "icon": $writeable-and-shared-folder-icon :)
                else ()                 
            ))
            else ()

};

(:~
: Request routing
:
: If the http querystring parameter key exists then we retrieve tree nodes based on this
: key which is basically a real or virtual (for groups) collection path.
: If there is no key we deliver the tree root
:)

(: if no key is submitted, take the predefined root collection :)
let $key := request:get-parameter("key", ())

return
(: if no key is submitted, build up the full tree :)
if (not($key))
then
    let $user-id := security:get-user-credential-from-session()[1]
    let $user-home-dir := security:get-home-collection-uri($user-id)

    return array {
        map {
            "title": $config:data-collection-name,
            "key": "/" || xmldb:decode($config:data-collection-name),
            "folder": true(),
            "writeable": false(),
            "extraClasses": "fancytree-readable",
            "expanded": true(),
            "lazy": true(),
            "children": array {
                if (not($user-id = "guest"))
                then map:merge((
                    map {
                        "title": "Home",
                        "key": xmldb:decode($user-home-dir),
                        "folder": true(),
                        "writeable": security:can-write-collection($user-home-dir),
                        "extraClasses": "fancytree-readable",
                        "expanded": true(),
                        "lazy": true()
                    } 
                    ,
                    let $readable-children := local:has-readable-children(xs:anyURI($user-home-dir))
                    
                    return
                        if (exists($readable-children))
                        then map {"children": $readable-children}
                        else ()
                ))
                else ()
                ,
                map {
                    "title": "Shared",
                    "key": xmldb:decode($config:users-collection),
                    "folder": true(),
                    "writeable": false(),
                    "extraClasses": "fancytree-readable",
                    "lazy": true()             
                },
                map:merge((
                    map {
                        "title": "Commons",
                        "key": xmldb:decode($config:mods-commons),
                        "folder": true(),
                        "writeable": false(),
                        "extraClasses": "fancytree-readable",
                        "expanded": true(),
                        "lazy": true()
                    }  
                    ,
                    let $readable-children := local:has-readable-children(xs:anyURI($config:mods-commons))
                    
                    return
                        if (exists($readable-children))
                        then map {"children": $readable-children}
                        else ()
                ))                    
            }
        }
    }
else
    (: load a defined branch (lazy) :)
    let $child-branch := local:lazy-read(xmldb:encode-uri($key))
    return 
        if (exists($child-branch))
        then $child-branch
        else ()
