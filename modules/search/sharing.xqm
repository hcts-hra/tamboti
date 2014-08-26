xquery version "3.0";

module namespace sharing="http://exist-db.org/mods/sharing";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace mail = "http://exist-db.org/xquery/mail";
import module namespace security = "http://exist-db.org/mods/security" at "security.xqm";
import module namespace functx="http://www.functx.com";

(: sets an ace on a collection and all the documents in that collection :)
declare function sharing:set-collection-ace-writeable($collection as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as xs:boolean {
    let $parent-collection-result :=
        if (security:set-ace-writeable($collection, $id, $is-writeable)) then
            (
                for $resource in xmldb:get-child-resources($collection)
                    let $useless := security:set-ace-writeable(xs:anyURI($collection || "/" || $resource), $id, $is-writeable)
                    return
                        ()
                ,
                true()
            )
        else false()
    return
        $parent-collection-result
};

(:~
 : toggles the ACE writable bit of a collection by target (USER/GROUP) and name
 : @param $collection the collection to remove ACE from
 : @param $target USER or GROUP
 : @param $name User- or groupname
 : @param $is-writeable writeable or not
 :)

declare function sharing:set-collection-ace-writeable-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string, $is-writeable as xs:boolean) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $parent-collection-result :=
            if (security:set-ace-writeable-by-name($collection, $target, $name, $is-writeable)) then
                (
                    for $resource in xmldb:get-child-resources($collection)
                        let $useless := security:set-ace-writeable-by-name(xs:anyURI($collection || "/" || $resource), $target, $name, $is-writeable)
                        return
                            ()
                    ,
                    true()
                )
            else false()
        return
            $parent-collection-result
    )
    
};


(: removes an ace on a collection and all the documents in that collection :)
declare function sharing:remove-collection-ace($collection as xs:anyURI, $id as xs:int)  {
    let $removed := security:remove-ace($collection, $id) 
    return
        if(exists(fn:not(fn:empty($removed))))then(
            for $resource in xmldb:get-child-resources($collection)
            let $resource-path := fn:concat($collection, "/", $resource) 
            return
                if(not(empty(security:remove-ace($resource-path, $id)))) then
                    true()
                else
                    fn:error(xs:QName("sharing:remove-collection-ace"), fn:concat("Could not remove ace at index '", $id, "' for '", $resource-path, "'"))
            ,
            if ($removed[1] eq "USER") then
                sharing:send-share-user-removal-mail($collection, $removed[2])
            else 
                if($removed[1] eq "GROUP") then
                    sharing:send-share-group-removal-mail($collection, $removed[2])
                else()
            ,
            true()
        )
        else
           false()
};

(: removes an ace on a collection and all the documents in that collection by ACE target and name:)
declare function sharing:remove-collection-ace-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string)  {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],(
        let $removed := security:remove-ace-by-name($collection, $target, $name)
        return 
            if(exists($removed)) then
            (
                for $resource in xmldb:get-child-resources($collection)
                    let $resource-path := $collection || "/" || $resource
                    return 
                        if (not(empty(security:remove-ace-by-name($resource-path, $target, $name)))) then
                            true()
                        else
                            fn:error(xs:QName("sharing:remove-collection-ace-by-name"), "Could not remove ace for " || $target  || " '" || $name || "' for '" || $resource-path || "'")
                ,
                if ($removed[1] eq "USER") then
                    sharing:send-share-user-removal-mail($collection, $removed[2])
                else 
                    if($removed[1] eq "GROUP") then
                        sharing:send-share-group-removal-mail($collection, $removed[2])
                    else()
                ,
                true()
            )
            else
               false()                        
        ()
        )
    )
};


