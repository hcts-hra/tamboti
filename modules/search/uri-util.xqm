xquery version "1.0";

(: How much of this is really needed? Isn't it enough to xmldb:decode-uri() and xmldb:encode-uri()? :)

module namespace uu = "http://exist-db.org/mods/uri-util";

declare variable $uu:encodings := (
    "%20", " ",
    "%C3%A4", "ä",
    "%C3%84", "Ä",
    "%C3%B6", "ö",
    "%C3%96", "Ö",
    "%C3%BC", "ü",
    "%C3%9C", "Ü",
    "%C3%9F", "ß"
);

declare function uu:escape-collection-path($path as xs:string?) as xs:string? {
    uu:_escape($path)
    (:xmldb:encode-uri($path):)
};

declare function uu:_escape($path as xs:string?) {
    uu:_escape($path, 1)
};

declare function uu:_escape($path as xs:string?, $i as xs:int) as xs:string? {
    
    if(fn:empty($path))then
        ()
    else
        if($i lt fn:count($uu:encodings))then
          let $new-path := fn:replace($path, $uu:encodings[$i+1], $uu:encodings[$i]) return
             uu:_escape($new-path, $i+2)
        else
            $path
};

declare function uu:unescape-collection-path($path as xs:string?) as xs:string? {
    xmldb:decode-uri($path)
};

declare function uu:_un-escape($path as xs:string?) {
    uu:_un-escape($path, 1)
};

declare function uu:_un-escape($path as xs:string?, $i as xs:int) as xs:string? {
    
    if(fn:empty($path))then
        ()
    else
        if($i lt fn:count($uu:encodings))then
          let $new-path := fn:replace($path, $uu:encodings[$i], $uu:encodings[$i+1]) return
             uu:_un-escape($new-path, $i+2)
        else
            $path
};