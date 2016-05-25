xquery version "3.0";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "../../modules/search/application.xql";
import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare function local:generate-query($query-as-xml as element()) as xs:string* {
    let $query :=
        typeswitch ($query-as-xml)
            case element(query)
            return 
                for $child in $query-as-xml/*
                return local:generate-query($child)
                
            case element(and)
            return
                string-join(
                    for $child in $query-as-xml/*
                    return local:generate-query($child), " intersect "
                )
            
            case element(or)
            return
                string-join(
                    for $child in $query-as-xml/*
                    return local:generate-query($child), " union "
                )            

            case element(not)
            return
                string-join(
                    for $child in $query-as-xml/*
                    return local:generate-query($child), " except "
                )            

            (:Determine which field to search in: if a field has been specified, use it; otherwise default to "any Field (MODS, TEI, VRA)".:)
            case element(field)
            return
                let $expr := $biblio:FIELDS/field[@name eq $query-as-xml/@name or @short-name eq $query-as-xml/@short-name]/search-expression
                let $expr := 
                    if ($expr) 
                    then $expr
                    (:Default to a search in All if no search field is chosen, i.e. when Simple Search is used.:)
                    else $biblio:FIELDS/field[@name eq $biblio:FIELDS/field[1]/@name]/search-expression
                (:This results in expressions like:
                <field name="Title">mods:mods[ft:query(.//mods:titleInfo, '$q', $options)]</field>.
                The search term, to be substituted for '$q', is held in $query-as-xml. :)
                (: When searching for ID and xlink:href, do not use the chosen collection-path, but search throughout all of /resources. :)
                return
                    (:The search term held in $query-as-xml is substituted for the '$q' held in $expr.:)
                    replace($expr, '\$q', biblio:normalize-search-string($query-as-xml/string()))
            case element(collection)
            return
                if (not($query-as-xml/..//field)) 
                then ('collection("', $query-as-xml, '")//(mods:mods | vra:vra[vra:work] | tei:TEI | atom:entry | svg:svg)')
                else ()
            default return ()
        
         (:Leading wildcards cannot appear in searches within extracted text. :) 
         let $query := 
            for $q in $query
            return replace(replace($q, ':[?*]', ':'), '\s[?*]', ' ')
            
         return $query
};

declare function local:generate-full-query($collection-path as xs:string, $query as xs:string*) as xs:string* {
    let $collection :=
        (: When searching inside whole users, do not show results from own home collection :)
        let $all-collections :=
            if (ends-with($collection-path, $config:users-collection)) then
                security:get-searchable-child-collections(xs:anyURI($collection-path), true())
            else 
                security:get-searchable-child-collections(xs:anyURI($collection-path), false())
                
        return "collection('" || fn:string-join(($collection-path, $all-collections), "', '") ||  "')//"
    
    return "collection(" || $collection || ")//(" || $query || ")"
};

let $query-as-xml :=
    <query>
        <collection>/data/users/editor</collection>
        <and>
            <field m="1" name="any Field (MODS, TEI, VRA)">numbers</field>
            <field m="2" name="any Field (MODS, TEI, VRA)" short-name="">gentle</field>
        </and>
    </query>
    
return local:generate-full-query($query-as-xml/*[1]/text(), local:generate-query($query-as-xml))
