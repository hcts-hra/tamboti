xquery version "3.0";

module namespace image-service="http://hra.uni-heidelberg.de/ns/tamboti/image-service";

declare namespace vra-ns = "http://www.vraweb.org/vracore4.htm";
declare variable $image-service:root-collection := "/db/resources/";

declare function image-service:get-image-vra($uuid) {
    let $col := collection($image-service:root-collection)
    let $imageVRA := $col//vra-ns:vra/vra-ns:image[@id=$uuid]
        return $imageVRA
};

