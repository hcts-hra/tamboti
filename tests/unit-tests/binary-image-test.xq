xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $response := httpclient:get(xs:anyURI("http://kjc-sv002.kjc.uni-heidelberg.de:6081/iiif/kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108310-105231-original.tif/full/!128,128/0/default.jpg"), true(), ())
let $body := $response/httpclient:body/data()
return
(:    $body:)
<img src="data:image/jpeg;charset=utf-8;base64,{$body}"/>
