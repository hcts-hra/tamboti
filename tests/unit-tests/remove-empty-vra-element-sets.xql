xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";
for $node in collection($config:users-collection || '/vma-editor/VMA-Collection')/vra:vra/vra:*/vra:*
    return
        if ($node[empty(.//*)]) then
(:             update delete $node:)
            $node
        else ()