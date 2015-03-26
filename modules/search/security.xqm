xquery version "3.0";

module namespace security = "http://exist-db.org/mods/security";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";

declare variable $security:GUEST_CREDENTIALS := ("guest", "guest");
declare variable $security:SESSION_USER_ATTRIBUTE := "biblio.user";
declare variable $security:SESSION_PASSWORD_ATTRIBUTE := "biblio.password";
declare variable $security:user-metadata-file := "security.metadata.xml";

(:~
: Authenticates a user and creates their tamboti home collection if it does not exist
:
: @param user The username of the user
: @param password The password of the user
:)
declare function security:login($username as xs:string, $password as xs:string?) as xs:boolean {
    (: if username is blacklisted: deny login :)
    if ($config:users-login-blacklist = $username) then
        false()
    else
        let $username := config:rewrite-username($username)
            return
                (: authenticate against eXist-db :)
                if (xmldb:login("/db", $username, $password))
                then
                    (
                        security:store-user-credential-in-session($username, $password),
                        (: check if the users tamboti home collectin exists, if not create it (this will happen at the first login) :)
                        if (security:home-collection-exists($username))
                        then
                            (
                                (: update the last login time:)
                                security:update-login-time($username),    
                                true()
                            )
                        else
                            (
                                let $users-collection-uri := security:create-home-collection($username)
                                return true()
                            )
                    )
                else
                    (: authentication failed:)
                    false()
};

(:~
: Stores a user's credentials for the tamboti app into the http session
:
: @param username The username
: @param password The password
:)
declare function security:store-user-credential-in-session($username as xs:string, $password as xs:string?) as empty() {
    let $username := config:rewrite-username($username)
        return
        (
            session:set-attribute($security:SESSION_USER_ATTRIBUTE, $username),
            session:set-attribute($security:SESSION_PASSWORD_ATTRIBUTE, $password)
        )
};

(:~
: Retrieves a user's credentials for the tamboti app from the http session
: 
: @return The sequence (username as xs:string, password as xs:string)
: If there is no entry in the session, then the guest account credentials are returned
:)
declare function security:get-user-credential-from-session() as xs:string+ {
    let $user := session:get-attribute($security:SESSION_USER_ATTRIBUTE) 
        return
            if ($user) then
            (
                $user,
                session:get-attribute($security:SESSION_PASSWORD_ATTRIBUTE)
            )
            else
                $security:GUEST_CREDENTIALS
};

(:~
: Gets a user's email address
:
: @param the username of the user
: @return the email address for the user
:)
declare function security:get-email-address-for-user($username as xs:string) as xs:string? {
    sm:get-account-metadata($username, xs:anyURI("http://axschema.org/contact/email"))
};

declare function security:get-human-name-for-user($username as xs:string) as xs:string?
{
    let $first := (system:as-user($config:dba-credentials[1],$config:dba-credentials[2], sm:get-account-metadata($username, xs:anyURI("http://axschema.org/namePerson/first"))))
        return
            if ($first) 
            then
                concat($first, " ", (system:as-user($config:dba-credentials[1],$config:dba-credentials[2], sm:get-account-metadata($username, xs:anyURI("http://axschema.org/namePerson/last")))))
            else
                $username
};

(:~
: Checks whether a user's tamboti home collection exists
:
: @param user The username
:)
declare function security:home-collection-exists($user as xs:string) as xs:boolean {
    let $username := 
        if ($config:force-lower-case-usernames) then
            fn:lower-case($user)
        else 
            $user
    return xmldb:collection-available(security:get-home-collection-uri($username))
(:            xmldb:collection-available(xs:anyURI(security:get-home-collection-uri($username))):)
};

(:~
: Get the URI of a users tamboti home collection
:)
declare function security:get-home-collection-uri($user as xs:string) as xs:string {
    let $username := 
        if ($config:force-lower-case-usernames) then 
            fn:lower-case($user)
        else 
            $user
    return
        xmldb:encode-uri($config:users-collection || "/" || $username)
};

(:~
: Creates a users tamboti home collection and sets permissions
:
: @return The uri of the users home collection or an empty sequence if it could not be created
:)
declare function security:create-home-collection($user as xs:string) as xs:string? {
    let $username := if ($config:force-lower-case-usernames) then 
           fn:lower-case($user)
        else 
            $user
    return
        if (xmldb:collection-available($config:users-collection)) then
            system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
                let $collection-uri := xmldb:create-collection($config:users-collection, xmldb:encode-uri($username))
                    return
                        if ($collection-uri) then
                            (:
                            TODO do we need the group 'read' to allow sub-collections to be enumerated?
                                NOTE - this will need to be updated to 'execute' when permissions are finalised in trunk
                            :)
                            let $null := sm:chmod($collection-uri, $config:collection-mode)
                            (: set the group as biblio users group, so that other users can enumerate our sub-collections :)
                            let $null := sm:chgrp($collection-uri, $config:biblio-users-group)
                            let $null := sm:chown($collection-uri, security:get-user-credential-from-session()[1])
                            let $null := security:create-user-metadata($collection-uri, $username) 
                            return
                                $collection-uri
                         else 
                            $collection-uri
            )
        else 
            ()        
};

