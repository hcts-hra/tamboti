xquery version "3.0";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";
for $node in collection('/resources/users/vma-editor/VMA-Collection')/vra:vra/vra:*/vra:*
    return
        if ($node[empty(.//*)]) then
(:             update delete $node:)
            $node
        else ()