(: adds a user ace on a collection, and also to all the documents in that collection (at the same acl index) :)
declare function sharing:add-collection-user-ace($collection as xs:anyURI, $username as xs:string) as xs:int {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],    
(:        let $collection := xs:anyURI(xmldb:encode($collection)):)
        (: check for existing user ACE :)
        let $user-ace := sm:get-permissions(xs:anyURI($collection))//sm:ace[@target="USER" and @who=$username]
            return
                if (count($user-ace) > 0) then 
                    fn:error(xs:QName("sharing:add-collection-user-ace"), "ACE for user already exists")
                else
                    let $id := security:add-user-ace($collection, $username, "r-x")
                        return
                            if (fn:not(fn:empty($id)))
                                then
                                    (
                                        for $resource in xmldb:get-child-resources($collection)
                                            let $resource-path := fn:concat($collection, "/", $resource) return
                                                if (not(empty(security:add-user-ace($resource-path, $username, "r-x")))) then
                                                    ()
                                                else
                                                    fn:error(xs:QName("sharing:add-collection-user-ace"), fn:concat("Could not add ace for '", $username , "' for '", $resource-path, "'"))
                                        ,
                                        let $send-email :=
                                            (: do not send notification email if function is called recursively on VRA_images :)
                                            if (not(functx:substring-after-last($collection, "/") = "VRA_images")) then
                                                sharing:send-share-user-invitation-mail($collection, $username)
                                            else
                                                ()
                                        return
                                            $id
                                    )
                                else -1
    )
};

(: adds a group ace on a collection, and also to all the documents in that collection (at the same acl index) :)
declare function sharing:add-collection-group-ace($collection as xs:anyURI, $groupname as xs:string) as xs:int {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        (: check for existing group ACE :)
        let $group-ace := sm:get-permissions(xs:anyURI($collection))//sm:ace[@target="GROUP" and @who=$groupname]
            return
                if (count($group-ace) > 0) then 
                    fn:error(xs:QName("sharing:add-collection-group-ace"), "ACE for group already exists")
                else
                    let $id := security:add-group-ace($collection, $groupname, "r--")
                        return
                            if (fn:not(fn:empty($id)))
                                then
                                    (
                                        (: add ACE to child resources :)
                                        for $resource in xmldb:get-child-resources($collection)
                                        let $resource-path := fn:concat($collection, "/", $resource) return
                                            if(not(empty(security:add-group-ace($resource-path, $groupname, "r--"))))then
                                                ()
                                            else
                                                fn:error(xs:QName("sharing:add-collection-group-ace"), fn:concat("Could not insert ace at index '", $id, "' for '", $resource-path, "'")),
                                        let $send-email :=
                                            (: do not send notification email if function is called recursively on VRA_images :)
                                            if (not(functx:substring-after-last($collection, "/") = "VRA_images")) then
                                                sharing:send-share-group-invitation-mail($collection, $groupname)
                                            else
                                                ()
                                        return
                                            $id
                                    )
                                else -1
    )
};

declare function sharing:send-share-user-invitation-mail($collection-path as xs:string, $username as xs:string) as empty()
{
    if($config:send-notification-emails)then
        let $mail-template := fn:doc(fn:concat($config:search-app-root, "/group-invitation-email-template.xml")) return
            mail:send-email(sharing:process-email-template($mail-template, $collection-path, $username), $config:smtp-server, ())
    else()
};

declare function sharing:send-share-group-invitation-mail($collection-path as xs:string, $groupname as xs:string) as empty()
{
    if($config:send-notification-emails)then
        for $group-member in security:get-group-members($groupname) return
            sharing:send-share-user-invitation-mail($collection-path, $group-member)
    else()
};

declare function sharing:send-share-user-removal-mail($collection-path as xs:string, $username as xs:string) as empty()
{
    if($config:send-notification-emails)then
        let $mail-template := fn:doc(fn:concat($config:search-app-root, "/group-removal-email-template.xml")) return
            mail:send-email(sharing:process-email-template($mail-template, $collection-path, $username), $config:smtp-server, ())
    else()
};

declare function sharing:send-share-group-removal-mail($collection-path as xs:string, $groupname as xs:string) as empty()
{
    if($config:send-notification-emails)then
        for $group-member in security:get-group-members($groupname) return
            sharing:send-share-user-removal-mail($collection-path, $group-member)
    else()
};

