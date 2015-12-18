xquery version "3.0";

module namespace iiif-functions="http://hra.uni-heidelberg.de/ns/iiif-functions";
import module namespace functx="http://www.functx.com";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace json="http://www.json.org";

declare variable $iiif-functions:ERROR := xs:QName("iiif-functions:error");
declare variable $iiif-functions:valid-formats := map{
                                                    "jpg" := "image/jpeg",
                                                    "tif" := "image/tiff",
                                                    "png" := "image/png",
                                                    "gif" := "image/gif",
                                                    "jp2" := "image/jp2",
                                                    "pdf" := "application/pdf",
                                                    "webp" := "image/webp"
                                                };

declare variable $iiif-functions:valid-qualities := ("color", "gray", "bitonal", "default");

(: the IIIF scheme looks like this: 
 :
 : {scheme}://{server}{/prefix}/{identifier}/{region}/{size}/{rotation}/{quality}.{format}
 : size:   /full/!225,100/0/default.jpg
 : region: /10,20,150,150/full/0/default.jpg
 : 
 : {http}://{localhost:8080}/{exist/apps/tamboti/modules/display/image.xql?schema=IIIF&call=} :)

declare function iiif-functions:parse-iiif-call($call as xs:string) {
    (: seperate the parameters :)
    let $parameters := tokenize($call, "/")

    return
        if ($parameters[last()] = "info.json") then
            <iiif-info>
                <prefix>
                    {
                        let $id-components := 
                            for $p in $parameters[position() lt (count($parameters) - 1)]
                                return
                                    if($p) then
                                        $p
                                    else
                                        ()
                        return 
                            "/" || string-join($id-components, "/")
                    }
                </prefix>
                <identifier>
                    {
                        $parameters[position() = count($parameters) - 1]
                    }
                </identifier>
            </iiif-info>
        (: if not at least 5 parameters the call is invalid :)
        else if (count($parameters) lt 5) then
            error($iiif-functions:ERROR, "iiif parsing error", "not a valid iiif call")
        else
            <iiif-parameters>
                {
                    (: get the identifier :)
                    <prefix>
                        {
                            let $id-components := 
                                for $p at $idx in $parameters[position() lt (count($parameters) - 4)]
                                    return
                                        if($p) then
                                            $p
                                        else
                                            ()
                            return 
                                "/" || string-join($id-components, "/")
                        }
                    </prefix>
                    ,
                    <identifier>
                        {
                            $parameters[position() = (count($parameters) - 4)]
                        }
                    </identifier>
                    ,
                    <image-request-parameters>
                        <full>
                        {
                            let $params := 
                                for $p in $parameters[position() gt (count($parameters) - 4)]
                                return $p
                                
                            return
                                string-join($params, "/")
                        }
                        </full>
                    {
                        for $p at $idx in $parameters[position() gt (count($parameters) - 4)]
                        return
                            switch($idx)
                                case 1 return
                                    (:parse region definition :)
                                    let $region-parameters := iiif-functions:parse-region-parameter($p)
                                    return
                                        <region>
                                            <full>{$region-parameters("full")}</full>
                                            <pct>{$region-parameters("pct")}</pct>
                                            <x>{$region-parameters("x")}</x>
                                            <y>{$region-parameters("y")}</y>
                                            <h>{$region-parameters("h")}</h>
                                            <w>{$region-parameters("w")}</w>
                                        </region>
                                case 2 return
                                    (:parse size definition :)
                                    let $size-parameters := iiif-functions:parse-size-parameter($p)
                                    return
                                        <size>
                                            <full>{$size-parameters("full")}</full>
                                            <pct>{$size-parameters("pct")}</pct>
                                            <pct-value>{$size-parameters("pct-value")}</pct-value>
                                            <aspect>{$size-parameters("aspect")}</aspect>
                                            <x>{$size-parameters("x")}</x>
                                            <y>{$size-parameters("y")}</y>
                                        </size>
                                case 3 return
                                    (:parse rotation definition :)
                                    let $rotation-parameters := iiif-functions:parse-rotation-parameter($p)
                                    return
                                        <rotation>
                                            <mirror>{$rotation-parameters("mirror")}</mirror>
                                            <degrees>{$rotation-parameters("degrees")}</degrees>
                                        </rotation>
                                case 4 return
                                    (: parse quality and format:)
                                    let $quality-format := tokenize($p, "\.")
                                    let $quality-parameter := iiif-functions:parse-quality-parameter($quality-format[1])
                                    let $format := iiif-functions:parse-format-parameter($quality-format[2])
                                    let $format-mime :=
                                        if ($format) then
                                            $iiif-functions:valid-formats($format)
                                        else
                                            ()
                                    return
                                        (
                                            <quality>{$quality-parameter}</quality>
                                            ,
                                            <format>{$format}</format>
                                            , 
                                            <format-mime>{$format-mime}</format-mime>
                                        )
                                default return 
                                    <other>
                                        <parameter-idx>{$idx}</parameter-idx>
                                        <parameter>{$p}</parameter>
                                    </other>
                    }
                    </image-request-parameters>

                }
            </iiif-parameters>
};

declare function iiif-functions:parse-region-parameter($region-string as xs:string) {
    let $pct := (substring($region-string, 1, 4) = "pct:")
    let $region-string := 
        if ($pct) then 
            substring($region-string, 5)
        else
            $region-string
    
    let $region := tokenize($region-string, ",")

    (: 4 parameters are needed :)
    return 
        if ($region = "full") then
            map{
                "full" := "full"
            }
        else if (count($region) = 4) then
            map{
                "pct" := $pct,
                "x" := $region[1],
                "y" := $region[2],
                "w" := $region[3],
                "h" := $region[4]
            }
        else
            ()
};

declare function iiif-functions:parse-size-parameter($size-string as xs:string) {
    let $aspect := (substring($size-string, 1, 1) = "!")
    let $size-string := 
        if ($aspect) then
            substring($size-string, 2)
        else
            $size-string

    let $pct := (substring($size-string, 1, 4) = "pct:")
    let $size-string := 
        if ($pct) then 
            substring($size-string, 5)
        else
            $size-string
    
    let $size := tokenize($size-string, ",")

    return 
        if ($size = "full") then
            map{
                "full" := "full"
            }
        (: 1 parameter if needed if percentage :)
        else if($pct and count($size) = 1) then
            map{
                "pct" := $pct,
                "pct-value" := $size
            }
        (: 2 parameters are needed if no percentage :)
        else if (count($size) = 2) then
            map{
                "aspect" := $aspect,
                "x" := $size[1],
                "y" := $size[2]
            }
        else
            ()
};

declare function iiif-functions:parse-rotation-parameter($rotation-string as xs:string) {
    let $mirror := (substring($rotation-string, 1, 1) = "!")
    let $rotation-string := 
        if ($mirror) then 
            substring($rotation-string, 2)
        else
            $rotation-string
    
    return
        map{
            "mirror" := $mirror,
            "degrees" := $rotation-string
        }
};

declare function iiif-functions:parse-quality-parameter($quality-string as xs:string) {
    if ($quality-string = $iiif-functions:valid-qualities) then
        $quality-string
    else 
        ()
};

declare function iiif-functions:parse-format-parameter($format-string as xs:string) {
    if ($format-string = map:keys($iiif-functions:valid-formats)) then
        $format-string
    else 
        ()
};

declare function iiif-functions:info($binary as xs:base64Binary, $iiif-parameters as node()) {
    let $uuid := $iiif-parameters//identifier/string()
    let $id-uri := functx:substring-before-last(request:get-url(), "/")
    
    let $width := image:get-width($binary)
    let $height := image:get-height($binary)

    let $data :=
        <data context="http://iiif.io/api/image/2/context.json" id="{$id-uri}">
            <protocol>http://iiif.io/api/image</protocol>
            <width json:literal="true">{$width}</width>
            <height json:literal="true">{$height}</height>
            <sizes>
                <width json:literal="true">150</width>
                <height json:literal="true">150</height>
            </sizes>
            <sizes>
                <width json:literal="true">600</width>
                <height json:literal="true">600</height>
            </sizes>
            <sizes>
                <width json:literal="true">1200</width>
                <height json:literal="true">1200</height>
            </sizes>
            <tiles json:array="true">
                <width json:literal="true">512</width>
                <height json:literal="true">512</height>
                <scaleFactors json:literal="true">1</scaleFactors>
                <scaleFactors json:literal="true">2</scaleFactors>
                <scaleFactors json:literal="true">4</scaleFactors>
                <scaleFactors json:literal="true">8</scaleFactors>
            </tiles>
            <profile>
                <formats json:array="true">jpg</formats>
                <qualities json:array="true">native</qualities>
                <supports>sizeByWh</supports>
                <supports>sizeByH</supports>
                <supports>sizeByW</supports>
                <supports>sizeAboveFull</supports>
                <supports>rotationBy90s</supports>
            </profile>
        </data>
    return
        $data

};