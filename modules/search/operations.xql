xquery version "3.1";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../../frameworks/vra-hra/vra-hra.xqm";
import module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "../../frameworks/mods-hra/mods-hra.xqm";
import module namespace svg-hra-framework = "http://hra.uni-heidelberg.de/ns/svg-hra-framework" at "../../frameworks/svg-hra/svg-hra.xqm";
import module namespace tei-hra-framework = "http://hra.uni-heidelberg.de/ns/tei-hra-framework" at "../../frameworks/tei-hra/tei-hra.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";

declare namespace op="http://exist-db.org/xquery/biblio/operations";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace json="http://www.json.org";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $op:HTTP-FORBIDDEN := 403;
 
(:TODO: if collection names use higher Unicode characters, 
the buttons do not show up (except Delete Folder).:)

(:~
: Creates a collection inside a parent collection
:
: The new collection inherits the owner, group and permissions of the parent
:
: @param $parent-collection-uri the parent collection uri
: @param $new-collection-name the name for the new collection
:)
(:NB: creation does not take place if the new name is already taken.:)
(:TODO: notify user if the new name is already taken.:)
declare function op:create-collection($parent as xs:string, $name as xs:string) as element(status) {
(:    let $log := util:log("DEBUG", "call: xmldb:create-collection('" || $parent || "', '" || $name || "')"):)
    let $create-collection :=
        let $parent-collection-owner := xmldb:get-owner($parent)
        let $parent-collection-group := xmldb:get-group($parent)
        let $collection := xmldb:create-collection($parent, $name)
        
        (: inherit ACE from parent collection to new collection:)
        let $inherit-ACE := security:duplicate-acl($parent, xs:anyURI($parent || "/" || $name))

        (: just the owner has full access - to start with :)
        let $null := sm:chmod(xs:anyURI($collection), $config:collection-mode)

        (: to be sure that the collection owner's group is the intended one :)
        let $change-group := sm:chgrp(xs:anyURI($collection), $parent-collection-group)
        let $change-owner := sm:chown(xs:anyURI($parent || "/" || $name), $parent-collection-owner)
        return ()

    return
        <status id="created">{xmldb:decode-uri(xs:anyURI($parent || "/" || $name))}</status>

};

(:TODO: Perform search for contents of collection after it has been moved.:)
declare function op:move-collection($collection as xs:anyURI, $target-collection as xs:anyURI, $inherit-acl-from-parent as xs:boolean) as element(status) {
    let $source-collection-owner := xmldb:get-owner($collection)
    let $target-collection-owner := xmldb:get-owner($target-collection)
    let $target-collection-group := xmldb:get-group($target-collection)
    let $collection-name := functx:substring-after-last($collection, "/")
    let $moved-collection-path := xs:anyURI($target-collection || "/" || $collection-name)

    let $result :=
        (
            (: Move collection to target collection   :)
            xmldb:move($collection, $target-collection)
            ,
            (: recursively set owner of target collection as owner :)
            security:recursively-set-owner-and-group($moved-collection-path, $target-collection-owner, $target-collection-group)
            ,
            (: clear ACL and add ACE for former collecton owner, if not owner of target-collection:)
            if (not($source-collection-owner = $target-collection-owner))
            then
                (
                    sm:clear-acl($moved-collection-path)
                    ,
                    sm:add-user-ace($moved-collection-path, $source-collection-owner, true(), "rwx")
                    ,
                    (: inherit ACL recursively to all subresources and -collections :)
                    security:recursively-inherit-collection-acl($moved-collection-path)
                )
            else
                ()
        )

    return
        <status id="moved" from="{xmldb:decode-uri($collection)}">{xmldb:decode-uri($target-collection)}</status>
};

(:NB: name change does not take place if the new name is already taken.:)
(:TODO: notify user if the new name is already taken.:)
declare function op:rename-collection($path as xs:anyURI, $name as xs:string) as element(status) {
    let $null := xmldb:rename($path, $name)
    
    return
        (:<status id="renamed" from="{uu:unescape-collection-path($path)}">{$name}</status>:)
        <status id="renamed" from="{xmldb:decode-uri($path)}">{xmldb:decode-uri($name)}</status>
};

(:TODO: After removal, perform search in Home collection:)
(:TODO: Implement for VRA records:)
declare function op:remove-collection($collection as xs:anyURI) as element(status) {

    (:Only allow deletion of a collection if none of the MODS records in it are referred to in xlinks outside the collection itself.:)
    (:Get the ids of the records in the collection that the user wants to delete.:)
    let $collection-ids := collection($collection)//@ID
    (:Get the ids of the records that are linked to the records in the collection that the user wants to delete.:)
    let $xlinked-rec-ids :=
        string-join(
        for $collection-id in $collection-ids
            let $xlink := concat('#', $collection-id)
            let $xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href eq $xlink]/ancestor::mods:mods/@ID
            return
                (:It is OK to delete a record using an ID as an xlink if the record is inside the folder to be deleted.:)
                if (not($xlink-recs = $collection-ids))
                then $xlink-recs
                else ''
                (:This should return '' for each iteration for deletion to proceed.:)
                )
    let $null := 
        (:If $xlinked-rec-ids is not empty, do not delete.:)
        if ($xlinked-rec-ids)
        then ()
        else xmldb:remove($collection)
    return
        if ($xlinked-rec-ids)
        then <status id="removed">{collection}</status>
        else <status id="not-removed">{$collection}</status>
};