(:~
: Stores some basic metadata about a user into their home collection
:)
declare function security:create-user-metadata($user-collection-uri as xs:string, $owner as xs:string) as xs:string {
    let $login-time := util:system-dateTime()
    let $metadata-doc-uri :=
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
            let $metadata-doc-uri :=
                xmldb:store($user-collection-uri, $security:user-metadata-file,
                    <security:metadata>
                        <security:last-login-time>{$login-time}</security:last-login-time>
                        <security:login-time>{$login-time}</security:login-time>
                    </security:metadata>
                )
            let $chmod := sm:chmod($metadata-doc-uri, $config:resource-mode)
            let $chown := sm:chown($metadata-doc-uri, security:get-user-credential-from-session()[1])
            let $chgrp := sm:chgrp($metadata-doc-uri, $config:biblio-users-group)
            return $metadata-doc-uri
        )

    return $metadata-doc-uri
};

(:~
: Update the last login time of a user
:)
declare function security:update-login-time($user as xs:string) as empty() {
    let $user-home-collection := security:get-home-collection-uri($user),
    $security-metadata := fn:doc(fn:concat($user-home-collection, "/", $security:user-metadata-file)) 
    return
        (
            update value $security-metadata/security:metadata/security:last-login-time with string($security-metadata/security:metadata/security:login-time),
            update value $security-metadata/security:metadata/security:login-time with util:system-dateTime()
        )
};

(:~
: Get the last login time of a user
:)
declare function security:get-last-login-time($user as xs:string) as xs:dateTime {
    let $user-home-collection := security:get-home-collection-uri($user) 
        return
            let $last-login := fn:doc(fn:concat($user-home-collection, "/", $security:user-metadata-file))/security:metadata/security:last-login-time return
            if (exists($last-login)) then
                $last-login
            else
                (
                    util:log("WARN", fn:concat("Could not find the last-login time for the user '", $user,"'. Does the user's metadata exist?")),
                    util:system-dateTime()
                )
};

(:~
: Determines if a user has read access to a collection
:
: @param user The username
: @param collection The path of the collection
:)
declare function security:can-read-collection($collection as xs:string) as xs:boolean {
    if (session:get-attribute($security:SESSION_USER_ATTRIBUTE) and  session:get-attribute($security:SESSION_PASSWORD_ATTRIBUTE))
    then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        sm:has-access($collection, "r"))
    else sm:has-access($collection, "r")
};

(:~
: Determines if a user has write access to a collection
:
: @param user The username
: @param collection The path of the collection
:)
declare function security:can-write-collection($collection as xs:string) as xs:boolean {
    if (session:get-attribute($security:SESSION_USER_ATTRIBUTE) and  session:get-attribute($security:SESSION_PASSWORD_ATTRIBUTE))
    then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        sm:has-access($collection, "w"))
    else sm:has-access($collection, "w")
};

(:~
: Determines if a user has execute to a collection
:
: @param user The username
: @param collection The path of the collection
:)
declare function security:can-execute-collection($collection as xs:string) as xs:boolean {
    if (session:get-attribute($security:SESSION_USER_ATTRIBUTE) and  session:get-attribute($security:SESSION_PASSWORD_ATTRIBUTE))
    then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        sm:has-access($collection, "x"))
    else sm:has-access($collection, "x")
};

(:~
: Determines if the user is the collection owner
:
: @param user The username
: @param collection The path of the collection
:)
declare function security:is-collection-owner($user as xs:string, $collection as xs:string) as xs:boolean
{
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $username := if ($config:force-lower-case-usernames) then (fn:lower-case($user)) else ($user) 
            return
                if (xmldb:collection-available($collection)) then
                  let $owner := security:get-owner($collection)
                    return
                        $username eq $owner
                else
                    false()
    )
};

