xquery version "1.0";

import module namespace json="http://www.json.org";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace session = "http://exist-db.org/xquery/session";
import module namespace util = "http://exist-db.org/xquery/util";

import module namespace mods-common="http://exist-db.org/mods/common" at "../mods-common.xql";

declare namespace mods="http://www.loc.gov/mods/v3";

declare option exist:serialize "method=json media-type=text/javascript";

declare variable $local:filmstrip-rows := 2;
declare variable $local:magic-width := 68;

declare variable $local:image-exts := ("tif", "tiff", "bmp", "png", "jpg", "jpeg", "svg", "gif");

declare function local:get-images-from-collection($start as xs:int, $end as xs:int) as xs:string* {
    let $resources := local:_get-collection-resources() return
        for $pos in $start to $end return
            $resources[$pos]
};

declare function local:get-images-from-cache($start as xs:int, $end as xs:int) as element(mods:url)* {
    let $cached := session:get-attribute("mods:cached") return
    
        for $pos in $start to $end
        let $entry := $cached[$pos] 
        let $image := $entry/mods:location/mods:url[@access="preview"]
        return
            $image
};

declare function local:get-collection-image-count() as xs:integer {
    
        fn:count(local:_get-collection-resources())
};

declare function local:_get-collection-resources() as xs:string* {
    let $collection := request:get-parameter("collection",())
    for $resource in xmldb:get-child-resources($collection)[fn:lower-case(fn:replace(. , ".*\.", "")) = $local:image-exts]
    order by number(replace($resource, "^\d+_0*(\d+)_.*$", "$1")) ascending
    return
        $resource
};

declare function local:get-cache-image-count() as xs:integer {
    let $cached := session:get-attribute("mods:cached") return
        fn:count($cached)
};

declare function local:get-image-collection-for-collection($image as xs:string) as xs:string {
    request:get-parameter("collection",())
};

declare function local:get-image-collection-for-cached($image as element(mods:url)) as xs:string {
    util:collection-name($image)
};

declare function local:thumbnails($filmstrip-width as xs:int, $page as xs:int, $fn-images-available as function, $fn-get-images as function, $fn-get-image-collection as function) {
    
    let $max-images-per-page := xs:int(fn:floor(($filmstrip-width div $local:magic-width) * $local:filmstrip-rows)),
    $images-available := util:call($fn-images-available),
    $total-pages := xs:int(fn:ceiling($images-available div $max-images-per-page)),
    
    $start := 
        if($page eq 1)then
            1
        else if((($page -1) * $max-images-per-page) lt $images-available)then
            ($page -1) * ($max-images-per-page) + 1
        else
            ($total-pages - 1) * $max-images-per-page
    ,
    
    $end := if($start + ($max-images-per-page -1) lt $images-available)then
				$start + ($max-images-per-page -1)
			else
				$images-available
    
    return
        <json:value>
            <magicWidth json:literal="true">{$local:magic-width}</magicWidth>
            <page json:literal="true">{$page}</page>
            <totalPages json:literal="true">{$total-pages}</totalPages>
            <images>
        {
            
            for $image at $i in util:call($fn-get-images, $start, $end) return
        
                if ($image) then
                    let $collection-name := util:call($fn-get-image-collection, $image),
                    $imgLink := fn:concat("images", substring-after($collection-name, "/db"), "/", $image)
                    return
                        <json:value>
                            <src>{$imgLink}?s=64</src>
                            <item json:literal="true">{$start + $i - 1}</item>
                        </json:value>
                else
                    ()
        }
            </images>
        </json:value>
};

declare function local:image($item as xs:int) {
    let $cached := session:get-attribute("mods:cached")
    return
        if ($cached[$item]) then
            let $entry := $cached[$item]
            let $image := $entry/mods:location/mods:url[@access="preview"]/string()
            let $imgLink := concat("images/", substring-after(util:collection-name($entry), "/db"), "/", $image)
            return
                <image>
                    <src>{ $imgLink }</src>
                    <title>{ string-join(mods-common:get-short-title($entry), " ") }</title>
                </image>
        else
            ()
};

declare function local:image($item as xs:int, $collection as xs:string) {
    for $image in local:get-images-from-collection($item, $item)
    let $imgLink := concat("images", substring-after($collection, "/db"), "/", $image)
    return
        <image>
            <src>{ $imgLink }</src>
        </image>
};

let $item := request:get-parameter("item", ())
let $collection := request:get-parameter("collection", ())
return
    if ($item) then
        if ($collection) then
            local:image(xs:int($item), $collection)
        else
            local:image(xs:int($item))
    else
        let $fn :=
            if(request:get-parameter("collection", ())) then
                (
                    util:function(xs:QName("local:get-collection-image-count"), 0),
                    util:function(xs:QName("local:get-images-from-collection"), 2),
                    util:function(xs:QName("local:get-image-collection-for-collection"), 1)
                )
            else
                (
                    util:function(xs:QName("local:get-cache-image-count"), 0),
                    util:function(xs:QName("local:get-images-from-cache"), 2),
                    util:function(xs:QName("local:get-image-collection-for-cached"), 1)
                )
        return
            local:thumbnails(xs:int(request:get-parameter("filmstripWidth", 800)), xs:int(request:get-parameter("page", 1)), $fn[1], $fn[2], $fn[3])