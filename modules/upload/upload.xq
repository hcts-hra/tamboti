xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";

declare namespace upload = "http://exist-db.org/eXide/upload";
declare namespace functx = "http://www.functx.com";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $user := $config:dba-credentials[1];
declare variable $userpass := $config:dba-credentials[2];
declare variable $message := 'uploaded';
declare variable $image-collection-name := 'VRA_images';

declare function functx:escape-for-regex($arg as xs:string?) as xs:string {
     replace($arg, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')
 };
 
declare function functx:substring-after-last($arg as xs:string?, $delim as xs:string) as xs:string {
    replace($arg, concat('^.*', functx:escape-for-regex($delim)), '')
};

declare function local:generate-image-record($uuid, $file-uuid, $title, $workrecord) {
    let $vra-content :=
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:ext="http://exist-db.org/vra/extension" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
            <image id="{$uuid}" source="Tamboti" refid="" href="{$file-uuid}">
                <titleSet>
                    <display/>
                    <title type="generalView">{concat('Image record ', xmldb:decode($title))}</title>
                </titleSet>
                <relationSet>
                    <relation type="imageOf" relids="{$workrecord}" refid="" source="Tamboti">attachment</relation>
                </relationSet>
            </image>
        </vra>

    return $vra-content    
};

declare function upload:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return
            (xmldb:create-collection($collection, $components[1]),
            upload:mkcol-recursive($newColl, subsequence($components, 2)))
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function upload:mkcol($collection, $path) {
    upload:mkcol-recursive($collection, tokenize($path, "/"))[last()]
};

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string) {
    local:apply-perms($collection-path, $username, $mode),
        for $child in xmldb:get-child-resources($collection-path)
        let $resource-path := fn:concat($collection-path, "/", $child)
        return
            local:apply-perms($resource-path, $username, $mode),
        for $child in xmldb:get-child-collections($collection-path)
        let $child-collection-path := fn:concat($collection-path, "/", $child)
        return
            local:recurse-items($child-collection-path, $username, $mode)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username, true(), $mode)
};

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string) {
    local:apply-perms($collection-path, $username, $mode),
    for $child in xmldb:get-child-resources($collection-path)
    let $resource-path := fn:concat($collection-path, "/", $child)
    return
        local:apply-perms($resource-path, $username, $mode),
            for $child in xmldb:get-child-collections($collection-path)
            let $child-collection-path := fn:concat($collection-path, "/", $child)
            return
                local:recurse-items($child-collection-path, $username, $mode)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username,true(), $mode)
};

