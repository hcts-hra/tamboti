xquery version "3.1";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink="http://www.w3.org/1999/xlink";
    
let $query-string-1 := "numbers"
let $query-string-2 := "uuid-6e8d9f5b-3bee-3636-9941-7078a269366d"

let $resources := collection('/data')//
    (
        (
            mods:mods[ft:query(., $query-string-1)]
            union
            vra:vra[ft:query(.[vra:work], $query-string-1)]
            union
            tei:TEI[ft:query(., $query-string-1)]
            union
            atom:entry[ft:query(., $query-string-1)]
            union
            ft:search('page:' || $query-string-1)
            union
            mods:mods[@ID eq $query-string-1]
            union
            mods:mods[mods:relatedItem/@xlink:href eq $query-string-1]
            union
            atom:entry[atom:id eq $query-string-1]
            union
            vra:vra[vra:work/@id eq $query-string-1]
            union
            vra:vra[vra:work//@relids eq $query-string-1]
            union
            svg:svg[@xml:id=$query-string-1]
        )        
        intersect 
        (
            mods:mods[@ID eq $query-string-2]
            union
            (:vra:vra[vra:collection/@id eq '$q']
            union:)
            vra:vra[vra:work/@id=$query-string-2 or vra:work//vra:relation/@relids=$query-string-2]
            union
            (:vra:vra[vra:image/@id eq '$q']
            union:)
            atom:entry[atom:id eq $query-string-2]
            union
            svg:svg[@xml:id eq $query-string-2]
        )        
    )

    
return count($resources)