(:~
: Gets the users for a group
:
: @param the group name
: @return The list of users in the group
:)
declare function security:get-group-members($group as xs:string) as xs:string*
{
    (: ToDo: This is a fix for broken sm:get-group-members. Undo (or better remove and replace security:get-group-members() function calls if fixed in eXist :)
    xmldb:get-users($group)
(:    sm:get-group-members($group):)
};

declare function security:set-resource-permissions($resource-path as xs:anyURI, $user-name as xs:string, $group-name as xs:string, $permissions as xs:string) as empty() {
    (
        sm:chown($resource-path, $user-name),
        sm:chgrp($resource-path, $group-name),
        sm:chmod($resource-path, $permissions)        
    )
};

declare function security:get-resource-permissions($resource-path as xs:string) as xs:string {
    data(sm:get-permissions(xs:anyURI($resource-path))/sm:permission/@mode)
};

declare function security:set-ace-writeable($resource as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as xs:boolean {
    let $permissions := sm:get-permissions($resource),
        $ace := $permissions/sm:permission/sm:acl/sm:ace[xs:int(@index) eq $id] return
            if (empty($ace)) then
                false()
            else (
                
                let $regexp-replacement := if ($is-writeable) then
                    "w"    
                else
                    "-"
                ,
                $new-mode := fn:replace($ace/@mode, "(.).(.)", fn:concat("$1", $regexp-replacement, "$2")),
                $null := system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], sm:modify-ace($resource, $id, $ace/@access_type eq 'ALLOWED', $new-mode))
                return
                    true()
                
            )
};

(:~
: toggles the ace-writable flag by name
: 
: @param resource The resource or collection
: @param target USER or GROUP
: @param name The user- or groupname
: @param is-writable writeable or not
:)

declare function security:set-ace-writeable-by-name($resource as xs:anyURI, $target as xs:string, $name as xs:string, $is-writeable as xs:boolean) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],    
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[@target=$target and @who=$name][1]
        let $id := $ace/@index
            return
                if (empty($ace)) then
                    false()
                else (
                    
                    let $regexp-replacement := if ($is-writeable) then
                        "w"    
                    else
                        "-"
                    ,
                    $new-mode := fn:replace($ace/@mode, "(.).(.)", fn:concat("$1", $regexp-replacement, "$2")),
                    $null := system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], sm:modify-ace($resource, $id, $ace/@access_type eq 'ALLOWED', $new-mode))
                    return
                        true()
                    
                )
    )
};

(:~
: toggles the ace-executable flag by name
: 
: @param resource The resource or collection
: @param target USER or GROUP
: @param name The user- or groupname
: @param is-executable executable or not
:)

declare function security:set-ace-executable-by-name($resource as xs:anyURI, $target as xs:string, $name as xs:string, $is-executable as xs:boolean) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],    
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[@target=$target and @who=$name][1]
        let $id := $ace/@index
            return
                if (empty($ace)) then
                    false()
                else (
                    
                    let $regexp-replacement := if ($is-executable) then
                        "x"    
                    else
                        "-"
                    ,
                    $new-mode := fn:replace($ace/@mode, "(.)(.)(.)", "$1" || "$2" || $regexp-replacement)
                    ,
                    $null := system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], sm:modify-ace($resource, $id, $ace/@access_type eq 'ALLOWED', $new-mode))
                    return
                        true()
                    
                )
    )
};

(:~
: set the mode for an user or group ACE
: 
: @param resource The resource or collection
: @param target USER or GROUP
: @param name The user- or groupname
: @param ace-mode the mode for ACE as string (i.e. "rwx" or "r--")
:)

declare function security:set-ace-mode-by-name($resource as xs:anyURI, $target as xs:string, $name as xs:string, $ace-mode as xs:string) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],    
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[@target=$target and @who=$name][1]
        let $id := $ace/@index
            return
                if (empty($ace)) then
                    false()
                else (
                    let $null := system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], sm:modify-ace($resource, $id, $ace/@access_type eq 'ALLOWED', $ace-mode))
                    return
                        true()
                )
    )
};


(:~
: @return a sequence if the removal succeeded, otherwise the empty sequence
:   The sequence contains USER or GROUP as the first item, and then the who as the second item
:)
declare function security:remove-ace($resource as xs:anyURI, $id as xs:int) as xs:string* {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[xs:int(@index) eq $id]
        
        return
            if (exists($ace))
            then
                (
                    let $null := sm:remove-ace($resource, $id)
                    return ($ace/@target, $ace/@who)
                )
            else (())
    )
};

(:~
: removes the user-ace by user name
: 
: @param user The username
: @param collection The path of the collection
:)
declare function security:remove-user-ace($resource as xs:anyURI, $user as xs:string) {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[@target="USER" and @who=$user][1]
        let $id := $ace/@index
        return
            if (exists($ace)) then
                (
                    let $null := sm:remove-ace($resource, $id)
                    return 
                        ($ace/@target, $ace/@who)
                )
    
            else
                (())
    )
};

