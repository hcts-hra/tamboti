xquery version "3.0";

declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

declare variable $out-collection := 'xmldb:exist:///db/test/out';

(: instead of $element-name-to-check, a path could be used :)
declare function local:insert-element($element as element(), $new-elements as node()*, 
    $element-name-to-check as xs:string, $location as xs:string) { 
        if (local-name($element) eq $element-name-to-check)
        then
            if ($location eq 'before')
            then ($new-elements, $element) 
            else 
                if ($location eq 'after')
                then ($element, $new-elements)
                else
                    if ($location eq 'first-child')
                    then element { node-name($element) } { 
                        $element/@*
                        ,
                        $new-elements
                        ,
                        for $child in $element/node()
                            return 
                                $child
                        }
                    else
                        if ($location eq 'last-child')
                        then element { node-name($element) } { 
                            $element/@*
                            ,
                            for $child in $element/node()
                                return 
                                    $child 
                            ,
                            $new-elements
                            }
                        else () (:The $element-to-check is removed if none of the four options are used.:)
        else
            if ($element instance of element()) 
            then
                element { node-name($element) } { 
                    $element/@*
                    , 
                    for $child in $element/node()
                        return 
                            local:insert-element($child, $new-elements, $element-name-to-check, $location) 
                }
            else $element
};

declare function local:remove-elements($nodes as node()*, $remove as xs:anyAtomicType+)  as node()* {
    for $node in $nodes
    return
        if ($node instance of element())
        then 
            if ((local-name($node) = $remove))
            then ()
            else element { node-name($node)}
                    { $node/@*,
                      local:remove-elements($node/node(), $remove)}
        else 
            if ($node instance of document-node())
            then local:remove-elements($node/node(), $remove)
            else $node
 };

let $input := collection('/db/test/in')

for $mods-record in $input/*
    let $uuid := $mods-record/@ID
    (:names can also occur in relatedItem and subject:)
    let $names := $mods-record/mods:name
    let $mods-record := local:remove-elements($mods-record, 'name')(:NB: This removes names in all places; add check to remove it from specific parents only:)
    let $names :=
    for $name in $names
        let $name :=
            if ($name/@type eq 'personal')
            then
                if (not($name/mods:namePart/@type))
                then 
                    if (matches($name/mods:namePart, ', '))(:Add check to make sure there is only one match:)
                    then 
                        <mods:name type="personal">
                            <mods:namePart type="family">{substring-before($name/mods:namePart, ', ')}</mods:namePart>
                            <mods:namePart type="given">{substring-after($name/mods:namePart, ', ')}</mods:namePart>
                            {$name/(* except mods:namePart)}
                        </mods:name>
                    else $name
                else $name
            else $name
            return $name
        let $mods-record :=  local:insert-element($mods-record, $names, 'mods', 'last-child')
        return
            xmldb:store($out-collection,  concat($uuid, ".xml"), $mods-record)