(:~
:
: @resource-id is the UUID of the MODS or VRA record
TODO: Perform search for contents of the collection that the removed resource belonged to.
:)
declare function op:remove-resource($resource-id as xs:string) as element(status)* {
    let $resource := collection($config:mods-root-minus-temp)//(mods:mods[@ID eq $resource-id][1] | vra:vra[vra:work[@id eq $resource-id]][1] | svg:svg[@xml:id = $resource-id][1] | tei:TEI[@xml:id = $resource-id][1])
    let $document-uri := xs:anyURI(document-uri(root($resource)))

    let $record-namespace := namespace-uri($resource)
    let $result :=
        switch($record-namespace)
            case "http://www.w3.org/2000/svg" return 
                svg-hra-framework:remove-resource($document-uri)
            case "http://www.loc.gov/mods/v3" return
                mods-hra-framework:remove-resource($document-uri)
            case "http://www.vraweb.org/vracore4.htm" return
                vra-hra-framework:remove-resource($document-uri)
(:            case "http://www.tei-c.org/ns/1.0":)
(:                return tei-hra-framework:remove-resource($document-uri):)
            default return 
                false()
    return
        if($result) then
            <status id="removed">{$resource-id}</status>
        else
            (
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status id="remove">Removing failed</status>
            )
};

(:~
: @ resource-id has the format db-document-path#node-id e.g. /db/mods/eXist/exist-articles.xml#1.36
TODO: Perform search for record after it has been moved. 
:)
declare function op:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
    let $resource := collection($source-collection)//(mods:mods[@ID eq $resource-id][1] | vra:vra[vra:work[@id eq $resource-id]][1] | svg:svg[@xml:id = $resource-id][1] | tei:TEI[@xml:id = $resource-id][1])
    let $document-uri := xs:anyURI(document-uri(root($resource)))

    let $log := util:log("DEBUG", "source:" || $source-collection || " target:" || $target-collection || " resID: " || $resource-id || " found: " || $document-uri)

    let $record-namespace := namespace-uri($resource)
    let $move-record :=
        switch($record-namespace)
            case "http://www.loc.gov/mods/v3"
                return mods-hra-framework:move-resource($source-collection, $target-collection, $resource-id)
            case "http://www.vraweb.org/vracore4.htm"
                return vra-hra-framework:move-resource($source-collection, $target-collection, $resource-id)
            case "http://www.w3.org/2000/svg"
                return svg-hra-framework:move-resource($document-uri, $target-collection)
            case "http://www.tei-c.org/ns/1.0"
                return tei-hra-framework:move-resource($document-uri, $target-collection)
            default return ()
    
(:    let $log := util:log("INFO", $move-record):)
    return $move-record
};