(:~
: removes the user-ace by target (USER/GROUP) and name
: 
: @param resource The resource or collection
: @param target USER or GROUP
: @param name The user- or groupname
:)
declare function security:remove-ace-by-name($resource as xs:anyURI, $target as xs:string, $name as xs:string) {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],(
        let $permissions := sm:get-permissions($resource)
        let $ace := $permissions/sm:permission/sm:acl/sm:ace[@target=$target and @who=$name][1]
        let $id := $ace/@index
        return
            if (exists($ace)) then
                (
                    let $null := sm:remove-ace($resource, $id)
                    return 
                        ($ace/@target, $ace/@who)
                )
    
            else
                (())
        )
    )
};

declare function security:clear-aces-by-name($resource as xs:anyURI, $name as xs:string, $target-type as xs:string) {
    let $ace-idxs :=  sm:get-permissions($resource)//sm:ace[@target = $target-type and @who = $name]/@index/number()
    (: remove existing aces :)
    for $idx in reverse($ace-idxs)
        return
            sm:remove-ace($resource, $idx)
};


(: adds a group ace and returns its index:)
declare function security:add-group-ace($resource as xs:anyURI, $groupname as xs:string, $mode as xs:string) as xs:int? {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        (
            sm:add-group-ace($resource, $groupname, true(), $mode),
            sm:get-permissions($resource)//sm:ace[@who = $groupname]/@index/string()
        )
    )
};

declare function security:insert-group-ace($resource as xs:anyURI, $id as xs:int, $groupname as xs:string, $mode as xs:string) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], 
        (: if the ace index is one past the end of the acl, then we actually want an append :)
        if ($id eq xs:int(sm:get-permissions($resource)/sm:permission/sm:acl/@entries)) then
            fn:not(fn:empty(security:add-group-ace($resource, $groupname, $mode)))
        else (
            sm:insert-group-ace($resource, $id, $groupname, true(), $mode)
            ,
            true()
            )
    )
};

(: adds a user ace and returns its index:)
declare function security:add-user-ace($resource as xs:anyURI, $username as xs:string, $mode as xs:string) as xs:int? {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        (
            sm:add-user-ace($resource, $username, true(), $mode),
            sm:get-permissions($resource)//sm:ace[@who = $username]/@index/string()
        )
    )
};

declare function security:insert-user-ace($resource as xs:anyURI, $id as xs:int, $username as xs:string, $mode as xs:string) as xs:boolean {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        (: if the ace index is one past the end of the acl, then we actually want an append:)
        if ($id eq xs:int(sm:get-permissions($resource)/sm:permission/sm:acl/@entries)) then
            fn:not(fn:empty(security:add-user-ace($resource, $username, $mode)))
        else (
            sm:insert-user-ace($resource, $id, $username, true(), $mode)
            ,
            true()
            )
    )
};

(: ~
: Resources always inherit the permissions of the parent collection
:)
declare function security:apply-parent-collection-permissions($resource as xs:anyURI) as empty() {
    let $parent-permissions := sm:get-permissions(xs:anyURI(fn:replace($resource, "(.*)/.*", "$1")))
    let $this-permissions := sm:get-permissions($resource)
    let $this-last-acl-index := xs:int($this-permissions/sm:permission/sm:acl/@entries) -1
    
    return
        (
            for $ace in $parent-permissions/sm:permission/sm:acl/sm:ace
            return
                if ($ace/@target eq "USER")
                then sm:add-user-ace($resource, $ace/@who, $ace/@access_type eq "ALLOWED", $ace/@mode)
                else
                    if ($ace/@target eq "GROUP")
                    then sm:add-group-ace($resource, $ace/@who, $ace/@access_type eq "ALLOWED", $ace/@mode)
                    else ()
            ,
            if ($this-permissions/sm:permission/@owner ne $parent-permissions/sm:permission/@owner)
            then
                let $owner-mode := fn:replace($parent-permissions/sm:permission/@mode, "(...).*", "$1")
                return sm:add-user-ace($resource, $parent-permissions/sm:permission/@owner, true(), $owner-mode)
            else ()
            ,
            if ($this-permissions/sm:permission/@group ne $parent-permissions/sm:permission/@group)
            then
                let $group-mode := fn:replace($parent-permissions/sm:permission/@mode, "...(...)...", "$1") 
                return sm:add-group-ace($resource, $parent-permissions/sm:permission/@group, true(), $group-mode)
            else ()
            ,
            (: clear any prev entries :)
            for $i in 0 to $this-last-acl-index
            return sm:remove-ace($resource, $i)
        )
};

declare function security:is-biblio-user($username as xs:string) as xs:boolean {
    sm:user-exists($username) and xmldb:get-user-groups($username) = $config:biblio-users-group
};

