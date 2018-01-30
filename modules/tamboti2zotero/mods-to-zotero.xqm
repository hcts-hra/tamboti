xquery version "3.1";

module namespace mods-to-zotero = "http://hra.uni-heidelberg.de/ns/mods-to-zotero/";

declare function mods-to-zotero:numPages($extent) {
    if ($extent/element())
    then
        let $start := $extent/*:start
        let $end := $extent/*:end
        let $total := $extent/*:total
        let $list := $extent/*:list
        let $full-description-1 := string-join(($start, $end)[. != ''], '-')
        let $full-description-2 := string-join(($full-description-1, $total, $list)[. != ''], ", ")
        
        return $full-description-2
    else $extent/string()  
};