declare function upload:upload($filetype, $filesize, $filename, $data, $doc-type, $workrecord, $collection-owner-username as xs:string) {
    let $myuuid := concat('i_', util:uuid())
    let $parentcol :=
        if (exists(collection($config:mods-root)//vra:work[@id=$workrecord]/@id))
        then util:collection-name(collection($config:mods-root)//vra:work[@id = $workrecord]/@id)
        else 
            if (exists(collection($config:mods-root)//mods:mods[@ID=$workrecord]/@ID))
            then util:collection-name(collection($config:mods-root)//mods:mods[@ID=$workrecord]/@ID)
            else ()
    let $parentdoc_path := concat($parentcol, '/', $workrecord, '.xml')
    let $null := util:log('ERROR', $parentcol)
    let $tag-changed := upload:add-tag-to-parent-doc($parentdoc_path, upload:determine-type($workrecord), $myuuid)
    
    (:set the image VRA folder by adding the suffix:)
    let $upload :=  
        if (exists($parentcol))
        then system:as-user($user, $userpass, 
                let $newcol := $parentcol
                let $mkdir := if (xmldb:collection-available($newcol)) 
                    then ()
                    else
                        let $null := upload:mkcol('/', $newcol)
                        let $null := security:apply-parent-collection-permissions(xs:anyURI($newcol))
                            return $null
                (:create images collection:)
                let $create-images-collection := 
                    if (not(xmldb:collection-available(concat($newcol, '/', $image-collection-name))))
                    then
                        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
                            (
                                xmldb:create-collection($newcol, $image-collection-name),
                                security:apply-parent-collection-permissions(xs:anyURI($newcol)),
                                sm:chown(xs:anyURI($newcol), $collection-owner-username)
                            )
                        )
                    else()
                let $newcol := concat($newcol, '/', $image-collection-name)                
                (: filenames  :)
                let $image-filename := concat($myuuid, '.', functx:substring-after-last($filename, '.'))
                let $image-record-filename := concat($myuuid, '.xml')
                
                (: store image record :)
                let $image-record := local:generate-image-record($myuuid, $image-filename, $filename, $workrecord)
                let $xmlupload := xmldb:store($newcol, $image-record-filename, $image-record)
                
                (: store image :)
                let $upload := xmldb:store($newcol, $image-filename, $data)
                
                let $apply-permissions :=
                    (
                        sm:chown(xs:anyURI(concat($newcol, '/', $image-filename)), $collection-owner-username),
                        sm:chmod(xs:anyURI(concat($newcol, '/', $image-filename)), 'rwxr-xr-x'),
                        sm:chgrp(xs:anyURI(concat($newcol, '/', $image-filename)), $config:biblio-users-group),
                        
                        sm:chown(xs:anyURI(concat($newcol, '/', $image-record-filename)), $collection-owner-username),
                        sm:chmod(xs:anyURI(concat($newcol, '/', $image-record-filename)), 'rwxr-xr-x'),
                        sm:chgrp(xs:anyURI(concat($newcol, '/', $image-record-filename)), $config:biblio-users-group),
                        
                        security:apply-parent-collection-permissions(xs:anyURI(concat($newcol, '/', $image-filename))),
                        security:apply-parent-collection-permissions(xs:anyURI(concat($newcol, '/', $image-record-filename)))
                    )

                return concat($filename, ' ' ,$message)
        )
       else ()
        return $upload
};
 
declare function upload:add-tag-to-parent-doc($parentdoc_path as xs:string, $parent_type as xs:string, $myuuid as xs:string) {
    system:as-user($user, $userpass,
        (
            let $parentdoc := doc($parentdoc_path)
            let $add :=
                if ($parent_type eq 'vra')
                then
                    let $vra_insert := <vra:relation type="imageIs" relids="{$myuuid}" source="Tamboti" refid=""  pref="true">general view</vra:relation>
                    let $relationTag := $parentdoc/vra:vra/vra:work/vra:relationSet
                        return
                            let $vra-insert := $parentdoc
                            let $insert_or_update := 
                                if (not($relationTag))
                                then update insert <vra:relationSet></vra:relationSet> into $vra-insert/vra:vra/vra:work 
(:                                    if (security:can-write-collection($parentdoc_path)) :)
(:                                    then update insert  <vra:relationSet></vra:relationSet> into $vra-insert/vra:vra/vra:work:)
(:                                    else util:log('error', 'no write access') :)
                                else ()
                            let $vra-update := update insert $vra_insert into $parentdoc/vra:vra/vra:work/vra:relationSet
                            return $vra-update
                else 
                    if ($parent_type eq 'mods')
                    then
                        let $mods-insert := 
                            <mods:relatedItem type="constituent">
                                <mods:typeOfResource>still image</mods:typeOfResource>
                                <mods:location>
                                    <mods:url displayLabel="Illustration" access="preview">{$myuuid}</mods:url>
                                </mods:location>
                            </mods:relatedItem>
                        let $mods-insert-tag := $parentdoc
                        let $mods-update := update insert  $mods-insert into $mods-insert-tag/mods:mods
(:                            if (security:can-write-collection($parentdoc_path)) :)
(:                            then update insert  $mods-insert into $mods-insert-tag/mods:mods:)
(:                            else util:log('error', 'no write access') :)
                        return  $mods-update 
                    else  ()
               
            return $add
        )
    )
};

declare function upload:determine-type($workrecord) {
    let $vra_image := collection($config:mods-root)//vra:work[@id = $workrecord]/@id
    let $type :=
        if (exists($vra_image)) 
        then 'vra'
        else
            let $mods := collection($config:mods-root)//mods:mods[@ID = $workrecord]/@ID
            let $mods_type :=
                if (exists($mods)) 
                then 'mods'
                else ()
                    return $mods_type
                    
    return $type
};

let $image-types := ('png', 'jpg', 'gif', 'tiff', 'jpeg', 'tif')
let $uploadedFile := 'uploadedFile'
let $data := request:get-uploaded-file-data($uploadedFile)
let $filename := request:get-uploaded-file-name($uploadedFile)
let $filesize := request:get-uploaded-file-size($uploadedFile)
let $result := for $x in (1 to count($data))
    let $filetype := functx:substring-after-last($filename[$x], '.')
    let $doc-type := if (ends-with(lower-case($filetype), $image-types))
        then 'image'
        else ''
        return
            if ($doc-type eq 'image')
            then
                let $workrecord :=
                    if (string-length(request:get-header('X-File-Parent')) > 0)
                    then config:process-request-parameter(request:get-header('X-File-Parent'))
                    else ()
                let $upload := 
                    if (exists($workrecord))
                    then upload:upload($filetype, $filesize[$x],$filename[$x], $data[$x], $doc-type, $workrecord, tamboti-utils:get-username-from-path($workrecord))
                    else
                        (:record for the collection:)
                        let $collection-folder := xmldb:decode(request:get-header('X-File-Folder'))
                        let $collection-owner-username := tamboti-utils:get-username-from-path($collection-folder)
                        (: if the collection file exists in the file folder:)
                        (:read the collection uuid:)
                        let $collection_vra := collection($config:mods-root)//vra:collection
                        let $collection_uuid :=  
                            if (exists($collection_vra))
                            then $collection_vra/@id
                            else concat('c_', util:uuid())
                        
                        (:else generate the new collection file:)
                        let $null := 
                            if (exists($collection_vra/@id))
                            then ()
                            else
                                let $vra-collection-xml := 
                                    <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd" xmlns:ext="http://exist-db.org/vra/extension">
                                        <collection id="{$collection_uuid}" source="" refid="{$collection_uuid}"></collection>
                                    </vra>
                                    (:let $store := system:as-user($user, $userpass, xmldb:store($collection-folder, concat($collection_uuid, '.xml'), $vra-collection-xml))
                                    return $store
                                    :)
                                        return ()
                                        
                        (:generate the  work record, if collection xml exists:)
                        let $work-xml-generate :=
                            if (exists($collection_uuid))
                            then
                                let $work_uuid := concat('w_', util:uuid())
                                let $vra-work-xml := 
                                    <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:ext="http://exist-db.org/vra/extension" xmlns:hra="http://cluster-schemas.uni-hd.de" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
                                        <work id="{$work_uuid}" source="Kurs" refid="{$collection_uuid}">
                                        <titleSet>
                                            <display/>
                                            <title type="generalView">{concat('Work record ', $filename[$x])}</title>
                                        </titleSet>  
                                        </work>
                                    </vra>
                                let $create-workrecord :=
                                    system:as-user($user, $userpass,
                                        (
                                            xmldb:store(xmldb:encode($collection-folder), concat($work_uuid, '.xml'), $vra-work-xml),
                                            sm:chown(xs:anyURI(concat($collection-folder, '/', $work_uuid, '.xml')), $collection-owner-username),
                                            sm:chmod(xs:anyURI(concat($collection-folder, '/', $work_uuid, '.xml')), 'rwxr-xr-x'),
                                            sm:chgrp(xs:anyURI(concat($collection-folder, '/', $work_uuid, '.xml')), $config:biblio-users-group)
                                        )
                                    )
                                let $store := upload:upload( $filetype, $filesize[$x], $filename[$x], $data[$x], $doc-type, $work_uuid, $collection-owner-username)
                                
                                return $message
                            else ()
                                return concat($filename[$x], ' ', $message)
                    return $upload
        else 
            let $upload := 'unsupported file format'
                return $upload

return $result