declare function security:get-owner($path as xs:string) as xs:string {
    let $response := data(sm:get-permissions(xs:anyURI($path))/sm:permission/@owner)
    return $response
};

declare function security:get-group($path as xs:string) as xs:string {
    data(sm:get-permissions(xs:anyURI($path))/sm:permission/@group)
};

declare function security:copy-collection-rights-to-child-resources($collection as xs:anyURI) {
    system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
        let $collection-owner := xmldb:get-owner($collection)
        let $collection-group := xmldb:get-group($collection)
        
        for $resource-name in xmldb:get-child-resources($collection)
            return
                security:copy-owner-and-group($collection, xs:anyURI($collection || "/" || $resource-name))
    )
};

declare function security:copy-collection-permissions-to-child-resources($collection as xs:anyURI) {
    security:copy-collection-permissions-to-child-resources($collection),
    security:copy-collection-acl-to-child-resources($collection)
};


declare function security:copy-tamboti-collection-user-acl($collection as xs:anyURI) {
    (: update ACL for resources in parent collection  :)
    security:copy-collection-acl-to-child-resources(xs:anyURI($collection)),
    
    if (xmldb:collection-available($collection || "/" || $config:images-subcollection)) then
        (
            (: update ACL for VRA_images collection  :)
            sm:clear-acl(xs:anyURI($collection || "/" || $config:images-subcollection)),
            security:duplicate-acl($collection, $collection || "/" || $config:images-subcollection),
            (: update ACL for resources in VRA_images   :)
            security:copy-collection-acl-to-child-resources(xs:anyURI($collection || "/" || $config:images-subcollection))
        )
    else
        ()
};

declare function security:recursively-inherit-collection-acl($collection as xs:anyURI) {
    system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
        (
            (: copy collection ACL and rights to each resource:)
            let $inherit-permissions := security:copy-collection-acl-to-child-resources($collection)
        
            for $subcollection in xmldb:get-child-collections($collection)
                let $subcollection-path := xs:anyURI($collection || "/" || $subcollection)
                    return
                        (
                            (: copy collection ACE to subcollection :)
                            sm:clear-acl($subcollection-path),
                            security:duplicate-acl($collection, $subcollection-path),
                            (: recursive call of function:)
                            security:recursively-inherit-collection-acl($subcollection-path)
                        )
        )
    )
};

declare function security:recursively-set-owner-and-group($collection as xs:anyURI, $owner, $group) {
    system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
        (
            try {
                let $res-result :=
                    for $resource in xmldb:get-child-resources($collection)
                        return
                            (
                                sm:chown(xs:anyURI($collection || "/" || $resource), $owner),
                                sm:chgrp(xs:anyURI($collection || "/" || $resource), $group)
                            )
                let $col-result :=
                    (
                        sm:chown($collection, $owner),
                        sm:chgrp($collection, $group),
    
                        for $subcol in xmldb:get-child-collections($collection)
                            return 
                                (
                                    security:recursively-set-owner-and-group(xs:anyURI($collection || "/" || $subcol), $owner, $group)
                                )
                    )
                return true()
            } catch * {
                util:log("INFO", "Catched Error: " ||  $err:code || ": " || $err:description),
                false()
            }
            
        )
    )
        
};

declare function security:copy-owner-and-group($source as xs:anyURI, $target as xs:anyURI) {
    let $source-owner := xmldb:get-owner($source)
    let $source-group := xmldb:get-group($source)
    return
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
            (
                sm:chown($target, $source-owner),
                sm:chgrp($target, $source-group)
            )
        )
};

(:NB: below, commented out group-related functions, not used yet:)

(:~
: Determines if a group has read access to a collection
:
: @param group The group name
: @param collection The path of the collection
:)