declare function op:set-ace-writeable($collection as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as element(status) {
  
    if(exists(sharing:set-collection-ace-writeable($collection, $id, $is-writeable)))then  
        <status id="ace">updated</status>
    else(
        response:set-status-code($op:HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

(:~
 : toggles the ACE writable bit by target (USER/GROUP) and name
 : @param $collection the collection to modify ACE
 : @param $target USER or GROUP
 : @param $name User- or groupname
 : @param $is-writeable writeable or not
 :)
declare function op:set-ace-writeable-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string, $is-writeable as xs:boolean) as element(status) {
    let $collection-result := sharing:set-collection-ace-writeable-by-name($collection, $target, $name, $is-writeable)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:set-collection-ace-writeable-by-name(xs:anyURI($collection || "/VRA_images"), $target, $name, $is-writeable)
        else
            ()
    return
        if(exists($collection-result)) then
            <status id="ace">updated</status>
        else
            (
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status id="ace">Permission Denied</status>
            )
};

(:~
 : toggles the ACE executable bit by target (USER/GROUP) and name
 : @param $collection the collection to modify ACE
 : @param $target USER or GROUP
 : @param $name User- or groupname
 : @param $is-executable executable or not
 :)
declare function op:set-ace-executable-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string, $is-executable as xs:boolean) as element(status) {
    let $collection-result := sharing:set-ace-executable-by-name($collection, $target, $name, $is-executable)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:set-ace-executable-by-name(xs:anyURI($collection || "/VRA_images"), $target, $name, $is-executable)
        else
            ()
    return
        if(exists($collection-result)) then
            <status id="ace">updated</status>
        else
            (
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status id="ace">Permission Denied</status>
            )
};


declare function op:remove-ace($collection as xs:anyURI, $id as xs:int) as element(status) {
    let $parent-collection-result := sharing:remove-collection-ace($collection, $id)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:remove-collection-ace(xs:anyURI($collection || "/VRA_images"), $id)
        else
            true()
    return
        if(exists($parent-collection-result) and exists($vra-images-result)) then
            <status id="ace">removed</status>
        else(
            response:set-status-code($op:HTTP-FORBIDDEN),
            <status id="ace">Permission Denied</status>
            )
      
};

(:~
 : removes ACE by target (USER/GROUP) and name
 : @param $collection the collection to remove ACE from
 : @param $target USER or GROUP
 : @param $name User- or groupname
 :)
declare function op:remove-ace-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string) as element(status) {
    let $parent-collection-result := sharing:remove-collection-ace-by-name($collection, $target, $name)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:remove-collection-ace-by-name(xs:anyURI($collection || "/VRA_images"), $target, $name)
        else
            true()
    return
        if(exists($parent-collection-result) and exists($vra-images-result)) then
            <status id="ace">removed</status>
        else
            (
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status id="ace">Permission denied</status>
            )

};

declare function op:add-user-ace($collection as xs:anyURI, $username as xs:string, $mode as xs:string, $inherit as xs:boolean) as element(status) {    
    let $ace-id := sharing:add-collection-user-ace($collection, $username, $mode)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-user-ace(xs:anyURI($collection || "/VRA_images"), $username, $mode)
        else
            ()    

    return
        if ($ace-id != -1) then
            <status ace-id="{$ace-id}">added</status>
        else
            ( 
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status ace-id="{$ace-id}">Permission Denied</status>
            )
};

declare function op:add-group-ace($collection as xs:anyURI, $groupname as xs:string, $mode as xs:string, $inherit as xs:boolean) as element(status) {
    let $ace-id := sharing:add-collection-group-ace(xs:anyURI($collection), $groupname, $mode)    
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-group-ace(xs:anyURI($collection || "/VRA_images"), $groupname, $mode)
        else
            ()  
    
    return
        if ($ace-id != -1)
        then <status ace-id="{$ace-id}">added</status>
        else
            ( 
                response:set-status-code($op:HTTP-FORBIDDEN),
                <status ace-id="{$ace-id}">Permission Denied</status>
            ) 
};

declare function op:is-valid-user-for-share($username as xs:string) as element(status) {
    if (sharing:is-valid-user-for-share($username))
    then <status id="user">valid</status>
    else
        (
            response:set-status-code($op:HTTP-FORBIDDEN),
            <status id="user">invalid</status>
        )
};

declare function op:get-child-collection-paths($start-collection as xs:anyURI) {
    for $child-collection in xmldb:get-child-collections("/db" || $start-collection)
        return
            if(xmldb:collection-available($start-collection || '/' || $child-collection)) then
                (concat($start-collection, '/', $child-collection), 
                op:get-child-collection-paths(concat($start-collection, '/', $child-collection) cast as xs:anyURI))
            else
                ()
};

(:A collection cannot be moved into itself or into its parent, nor can it be moved into a subcollection, 
so it is necessary to check against the path of the collection that is to be moved.
A file cannot, by stipulation, be moved into the top level of the home collection, nor can it be moved to its own parent collection.:)
(:TODO: capture the collection that the resource to be moved belongs to.:)

declare function op:get-move-folder-list($chosen-collection as xs:anyURI) as element(select) {
    <select>
        {
            (:the user can move records to their home folder and to folders that are shared with the user:)
            let $available-collection-paths := (security:get-home-collection-uri(security:get-user-credential-from-session()[1]), $config:mods-commons)
            let $move-folder-list :=
                for $available-collection-path in $available-collection-paths 
                    return 
                        distinct-values(
                    (
                        $available-collection-path,
                        security:get-home-collection-uri(security:get-user-credential-from-session()[1]),
                        op:get-child-collection-paths($available-collection-path),
                        sharing:recursively-get-shared-subcollections(xs:anyURI($config:mods-root), true())
                    )
                    )
            for $path in distinct-values($move-folder-list)
                (:let $log := util:log("DEBUG", ("##$path): ", $path)):)
                (:let $log := util:log("DEBUG", ("##$chosen-collection): ", $chosen-collection)):)
                (:let $log := util:log("DEBUG", ("##$starts-with): ", starts-with($path, $chosen-collection))):)
                (:let $log := util:log("DEBUG", ("##$home): ", security:get-home-collection-uri(security:get-user-credential-from-session()[1]))):)
                (:let $log := util:log("DEBUG", ("##$shared): ", sharing:get-shared-collection-roots(true()))):)
                let $display-path := substring-after($path, '/db/')
                let $user := xmldb:get-current-user()
                let $display-path := replace($path, concat('users/', $user), 'Home')
                let $valid-col-mode := $config:sharing-permissions("full")("collection")
                order by $display-path
                return
                (:leave out the folder that the user has marked, since you cannot move something to itself:)
                (:leave out descendant folders, since you cannot move a folders into a descendant:)
                (:if (contains($path, $chosen-collection) or contains($chosen-collection, $path)):)
                    if (starts-with($path, $chosen-collection)
                        or not(security:user-has-access(security:get-user-credential-from-session()[1], $path, $valid-col-mode))
                        or $path eq $chosen-collection
                        or functx:substring-after-last($path, "/") = "VRA_images") then
                        () 
                    else
                        <option value="{xmldb:decode-uri($path)}">{xmldb:decode-uri($display-path)}</option>
                    
        }
    </select>
};

declare function op:get-move-list($chosen-collection as xs:anyURI, $type as xs:string) as element(select) {
    <select>
        {
            (:the user can move records to their home folder and to folders that are shared with the user:)
            let $available-collection-paths := (security:get-home-collection-uri(security:get-user-credential-from-session()[1]))
            let $move-folder-list :=
                for $available-collection-path in $available-collection-paths 
                    return 
                    (
                        security:get-home-collection-uri(security:get-user-credential-from-session()[1]),
                        op:get-child-collection-paths($available-collection-path),
                        sharing:recursively-get-shared-subcollections(xs:anyURI($config:mods-root), true())
                    )
            for $path in distinct-values($move-folder-list)
                let $display-path := substring-after($path, '/db/')
                let $user := xmldb:get-current-user()
                let $display-path := replace($path, concat('users/', $user), 'Home')
                order by $display-path
                return
                (:leave out the folder that the user has marked, since you cannot move something to itself:)
                (:leave out descendant folders, since you cannot move a folders into a descendant:)
                    if ($path eq $chosen-collection or functx:substring-after-last($path, "/") = "VRA_images") then
                        () 
                    else
                        <option value="{xmldb:decode-uri($path)}">{xmldb:decode-uri($display-path)}</option>
        }
    </select>
};

declare function op:get-move-resource-list($collection as xs:anyURI) as element(select) {
    op:get-move-folder-list($collection)
};

declare function op:is-valid-group-for-share($groupname as xs:string) as element(status) {
    if(sharing:is-valid-group-for-share($groupname))then
        <status id="group">valid</status>
    else(
        response:set-status-code($op:HTTP-FORBIDDEN),
        <status id="group">invalid</status>
    )
};

declare function op:unknown-action($action as xs:string) {
        response:set-status-code($op:HTTP-FORBIDDEN),
        <p>Unknown action: {$action}.</p>
};

declare function op:share($collection as xs:anyURI, $name as xs:string, $target-type as xs:string, $share-type as xs:string) {
    (
        if (xmldb:collection-available($collection)) then
            try {
                let $permissions-map := $config:sharing-permissions($share-type)
    
                (: update ACEs for resources:)
                let $resources-result := 
                    for $res in xmldb:get-child-resources($collection)
                        (: remove existing user/group aces :)
                        let $remove := security:clear-aces-by-name(xs:anyURI($collection || "/" || $res), $name, $target-type)
                        (: add ace for "readonly" defined in config.xml :)
                        let $add-resource-ace := 
                            if($share-type) then
                                    switch ($target-type)
                                        case "USER" return
                                            sm:add-user-ace(xs:anyURI($collection || "/" || $res), $name, true(), $permissions-map("resource"))
                                        case "GROUP" return
                                            sm:add-group-ace(xs:anyURI($collection || "/" || $res), $name, true(), $permissions-map("resource"))
                                        default return
                                            ()
                            else
                                ()
                        return 
                            true()
            
                (: remove existing user/group aces for collection:)
                let $remove-collection-aces := security:clear-aces-by-name($collection, $name, $target-type)
                let $add-collaction-ace := 
                    if($share-type) then
                        switch ($target-type)
                            case "USER" return
                                sm:add-user-ace($collection, $name, true(), $permissions-map("collection"))
                            case "GROUP" return
                                sm:add-group-ace($collection, $name, true(), $permissions-map("collection"))
                            default return
                                    ()
                    else
                        ()
                return 
                    true()
            } catch * { 
                <error>Caught error {$err:code}: {$err:description}. Data: {$err:value}</error>
            } 
        else
            <error>Collection not available</error>
    )
};


let $action := request:get-parameter("action", ())
let $collection := xmldb:encode-uri(request:get-parameter("collection", ""))

return
    switch ($action)
        case "create-collection" return
            op:create-collection($collection, xmldb:encode-uri(request:get-parameter("name", "")))
            
        case "move-collection" return
            op:move-collection($collection, xmldb:encode-uri(request:get-parameter("path",())), false())

        case "rename-collection" return
            op:rename-collection($collection, xmldb:encode-uri(request:get-parameter("name",())))

        case "remove-collection" return
            op:remove-collection($collection)
        
        case "remove-resource" return
            op:remove-resource(request:get-parameter("resource",()))
        
        case "move-resource" return
            let $source-collection := xmldb:decode(request:get-parameter("source_collection",()))
            return 
                op:move-resource(xmldb:encode-uri($source-collection), xmldb:encode-uri(request:get-parameter("path",())), request:get-parameter("resource",()))

        case "set-ace-writeable" return
            op:set-ace-writeable($collection, xs:int(request:get-parameter("id",())), xs:boolean(request:get-parameter("is-writeable", false())))
        
        case "set-ace-writeable-by-name" return
            op:set-ace-writeable-by-name($collection, xs:string(request:get-parameter("target",())), xs:string(request:get-parameter("name",())), xs:boolean(request:get-parameter("is-writeable", false())))
        
        case "set-ace-executable-by-name" return
            op:set-ace-executable-by-name($collection, xs:string(request:get-parameter("target",())), xs:string(request:get-parameter("name",())), xs:boolean(request:get-parameter("is-executable", false())))

        case "remove-ace" return
            op:remove-ace($collection, xs:int(request:get-parameter("id",())))
            
        case "remove-ace-by-name" return
            op:remove-ace-by-name($collection, xs:string(request:get-parameter("target", ())) , xs:string(request:get-parameter("name", ())))
        
        case "is-valid-user-for-share" return
            op:is-valid-user-for-share(request:get-parameter("username",()))
        
        case "is-valid-group-for-share" return
            op:is-valid-group-for-share(request:get-parameter("groupname",()))

        case "add-user-ace" return
            let $log := util:log("DEBUG", request:get-parameter-names())
            let $mode := "r--"
            let $inherit := 
                if(request:get-parameter("inherit", false())) then 
                    true() 
                else 
                    false()
            let $writable := if (request:get-parameter("write", "")) then "w" else "-"
            let $executable := if (request:get-parameter("execute", "")) then "x" else "-"
            let $mode := 
                fn:replace($mode, "(.)(.)(.)", "$1" || $writable || $executable)

            let $log := util:log("DEBUG", "mode: " || $mode || " inherit: " || $inherit)
            return
(:                op:add-user-ace($collection, request:get-parameter("username",())):)
                op:add-user-ace($collection, request:get-parameter("username",()), $mode, $inherit)

        case "add-group-ace" return
            let $mode := "r--"
            let $inherit := 
                if(request:get-parameter("inherit", false())) then 
                    true() 
                else 
                    false()
            let $writable := if (request:get-parameter("write", "")) then "w" else "-"
            let $executable := if (request:get-parameter("execute", "")) then "x" else "-"
            let $mode := 
                fn:replace($mode, "(.)(.)(.)", "$1" || $writable || $executable)

            let $log := util:log("DEBUG", "mode: " || $mode || " inherit: " || $inherit)
            return
(:                op:add-group-ace($collection, request:get-parameter("groupname",()), $mode):)
                op:add-group-ace($collection, request:get-parameter("groupname",()), $mode, $inherit)

        case "get-move-folder-list" return
            op:get-move-folder-list($collection)
            
        case "get-move-resource-list" return
            op:get-move-resource-list($collection)
        case "getSharingRoles" return
            let $node := 
                <json>
                {
                    for $key in map:keys($config:sharing-permissions)
                    let $map := $config:sharing-permissions($key)
                    let $rank := $map("rank")
                    order by $rank
                    return 
                        <options>
                            <value>{$key}</value>
                            <title>{$map("name")}</title>
                            <collectionPermissions>{$map("collection")}</collectionPermissions>
                            <resourcePermissions>{$map("resource")}</resourcePermissions>
                        </options>
                }
                </json>
            return 
                (
                    response:set-header("Content-Type", "text/javascript"),
                    util:serialize($node, "method=json media-type=text/javascript")
                )
        
        case "getSharingRole" return
            sharing:get-resource-ace-mode-for-collection-ace($collection, request:get-parameter("target", "USER"), request:get-parameter("name", ""))

        case "share" return
(:                $collection || " " || request:get-parameter("name", "") || " " || request:get-parameter("target", "USER") || " " || request:get-parameter("type", ""):)
            let $collection-result := op:share($collection, request:get-parameter("name", ""), request:get-parameter("target", "USER"), request:get-parameter("type", ""))
            let $vra-images-result := op:share(xs:anyURI($collection || "/VRA_images"), request:get-parameter("name", ""), request:get-parameter("target", "USER"), request:get-parameter("type", ""))
            
            return
                if ($collection-result = true()) then
                    <status>Permission set.</status>
                else 
                    ( 
                        response:set-status-code($op:HTTP-FORBIDDEN),
                        <status>{$collection-result}</status>
                    )
        case "copyCollectionACL" return
            let $result := security:copy-collection-acl($collection, xmldb:encode-uri(request:get-parameter("targetCollection", "")))
            return
                if($result = true()) then
                    <status>Successfully copied ACL</status>
                else
                    (
                        response:set-status-code($op:HTTP-FORBIDDEN),
                        <status>{$result}</status>
                    )

        default return
            op:unknown-action($action)
    