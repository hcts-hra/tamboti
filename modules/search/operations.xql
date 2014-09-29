xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../../frameworks/vra-hra/vra-hra.xqm";
import module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "../../frameworks/mods-hra/mods-hra.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";

declare namespace group = "http://commons/sharing/group";
declare namespace op="http://exist-db.org/xquery/biblio/operations";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace xlink="http://www.w3.org/1999/xlink";

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
    let $parent-collection-owner := xmldb:get-owner($parent)
    let $parent-collection-group := xmldb:get-group($parent)

    let $create-collection :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
    
                let $collection := xmldb:create-collection($parent, $name)
                
                (: inherit ACE from parent collection to new collection:)
                let $inherit-ACE := security:duplicate-acl($parent, $parent || "/" || $name)
        
                (: just the owner has full access - to start with :)
                let $null := sm:chmod(xs:anyURI($collection), "rwxr-xr-x")
    
                (: to be sure that the collection owner's group is the intended one :)
                let $change-group := sm:chgrp(xs:anyURI($collection), $parent-collection-group)
                return ()
        )
    let $change-owner :=
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                (: set parent collection owner as owner for new collection :)
                sm:chown(xs:anyURI($parent || "/" || $name), $parent-collection-owner)
        )
        
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
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
            (
                (: Move collection to target collection   :)
                xmldb:move($collection, $target-collection),
                (: recursively set owner of target collection as owner :)
                security:recursively-set-owner-and-group($moved-collection-path, $target-collection-owner, $target-collection-group),
                (: clear ACL and add ACE for former collecton owner, if not owner of target-collection:)
                if (not($source-collection-owner = $target-collection-owner)) then
                    (
                        sm:clear-acl($moved-collection-path),
                        sm:add-user-ace($moved-collection-path, $source-collection-owner, true(), "rwx"),
                        (: inherit ACL recursively to all subresources and -collections :)
                        security:recursively-inherit-collection-acl($moved-collection-path)
                    )
                else
                    ()
            )
        )

    return
        <status id="moved" from="{xmldb:decode-uri($collection)}">{xmldb:decode-uri($target-collection)}</status>
};

(:NB: name change does not take place if the new name is already taken.:)
(:TODO: notify user if the new name is already taken.:)
declare function op:rename-collection($path as xs:anyURI, $name as xs:string) as element(status) {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $null := xmldb:rename($path, $name)
        return
            (:<status id="renamed" from="{uu:unescape-collection-path($path)}">{$name}</status>:)
            <status id="renamed" from="{xmldb:decode-uri($path)}">{xmldb:decode-uri($name)}</status>
    )
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
        else system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove($collection)) 
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
    let $mods-record := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
    let $xlink-to-mods-record := concat('#', $resource-id)
    (:since xlinks are also inserted manually, check also for cases when the pound sign has been forgotten:)
    let $xlinked-mods-records := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href = ($xlink-to-mods-record, $resource-id)]
    
    let $vra-work-record := collection($config:mods-root-minus-temp)//vra:vra/vra:work[@id eq $resource-id]
    (:NB: we assume that @relids (plural) can hold several values:)
    let $vra-image-records := collection($config:mods-root-minus-temp)//vra:vra[vra:image/vra:relationSet/vra:relation[contains(@relids, $resource-id)]]
    (:NB: we assume that all image files are in the same collection as their metadata 
    and that all image records belonging to a work record are in the same collection:)
    let $vra-image-record-collection := util:collection-name($vra-image-records[1])
    let $vra-binary-file-names := $vra-image-records/vra:image/@href    
    let $vra-records := ($vra-work-record, $vra-image-records)
    
    let $records := 
        if ($mods-record) 
        then $mods-record 
        else $vra-records 
    
    for $record in $records 
    return
    (
        (:do not remove records which erroneously have the same ID:)
        (:TODO: inform user that this is the case:)
        if (count($record) eq 1)
        then
            (:do not remove a record which is xlinked to from one or more other records:)
            (:TODO: inform user that this is the case:)
            if (count($xlinked-mods-records) eq 0) 
            then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove(util:collection-name($record), util:document-name($record)))
            else ()
        else ()
        ,
        if (count($vra-binary-file-names) gt 0) 
        then
            for $vra-binary-name in $vra-binary-file-names
            return
                (:NB: since this iterates inside another iteration, files are attempted deleted which have been deleted already, 
                causing the script to halt. However, the existence of the file to be deleted should first be checked, 
                in order to prevent the function from halting in case the file does not exist.:)
                if (util:binary-doc-available(concat($vra-image-record-collection, '/', $vra-binary-name))) 
                then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove($vra-image-record-collection, $vra-binary-name))
                else ()
        else ()
