xquery version "3.0";

declare namespace user="http://exist-db.org/xquery/biblio/user";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare function user:add-to-personal-list() {
    let $cached := session:get-attribute("mods:cached")
    let $pos := xs:integer(request:get-parameter("pos", 1))
    let $oldList := session:get-attribute("personal-list")
    let $oldList :=
        if ($oldList) then $oldList else <mylist/>
    let $id := concat(document-uri(root($cached[$pos])), '#', util:node-id($cached[$pos]))
    let $newList :=
        <myList>
            <listitem id="{$id}">{ $cached[$pos] }</listitem>
            { $oldList/listitem }
        </myList>
    let $stored := session:set-attribute("personal-list", $newList)
    return
        ()
};

declare function user:remove-from-personal-list() {
    (:Where does "save_" come from?:)
    let $id := substring-after(request:get-parameter("id", ()), "save_")
    let $oldList := session:get-attribute("personal-list")
    let $newList :=
        <myList>
            { $oldList/listitem[not(@id = $id)] }
        </myList>
    let $stored := session:set-attribute("personal-list", $newList)
    return
        ()
};

declare function user:personal-list($list as xs:string) {
    if ($list eq 'add') 
    then user:add-to-personal-list()
    else user:remove-from-personal-list()
};

declare function user:personal-list-size() {
    let $list := session:get-attribute("personal-list")
    (:let $log := util:log("DEBUG", ("##$list): ", $list)):)
    return
        if (count($list/listitem) eq 1)
        then <span>{count($list/listitem)} item</span>
        else <span>{count($list/listitem)} items</span>
};

declare function user:export-personal-list() as element(my-list-export) {
    util:declare-option("exist:serialize", "method=xml media-type=application/xml"),   
    response:set-header("Content-Disposition", "attachment; filename=my-list-export.xml"),
    let $vra-images := user:get-vra-image-records()/vra:image
    let $vra-work := session:get-attribute("personal-list")/listitem/vra:vra/vra:work

    return
        <my-list-export>
        {
            (
            session:get-attribute("personal-list")/listitem/mods:mods, 
                            <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
            {
            $vra-work,
            $vra-images
                
            }
                </vra>,
            session:get-attribute("personal-list")/listitem/tei:TEI
            )
        }
        </my-list-export>
};

declare function user:get-vra-image-records() as element()* {
    let $work-records := session:get-attribute("personal-list")/listitem/vra:vra
    let $image-records :=
        for $work-record in $work-records
        let $image-record-ids := $work-record//vra:relationSet/vra:relation[@type eq "imageIs"]/@relids/string()
        let $image-record-ids := tokenize($image-record-ids, ' ')
        return
            for $image-record-id in $image-record-ids
            let $image-record := collection($config:mods-root-minus-temp)/vra:vra[vra:image/@id eq $image-record-id]
                return $image-record
    return
        $image-records
};

let $list := request:get-parameter("list", ())
let $export := request:get-parameter("export", ())
let $list-size := user:personal-list-size()

return
    if ($export)
    then user:export-personal-list()
    else 
        if ($list) 
        then user:personal-list($list)
        else user:personal-list-size()
