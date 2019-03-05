xquery version "3.0";

let $node := "&amp;"

let $param := 
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="text"/>
        <output:media-type value="text/plain"/>
        <output:omit-xml-declaration value="yes"/>
    </output:serialization-parameters>

let $parameters :=     
                <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                    <output:method value="json"/>
                    <output:media-type value="application/json"/>
                    <output:prefix-attributes value="yes"/>
                    <output:omit-xml-declaration value="yes"/>
                </output:serialization-parameters>
(:            let $useless := util:log("DEBUG", $self-id-url || " " || $remote-id-url):)

let $header := response:set-header("Content-Type", "application/json")
(:let $header := response:set-header("Content-Type", "text/plain"):)


let $formdata :=
      <http:request method="POST" http-version="1.0">
            <http:body media-type="application/octet-stream">http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/modules/display/image.xql?schema=IIIF&amp;call=/i_87b9668a-e84f-5a41-859e-7ff68af8dbdf</http:body>
      </http:request>
        

let $response := http:send-request($formdata, "http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/modules/display/serialize-as-text.xql")
return
    xmldb:encode(xs:string($response[2]))

(:let $text := http:send-request(<http:request method="POST"/>, ):)
(::)
(:return:)
(:    $node:)
(:(:    xmldb:decode("&amp;"):):)