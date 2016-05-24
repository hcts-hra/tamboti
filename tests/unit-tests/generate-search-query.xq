xquery version "3.0";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "../../modules/search/application.xql";

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

declare function local:generate-full-query($query as xs:string*) as xs:string* {
    "collection('/data')//(" || $query || ")"
};

let $query-as-xml :=
    <query>
        <collection>/data</collection>
        <and>
            <field m="1" name="any Field (MODS, TEI, VRA)">numbers</field>
            <field m="2" name="any Field (MODS, TEI, VRA)" short-name="">gentle</field>
        </and>
    </query>
    
return local:generate-full-query(local:generate-query($query-as-xml))
