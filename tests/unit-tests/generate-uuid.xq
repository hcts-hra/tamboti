xquery version "3.0";

let $api-url := xs:anyURI("http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/api/uuid")
let $resources := httpclient:get($api-url, false(), ())


return util:binary-to-string($resources/*[2])