(:
declare function security:group-can-read-collection($group as xs:string, $collection as xs:string) as xs:boolean
{
    if (xmldb:collection-available($collection)) then
    
        let $permissions := sm:get-permissions($collection) return
        
            (: check the group owner :)
            if ($permissions/@group eq $group and (fn:matches($permissions/@mode, "...r.....", "") or fn:matches($permissions/@mode, "......r.."))) then
                true()
            else
                (: check the acl :)
                if ($permissions/sm:permission/sm:acl/sm:ace[@target eq "GROUP"][@who eq $group][@access_type eq "ALLOWED"][fn:contains(@mode, "r")]) then
                    true()
                else
                    false()
    else
        false()
};

(:~
: Determines if a group has write access to a collection
:
: @param group The group name
: @param collection The path of the collection
:)
declare function security:group-can-write-collection($group as xs:string, $collection as xs:string) as xs:boolean
{
    if (xmldb:collection-available($collection)) then
    
        let $permissions := sm:get-permissions($collection) return
        
            (: check the group owner :)
            if ($permissions/@group eq $group and (fn:matches($permissions/@mode, "....w....", "") or fn:matches($permissions/@mode, ".......w."))) then
                true()
            else
                (: check the acl :)
                if ($permissions/sm:permission/sm:acl/sm:ace[@target eq "GROUP"][@who eq $group][@access_type eq "ALLOWED"][fn:contains(@mode, "w")]) then
                    true()
                else
                    false()
    else
        false()
};

(:~
: Determines if everyone has read access to a collection
:
: @param collection The path of the collection
:)
declare function security:other-can-read-collection($collection as xs:string) as xs:boolean
{
    if (xmldb:collection-available($collection)) then
        let $permissions := sm:get-permissions($collection) return
            fn:matches($permissions/@mode, "......r..")
    else
        false()
};

(:~
: Determines if everyone has write access to a collection
:
: @param collection The path of the collection
:)
declare function security:other-can-write-collection($collection as xs:string) as xs:boolean
{
    if (xmldb:collection-available($collection)) then
        let $permissions := sm:get-permissions($collection) return
            fn:matches($permissions/@mode, ".......w.")
    else
        false()
};
:)

(:~
: Gets the managers for a group
:
: @param the group name
: @return The list of managers in the group
:)
(:
declare function security:get-group-managers($group as xs:string) as xs:string*
{
    sm:get-group-managers($group)
};
:)

(:~
: Gets a list of other tamboti users
:)
(:
declare function security:get-other-biblio-users() as xs:string*
{
    security:get-group-members($config:biblio-users-group)[. ne security:get-user-credential-from-session()[1]]
};
:)

(:
declare function security:set-other-can-read-collection($collection, $read as xs:boolean) as xs:boolean
{
    let $permissions := security:get-resource-permissions($collection) return
        let $new-permissions := if ($read) then (
            fn:replace($permissions, "(......)(.)(..)", "$1r$3")
        ) else (
           fn:replace($permissions, "(......)(.)(..)", "$1-$3")
        )
        return
            security:set-resource-permissions(xs:anyURI($collection), security:get-owner($collection), security:get-group($collection), $new-permissions),
            
            true()
};

declare function security:set-other-can-write-collection($collection, $write as xs:boolean) as xs:boolean
{
    let $permissions := security:get-resource-permissions($collection) return
        let $new-permissions := if ($write) then (
            fn:replace($permissions, "(.......)(.)(.)", "$1w$3")
        ) else (
           fn:replace($permissions, "(.......)(.)(.)", "$1-$3")
        )
        return        
            security:set-resource-permissions(xs:anyURI($collection), security:get-owner($collection), security:get-group($collection), $new-permissions),
            
            true()
};

declare function security:set-group-can-read-collection($collection, $read as xs:boolean) as xs:boolean
{
    security:set-group-can-read-collection($collection, security:get-group($collection), $read)
};

declare function security:set-group-can-write-collection($collection, $write as xs:boolean) as xs:boolean
{
    security:set-group-can-write-collection($collection, security:get-group($collection), $write)
};

declare function security:set-group-can-read-collection($collection, $group as xs:string, $read as xs:boolean) as xs:boolean
{
    let $permissions := security:get-resource-permissions($collection) return
        let $new-permissions := if ($read) then (
            fn:replace($permissions, "(...)(.)(.....)", "$1r$3")
        ) else (
           fn:replace($permissions, "(...)(.)(.....)", "$1-$3")
        )
        return
            security:set-resource-permissions(xs:anyURI($collection), security:get-owner($collection), $group, $new-permissions),
            true()
};

declare function security:set-group-can-write-collection($collection, $group as xs:string, $write as xs:boolean) as xs:boolean
{
    let $permissions := security:get-resource-permissions($collection) return
        let $new-permissions := if ($write) then (
            fn:replace($permissions, "(....)(.)(....)", "$1w$3")
        ) else (
           fn:replace($permissions, "(....)(.)(....)", "$1-$3")
        )
        return
            security:set-resource-permissions(xs:anyURI($collection), security:get-owner($collection), $group, $new-permissions),
            true()
};
:)

(:~
: Creates a security group
:
: Note - The currently logged in user will be the group owner
:)
(:
declare function security:create-group($group-name as xs:string, $group-members as xs:string*) as xs:boolean
{       
    (: create the group, currently logged in user will be the groups manager :)
    if (sm:create-group($group-name, security:get-user-credential-from-session()[1], "")) then
    (
        (: add members to group :)
        let $add-results :=
            for $group-member in $group-members            
            let $group-member-username := if ($config:force-lower-case-usernames) then (fn:lower-case($group-member)) else ($group-member) return
                sm:add-group-member($group-name, $group-member-username)
        return
            fn:not(fn:contains($add-results, false()))
    )
    else
    (
        false()
    )
};
:)