(:        ,:)
(:        response:set-status-code($HTTP-FORBIDDEN),:)
(:        <p>Unknown action: Movee.</p>:)
    )
};

declare function op:remove-resource($resource-id as xs:string) as element(status)* {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], 
    (
        let $mods-doc := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
        let $xlink := concat('#', $resource-id)
        (:since xlinks are also inserted manually, check also for cases when the pound sign has been forgotten:)
        let $mods-xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href = ($xlink, $resource-id)]
        (:let $base-uri := concat(util:collection-name($doc), '/', util:document-name($doc)):)
        (:NB: we assume that @relids (plural) can hold several values:)
        
        let $vra-work := collection($config:mods-root-minus-temp)//vra:vra/vra:work[@id eq $resource-id]
        let $vra-images := collection($config:mods-root-minus-temp)//vra:vra[vra:image/vra:relationSet/vra:relation[contains(@relids, $resource-id)]]
        (:NB: we assume that all image files are in the same collection as their metadata and that all image records belonging to a work record are in the same collection:)
        let $vra-image-collection := util:collection-name($vra-images[1])
        let $vra-binary-names := $vra-images/vra:image/@href    
        let $vra-docs := ($vra-work, $vra-images)
        
        let $docs := if ($mods-doc) then $mods-doc else $vra-docs 
       
        for $doc in $docs return
            (
                (:do not remove records which erroneously have the same ID:)
                (:NB: inform user that this is the case:)
                if (count($doc) eq 1)
                then
                    (:do not remove records which are linked to from other records:)
                    (:NB: inform user that this is the case:)
                    if (count($mods-xlink-recs/..) eq 0) 
                    then
                        (
                            xmldb:remove(util:collection-name($doc), util:document-name($doc))
                            ,
                            if (count($vra-binary-names) gt 0) then
                                for $vra-binary-name in $vra-binary-names
                                    return
                                        (:NB: since this iterates inside another iteration, files are attempted deleted which have been deleted already, causing the script to halt. However,:)
                                        (:the existence of the file to be deleted should first be checked, in order to prevent the function from halting in case the file does not exist.:)
                                        if (util:binary-doc-available(concat($vra-image-collection, '/', $vra-binary-name))) then
                                            xmldb:remove($vra-image-collection, $vra-binary-name)
                                        else ()
                            else ()
                        )
                    else ()
                else()
                (:
                ,
                update insert $record into doc('/db/resources/temp/deletions.xml')/records
                :)
                ,
                <status id="removed">{$resource-id}</status>
            )
    )
    )
};



(:~
: @ resource-id has the format db-document-path#node-id e.g. /db/mods/eXist/exist-articles.xml#1.36
TODO: Perform search for record after it has been moved. 
:)
declare function op:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
    let $resource := collection($config:mods-root-minus-temp)//(mods:mods[@ID eq $resource-id][1] | vra:vra[vra:work[@id eq $resource-id]][1])
    let $record-namespace := namespace-uri($resource)
    let $move-record :=
        switch($record-namespace)
            case "http://www.loc.gov/mods/v3"
                return mods-hra-framework:move-resource($source-collection, $target-collection, $resource-id)
            case "http://www.vraweb.org/vracore4.htm"
                return vra-hra-framework:move-resource($source-collection, $target-collection, $resource-id)
            default return ()

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
 : @param $collection the collection to remove ACE from
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

