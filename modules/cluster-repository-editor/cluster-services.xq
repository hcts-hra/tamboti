xquery version "3.0";

import module "http://xqilla.sourceforge.net/lib/xqjson";

let $cluster-services-url := "http://kjc-sv013.kjc.uni-heidelberg.de:38080/exist/apps/cluster-services/modules/services/search/suggest.xq?"

let $get-result := xqjson:parse-json(util:binary-to-string(httpclient:delete(xs:anyURI($cluster-services-url || request:get-query-string()), false(), <headers />)/*[2]/text()))

let $local-name-of-first-item := local-name($get-result/*[2]/*[1])

return
        if ($local-name-of-first-item = 'pair')
        then (<pair><item>{$get-result/*[2]/*}</item></pair>)
        else ($get-result/*[2])