(:
declare function security:add-user-to-group($username as xs:string, $group-name as xs:string) as xs:boolean
{
    sm:add-group-member($group-name, $username)
};

declare function security:remove-user-from-group($username as xs:string, $group-name as xs:string) as xs:boolean
{
    sm:remove-group-member($group-name, $username)
};
:)

(:
declare function security:set-group-can-read-resource($group-name as xs:string, $resource as xs:string, $read as xs:boolean) as xs:boolean
{
    let $collection-uri := fn:replace($resource, "(.*)/.*", "$1"),
    $resource-uri := fn:replace($resource, ".*/", ""),
    $permissions := security:get-resource-permissions(concat($collection-uri, "/", $resource-uri)) return
        let $new-permissions := if ($read) then (
            fn:replace($permissions, "(...)(.)(.....)", "$1r$3")
        ) else (
           fn:replace($permissions, "(...)(.)(.....)", "$1-$3")
        )
        return
            security:set-resource-permissions(xs:anyURI(concat($collection-uri, "/", $resource-uri)), security:get-owner(concat($collection-uri, "/", $resource-uri)), $group-name, $new-permissions),
            
            true()
};
:)

(:
declare function security:get-groups($user as xs:string) as xs:string*
{
    (: TODO if you remove this line, then for some reason you get an error -
    XPTY0004: The actual cardinality for parameter 1 does not match the cardinality declared in the function's signature: xmldb:get-user-groups($user-id as xs:string) xs:string+. Expected cardinality: exactly one, got 2.
    :)
    let $null := util:log("debug", fn:concat("USER=========", $user)) return
    
    let $username := if ($config:force-lower-case-usernames) then (fn:lower-case($user)) else ($user) return
        xmldb:get-user-groups($username)
};
:)

(:
declare function security:find-collections-with-group($collection-path as xs:string, $group as xs:string) as xs:string*
{
    for $child-collection in xmldb:get-child-collections($collection-path)
    let $child-collection-path := fn:concat($collection-path, "/", $child-collection) return
        (
            if (security:get-group($child-collection-path) eq $group) then (
                $child-collection-path
            ) else (),
            security:find-collections-with-group($child-collection-path, $group)
        )
};
:)

declare function security:copy-collection-acl-to-child-resources($collection as xs:anyURI) {
    for $resource-name in xmldb:get-child-resources($collection)
        return
            (
                (: first remove ACL on resource :)
                sm:clear-acl(xs:anyURI($collection || "/" || $resource-name)),
                (: add each ACE from collection to resource:)
                security:duplicate-acl($collection, $collection || "/" || $resource-name)
            )
};

(:~
: get searchable children. Recursively goes into collection structure to get collections that are searchable by user but maybe not directly accessible because located in a non-searchable collection
:
: @param $collection-uri the base collection to search
: @param $spare-user-home should users home collection (and its children) be left out
: @return sequence with full paths to searchable collections
:)
declare function security:get-searchable-child-collections($collection-uri as xs:anyURI, $spare-user-home as xs:boolean) {
    (: elevate rights for going into the collection structure :)
    let $subcollections := 
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], (
                xmldb:get-child-collections($collection-uri)
            )
        )
    for $subcol in $subcollections[not($config:images-subcollection = .)]
    let $fullpath := xs:anyURI($collection-uri || "/" || $subcol)
    order by $subcol
    
    return
        if ($spare-user-home and $subcol = security:get-user-credential-from-session()[1]) then
            ()
        else
            (
                system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], 
                    if (xmldb:collection-available($fullpath)) then
                        let $readable := security:can-read-collection($fullpath)
                        let $executeable := security:can-execute-collection($fullpath) 
                        let $readable-children := security:get-searchable-child-collections($fullpath, $spare-user-home)
                        return
                            (
                                if (($readable and $executeable) or not(empty($readable-children))) then
                                    xs:anyURI($fullpath)
                                else
                                    ()
                            )
                    else
                        ()
                )
            ,
                security:get-searchable-child-collections($fullpath, $spare-user-home)
            )
};

declare function security:get-acl($collection-uri as xs:anyURI) {
    let $aces := 
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
            sm:get-permissions($collection-uri)//sm:ace
        )
    return $aces
};

