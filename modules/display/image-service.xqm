xquery version "3.0";

module namespace image-service="http://hra.uni-heidelberg.de/ns/tamboti/image-service";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace vra-ns = "http://www.vraweb.org/vracore4.htm";

declare function image-service:get-image-vra($uuid) {
    let $col := collection($config:mods-root)
    let $imageVRA := $col//vra-ns:vra/vra-ns:image[@id=$uuid]
    return 
        if(count($imageVRA) > 0) then
            $imageVRA
        else
            false()
};