declare function sharing:process-email-template($element as element(), $collection-path as xs:string, $username as xs:string) as element() {
    element {node-name($element) } {
        $element/@*,
        for $child in $element/node() return
            if ($child instance of element()) then
            (
                if(fn:node-name($child) eq xs:QName("config:smtp-from-address"))then
                (
                    text { $config:smtp-from-address }
                )
                else if(fn:node-name($child) eq xs:QName("sharing:user-smtp-address"))then
                (
                    text { security:get-email-address-for-user($username) }
                )
                else if(fn:node-name($child) eq xs:QName("sharing:collection-path"))then
                (
                    text { $collection-path }
                )
                else if(fn:node-name($child) eq xs:QName("sharing:user-name"))then
                (
                    text { $username }
                )
                else
                (
                    sharing:process-email-template($child, $collection-path, $username)
                )
            )
            else
            (
                $child
            )
    }
};

declare function sharing:get-shared-collection-roots($write-required as xs:boolean) as xs:string* {
    let $user-id := security:get-user-credential-from-session()[1]
    
    return
        if (fn:not(($user-id eq 'guest')))
        then
            system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
                for $child-collection in xmldb:get-child-collections($config:users-collection)
                let $child-collection-path := fn:concat($config:users-collection, "/", $child-collection)
                
                return
                    for $user-subcollection in xmldb:get-child-collections($child-collection-path)
                    let $user-subcollection-path := fn:concat($child-collection-path, "/", $user-subcollection)
                    let $ace-mode := data(sm:get-permissions(xs:anyURI($user-subcollection-path))//sm:ace[@who = $user-id]/@mode)
                    
                    return
                        if ($write-required)
                        then
                            if (contains($ace-mode, 'w'))
                                then $user-subcollection-path
                                else ()                            
                        else
                            if (contains($ace-mode, 'r'))
                                then $user-subcollection-path
                                else ()
        )
    else()
};

declare function sharing:recursively-get-shared-subcollections($collection as xs:anyURI, $write-required as xs:boolean) as xs:string* {
    let $user-id := security:get-user-credential-from-session()[1]
    let $ace-mode := data(sm:get-permissions($collection)//sm:ace[@who = $user-id]/@mode)

    return
            if (fn:not(($user-id eq 'guest'))) then
                (
                system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
                        if ($write-required) then
                            if (contains($ace-mode, 'w')) then 
                                    $collection
                            else 
                                ()                            
                        else
                            if (contains($ace-mode, 'r')) then 
                                $collection
                            else 
                                ()
                    )
                    ,
                    (: recursively call function for all subcollections:)
                    for $child-collection in xmldb:get-child-collections($collection)
                    order by $child-collection ascending
                        return sharing:recursively-get-shared-subcollections(xs:anyURI($collection || "/" || $child-collection), $write-required)   
                )
            else
                ()
};

declare function sharing:get-shared-with($collection-path as xs:string) as xs:string* {
    (:
    let $permissions := sm:get-permissions(xs:anyURI($collection-path))/sm:permission,
    $mode := $permissions/@mode return
    fn:string-join(
        (
        if(fn:matches($mode, "...r....."))then
            "Biblio users"
        else(),
        if(fn:matches($mode, "......r.."))then
            "Anyone"
        else(),
        for $ace in $permissions/sm:acl/sm:ace[@access_type eq "ALLOWED"] return
            sm:get-account-metadata($ace/@who, xs:anyURI("http://axschema.org/namePerson"))
        ),
        ", "
    )
    :)
     ()
};

declare function sharing:is-valid-user-for-share($username as xs:string) as xs:boolean
{
    $username ne security:get-user-credential-from-session()[1] and (fn:contains($username, "@") or sm:user-exists($username) or security:is-biblio-user($username))
};

declare function sharing:is-valid-group-for-share($groupname as xs:string) as xs:boolean
{
    $groupname != ("SYSTEM", "guest", $config:biblio-users-group)
};