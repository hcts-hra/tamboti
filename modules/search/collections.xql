xquery version "3.0";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace json="http://www.json.org";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace functx = "http://www.functx.com";

declare namespace col = "http://library/search/collections";

declare option exist:serialize "method=json media-type=text/javascript";


declare variable $user-folder-icon := "../skin/ltFld.user.gif";
declare variable $groups-folder-icon := "../skin/ltFld.groups.gif";
declare variable $writeable-folder-icon := "../skin/ltFld.page.png";
declare variable $not-writeable-folder-icon := "../skin/ltFld.locked.png";
declare variable $writeable-and-shared-folder-icon := "../skin/ltFld.page.link.png";
declare variable $not-writeable-and-shared-folder-icon := "../skin/ltFld.locked.link.png";
declare variable $commons-folder-icon := "../skin/ltFld.png";
declare variable $collections-to-skip-for-all := ('VRA_images');

declare function col:lazy-read($collection-uri as xs:anyURI) {
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
    order by $subcol
    return
        let $fullpath := xs:anyURI($collection-uri || "/" || $subcol)
        let $readable := security:can-read-collection($fullpath)
        let $executeable := security:can-execute-collection($fullpath) 
        let $writeable := security:can-write-collection($fullpath) 
        let $readable-children := col:has-readable-children($fullpath)
        let $is-owner := security:is-collection-owner(security:get-user-credential-from-session()[1],  $fullpath)
        let $extra-classes := (
            if($writeable) then 
                'fancytree-writeable' 
            else 
                'fancytree-readable'
            ,
            if ($is-owner and count(security:get-acl($fullpath)) > 0 ) then
(:                            <icon>{$writeable-and-shared-folder-icon}</icon>:)
                'fancytree-shared'
            else ()
        )
        return
            if (not($skip-collections = $subcol) and (($readable and $executeable) or not(empty($readable-children)))) then
                <json:value json:array="true">
                    <title>{xmldb:decode($subcol)}</title>
                    <key>{xmldb:decode($fullpath)}</key>
                    <folder json:literal="true">true</folder>
                    <writeable json:literal="true">{$writeable}</writeable>
                    <lazy json:literal="true">true</lazy>
                    {
                        $readable-children
                    }
                    <extraClasses>
                    {
                        $extra-classes
                    }
                    </extraClasses>
                </json:value>
            else
                ()
};

declare function col:has-readable-children($collection-uri as xs:anyURI) {
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
    order by $subcol 
    return
        let $fullpath := xs:anyURI($collection-uri || "/" || $subcol)
        let $readable := security:can-read-collection($fullpath)
        let $executeable := security:can-execute-collection($fullpath) 
        let $writeable := security:can-write-collection($fullpath) 
        let $readable-children := col:has-readable-children($fullpath)
        let $is-owner := security:is-collection-owner(security:get-user-credential-from-session()[1],  $fullpath)
        let $extra-classes := (
            if($writeable) then 
                'fancytree-writeable' 
            else 
                'fancytree-readable'
            ,
            if ($is-owner and count(security:get-acl($fullpath)) > 0 ) then
(:                            <icon>{$writeable-and-shared-folder-icon}</icon>:)
                'fancytree-shared'
            else ()
        )
        
        return
            if (not($skip-collections = $subcol) and (($readable and $executeable) or not(empty($readable-children)))) then
                <children json:array="true">
                    <title>{xmldb:decode($subcol)}</title>
                    <key>{xmldb:decode($fullpath)}</key>
                    <folder json:literal="true">true</folder>
                    <writeable json:literal="true">{$writeable}</writeable>
                    <lazy json:literal="true">true</lazy>
                    {
                        if ($is-owner and count(security:get-acl($fullpath)) > 0 ) then
                            ()
(:                            <icon>{$writeable-and-shared-folder-icon}</icon>:)
                        else ()
                    }
                    {
                        $readable-children
                    }
                    <extraClasses>
                        {
                            $extra-classes
                        }
                    </extraClasses>                        
                </children>
            else
                ()

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
(:let $active-key := request:get-parameter("activeKey",()):)
(:let $expanded-key-list := fn:tokenize(request:get-parameter("expandedKeyList", ()), ","):)
(:let $focused-key := request:get-parameter("focusedKey",()):)
return

(: if no key is submitted, build up the full tree :)
if (not($key)) then
    let $user-id := security:get-user-credential-from-session()[1]
    let $user-home-dir := security:get-home-collection-uri($user-id)

    return
            <something>
                {
                    (: no home for guest :)
                    if(not($user-id = "guest")) then
                        <json:value>
                            <title>Home</title>
                            <key>{xmldb:decode($user-home-dir)}</key>
                            <folder json:literal="true">true</folder>
                            <writeable json:literal="true">{security:can-write-collection($user-home-dir)}</writeable>
                            <extraClasses>fancytree-writeable</extraClasses>
                            <expanded json:literal="true">true</expanded>
                            <lazy json:literal="true">true</lazy>
                            {
                                (: construct the home branch:)
                                let $child-branch := col:has-readable-children(xs:anyURI($user-home-dir))
                                return
                                    $child-branch
                            }
                        </json:value>
                    else
                        ()
                }
                <json:value>
                    <title>Shared</title>
                    <key>{xmldb:decode($config:users-collection)}</key>
                    <folder json:literal="true">true</folder>
                    <writeable json:literal="true">false</writeable>
                    <lazy json:literal="true">true</lazy>
                    <extraClasses>fancytree-readable</extraClasses>
                </json:value>
                <json:value>
                    <title>Commons</title>
                    <key>{xmldb:decode($config:mods-commons)}</key>
                    <writeable json:literal="true">false</writeable>
                    <extraClasses>fancytree-readable</extraClasses>
                    <folder json:literal="true">true</folder>
                    <expanded json:literal="true">true</expanded>
                    <lazy json:literal="true">true</lazy>
                        {
                            (: construct the commons branch:)
                            let $child-branch := col:has-readable-children(xs:anyURI($config:mods-commons))
                            return
                                $child-branch
                        }
                </json:value>
            </something>
else
    (: load a defined branch (lazy) :)
    let $child-branch := col:lazy-read(xmldb:encode-uri($key))
    return 
        if($child-branch) then
            <json:value>
            {
                $child-branch
            }
            </json:value>
        else
            <json:value json:array="true" />

