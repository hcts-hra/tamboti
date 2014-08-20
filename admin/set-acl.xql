xquery version "3.0";

(:sm:chown(xs:anyURI("/resources/users/eric.decker@ad.uni-heidelberg.de"), "eric.decker@ad.uni-heidelberg.de"):)
let $user-id := "gd079@ad.uni-heidelberg.de"

return 
    (
(:    sm:modify-ace(xs:anyURI("/db/resources/users/matthias.guth@ad.uni-heidelberg.de/rechtegeschichte"), 1, true(), "rwx"):)
    sm:add-user-ace(xs:anyURI("/db/resources/users/matthias.guth@ad.uni-heidelberg.de/rechtegeschichte"), $user-id, true(), "rwx") 
(:        sm:remove-ace(xs:anyURI("/db/resources/users/matthias.guth@ad.uni-heidelberg.de/rechtegeschichte"), 2):)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/baniabidi"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/yamunawalk"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/delhistreetart"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/guptaparisdelhi"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/guptawishyouwerehere"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/hashmirecentwork"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/mydefeat"), $user-id, true(), "rwx"), :)
(:    sm:add-user-ace(xs:anyURI("/resources/users/vma-editor/VMA-Collection/yamunawalk"), $user-id, true(), "rwx") :)
    )
    