declare function op:add-user-ace($collection as xs:anyURI, $username as xs:string) as element(status) {    
    let $ace-id := sharing:add-collection-user-ace($collection, $username)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-user-ace(xs:anyURI($collection || "/VRA_images"), $username)
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

declare function op:add-group-ace($collection as xs:anyURI, $groupname as xs:string) as element(status) {
    let $ace-id := sharing:add-collection-group-ace(xs:anyURI($collection), $groupname)    
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-group-ace(xs:anyURI($collection || "/VRA_images"), $groupname)
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
    for $child-collection in xmldb:get-child-collections($start-collection)
        return
            (concat($start-collection, '/', $child-collection), 
            op:get-child-collection-paths(concat($start-collection, '/', $child-collection) cast as xs:anyURI))
};

(:A collection cannot be moved into itself or into its parent, nor can it be moved into a subcollection, 
so it is necessary to check against the path of the collection that is to be moved.
A file cannot, by stipulation, be moved into the top level of the home collection, nor can it be moved to its own parent collection.:)
(:TODO: capture the collection that the resource to be moved belongs to.:)


declare function op:get-move-folder-list($chosen-collection as xs:anyURI) as element(select) {
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
                (:let $log := util:log("DEBUG", ("##$path): ", $path)):)
                (:let $log := util:log("DEBUG", ("##$chosen-collection): ", $chosen-collection)):)
                (:let $log := util:log("DEBUG", ("##$starts-with): ", starts-with($path, $chosen-collection))):)
                (:let $log := util:log("DEBUG", ("##$home): ", security:get-home-collection-uri(security:get-user-credential-from-session()[1]))):)
                (:let $log := util:log("DEBUG", ("##$shared): ", sharing:get-shared-collection-roots(true()))):)
                let $display-path := substring-after($path, '/db/')
                let $user := xmldb:get-current-user()
                let $display-path := replace($path, concat('users/', $user), 'Home')
                order by $display-path
                return
                (:leave out the folder that the user has marked, since you cannot move something to itself:)
                (:leave out descendant folders, since you cannot move a folders into a descendant:)
                (:if (contains($path, $chosen-collection) or contains($chosen-collection, $path)):)
                    if ($path eq $chosen-collection or functx:substring-after-last($path, "/") = "VRA_images") then
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

let $action := request:get-parameter("action", ())

return
    if($action eq "create-collection") then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        let $name := xmldb:encode-uri(request:get-parameter("name", ""))
        return
            op:create-collection($collection, $name)
            
    else if($action eq "move-collection")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:move-collection($collection, xmldb:encode-uri(request:get-parameter("path",())), false())
            
    else if($action eq "rename-collection")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:rename-collection($collection, xmldb:encode-uri(request:get-parameter("name",())))
            
    else if($action eq "remove-collection")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:remove-collection($collection)
            
    else if($action eq "remove-resource")then
        op:remove-resource(request:get-parameter("resource",()))
        
    else if($action eq "move-resource")then
        let $source-collection := xmldb:decode(request:get-parameter("source_collection",()))
        return 
            op:move-resource(xmldb:encode-uri($source-collection), xmldb:encode-uri(request:get-parameter("path",())), request:get-parameter("resource",()))
            
    else if($action eq "set-ace-writeable")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:set-ace-writeable($collection, xs:int(request:get-parameter("id",())), xs:boolean(request:get-parameter("is-writeable", false())))
            
    else if($action eq "set-ace-writeable-by-name")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:set-ace-writeable-by-name($collection, xs:string(request:get-parameter("target",())), xs:string(request:get-parameter("name",())), xs:boolean(request:get-parameter("is-writeable", false())))
            
    else if($action eq "remove-ace")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:remove-ace($collection, xs:int(request:get-parameter("id",())))
            
    else if($action eq "remove-ace-by-name")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:remove-ace-by-name($collection, xs:string(request:get-parameter("target", ())) , xs:string(request:get-parameter("name", ())))
            
    else if($action eq "add-user-ace") then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:add-user-ace($collection, request:get-parameter("username",()))
            
    else if($action eq "is-valid-user-for-share")then
        op:is-valid-user-for-share(request:get-parameter("username",()))
        
    else if($action eq "add-group-ace")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:add-group-ace($collection, request:get-parameter("groupname",()))
            
    else if($action eq "is-valid-group-for-share")then
        op:is-valid-group-for-share(request:get-parameter("groupname",()))
        
    else if($action eq "get-move-folder-list")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:get-move-folder-list($collection)
            
     else if($action eq "get-move-resource-list")then
        let $collection := xmldb:encode-uri(request:get-parameter("collection", ()))
        return
            op:get-move-resource-list($collection)
            
     else
        op:unknown-action($action)