(:~
: Use elevated rights to search resource by id.
:
: @param $id the resource id
: @return the resource as node
:)
declare function security:get-resource($id as xs:string) as node()? {
    (: Do search as dba :)
    let $resource :=
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
            collection($config:mods-root)//(mods:mods[@ID eq $id][1] | vra:vra/vra:work[@id eq $id][1] | vra:vra/vra:image[@id eq $id][1])
        )
    return
        if ($resource) then
            let $resource-path := util:collection-name($resource)
            let $resource-name := util:document-name($resource)
            
            (: only return data if user has access to resource   :)
            return
                system:as-user(security:get-user-credential-from-session()[1],security:get-user-credential-from-session()[2],
                    if(sm:has-access(xs:anyURI($resource-path || "/" || $resource-name), "r--")) then
                        $resource
                    else
                        ()
                )
    else
        ()
};

declare function security:duplicate-acl($source as xs:anyURI, $target as xs:anyURI) {
    (: get ACL from source   :)
    let $ACL := sm:get-permissions($source)//sm:ace
    return
        (: first remove ACL on resource :)
        sm:clear-acl($target),
        (: add each ACE from collection to resource:)
        for $ACE in sm:get-permissions($source)//sm:ace
            let $ace-target := $ACE/@target
            let $who := $ACE/@who
            let $access_type := if ($ACE/@access_type = 'ALLOWED') then true() else false()
            let $mode := $ACE/@mode
            (: no  :)
            return
                if ($ace-target = 'USER') then 
                    sm:add-user-ace($target, $who, $access_type, $mode)
                else 
                    sm:add-group-ace($target, $who, $access_type, $mode)

};

(:~
: Copy collection ACL to resource and change mode to corresponding resource-mode
:
: @param $source-collection the target collection
: @param $resource the resource-name to move
: @param $target-collection the target collection
:)

declare function security:copy-collection-ace-to-resource-apply-modechange($collection as xs:anyURI, $resource as xs:anyURI) {
    let $target-collection-aces := sm:get-permissions($collection)
    (: clear respource ACL :)
    let $clear := sm:clear-acl($resource)
    
    for $ace in $target-collection-aces//sm:ace
        let $resource-mode := 
            for $key in map:keys($config:sharing-permissions)
            return
                if($config:sharing-permissions($key)("collection") = $ace/@mode/string()) then
                    $config:sharing-permissions($key)("resource")
                else
                    ()
        let $target := $ace/@target/string()
        let $who := $ace/@who/string()
        let $access-type := $ace/@access_type/string() = "ALLOWED"
        return
            if ($target = "USER") then
                sm:add-user-ace($resource, $who, $access-type, $resource-mode)
            else
                sm:add-group-ace($resource, $who, $access-type, $resource-mode)
};


(:~
: Move resource to a collection and apply permissions specified for Tamboti
:
: @param $source-collection the target collection
: @param $resource the resource-name to move
: @param $target-collection the target collection
:)
declare function security:move-resource-to-tamboti-collection($source-collection as xs:anyURI, $resource as xs:anyURI, $target-collection as xs:anyURI) {
(:    util:log("DEBUG", xmldb:get-owner($target-collection) || "=" || security:get-user-credential-from-session()[1]),:)
    (: first move the resource :)
    xmldb:move($source-collection, $target-collection, $resource),
    (: if user is owner of target collection first change owner since he will get no ACE and will shut out himself  :)
    if(xmldb:get-owner($target-collection) = security:get-user-credential-from-session()[1]) then
        (
            security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource))
            ,
            security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection || "/" || $resource))
        )
    else
        (
            security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection || "/" || $resource))
            ,
            security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource))
        )
};

declare function security:copy-collection-acl($source-collection as xs:anyURI, $target-collection as xs:anyURI) {
    try {
        (
            sm:clear-acl($target-collection)
            ,
            security:duplicate-acl($source-collection, $target-collection)
            ,
            for $resource in xmldb:get-child-resources($target-collection)
            return
                security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection ||  "/" || $resource))
            ,
            let $call-for-VRA-images :=
                if(xmldb:collection-available(xs:anyURI($target-collection || "/VRA_images"))) then
                    (
                    sm:clear-acl(xs:anyURI($target-collection || "/VRA_images"))
                    ,
                    security:duplicate-acl($source-collection, xs:anyURI($target-collection || "/VRA_images"))
                    ,
                    for $resource in xmldb:get-child-resources(xs:anyURI($target-collection || "/VRA_images"))
                    return
                        security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection || "/VRA_images/" || $resource))
                    )

(:                    security:copy-collection-acl($target-collection, xs:anyURI($target-collection || "/VRA_images")):)
                else 
                    ()
            return true()
        )    
    } catch * {
          "Catched Error: " ||  $err:code || ": " || $err:description
  }

};