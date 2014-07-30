xquery version "3.0";

(: This functions reorders VRA elements in the required order. :)

declare namespace in-mem-ops = "http://exist-db.org/apps/mopane/in-mem-ops";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $out-collection := 'xmldb:exist:///db/test/out';

declare function in-mem-ops:change-elements(
    $node as node(), 
    $new-content as item()*, 
    $action as xs:string, 
    $target-element-names as xs:string+
) as node()* 
{
        if ($node instance of element() and local-name($node) = $target-element-names)
        then

            if ($action eq 'insert-before')
            then ($new-content, $node) 
            else
            
            if ($action eq 'insert-after')
            then ($node, $new-content)
            else
            
            if ($action eq 'insert-as-first-child')
            then element {node-name($node)}
                {
                $node/@*
                ,
                $new-content
                ,
                for $child in $node/node()
                return $child
                }
            else
            
            if ($action eq 'insert-as-last-child')
            then element {node-name($node)}
                {
                $node/@*
                ,
                for $child in $node/node()
                return $child 
                ,
                $new-content
                }
            else
                
            if ($action eq 'substitute')
            then $new-content
            else 
                
            if ($action eq 'remove')
            then ()
            else 
                
            if ($action eq 'remove-if-empty')
            then
                if (normalize-space($node) eq '')
                then ()
                else $node
            else

            if ($action eq 'substitute-children-for-parent')
            then $node/*
            else
            
            if ($action eq 'substitute-content')
            then
                element {name($node)}
                    {$node/@*,
                $new-content}
            else
                
            if ($action eq 'change-name')
            then
                element {$new-content[1]}
                    {$node/@*,
                for $child in $node/node()
                return $child}
            else ()
        
        else
        
            if ($node instance of element()) 
            then
                element {node-name($node)} 
                {
                    $node/@*
                    ,
                    for $child in $node/node()
                    return 
                            in-mem-ops:change-elements($child, $new-content, $action, $target-element-names) 
                }
            else $node
};


let $in-collection := collection('/db/test/in')

return
    for $doc in $in-collection/*
    let $wrapper := in-mem-ops:change-elements($doc, (), 'remove', ('agentSet', 'culturalContextSet', 'dateSet', 'descriptionSet', 'inscriptionSet', 'locationSet', 'materialSet', 'measurementsSet', 'relationSet', 'rightsSet', 'sourceSet', 'stateEditionSet', 'stylePeriodSet', 'subjectSet', 'techniqueSet', 'textrefSet', 'titleSet', 'worktypeSet'))
    let $contents :=
    (
    $doc//vra:agentSet,
    $doc//vra:culturalContextSet,
    $doc//vra:dateSet,
    $doc//vra:descriptionSet,
    $doc//vra:inscriptionSet,
    $doc//vra:locationSet,
    $doc//vra:materialSet,
    $doc//vra:measurementsSet,
    $doc//vra:relationSet,
    $doc//vra:rightsSet,
    $doc//vra:sourceSet,
    $doc//vra:stateEditionSet,
    $doc//vra:stylePeriodSet,
    $doc//vra:subjectSet,
    $doc//vra:techniqueSet,
    $doc//vra:textrefSet,
    $doc//vra:titleSet,
    $doc//vra:worktypeSet
    )

let $vra-uuid := $doc/vra:image/@id/string()
let $doc := in-mem-ops:change-elements($wrapper, $contents, 'insert-as-first-child', ('work', 'image'))
    return xmldb:store($out-collection, concat($vra-uuid, ".xml"), $doc)