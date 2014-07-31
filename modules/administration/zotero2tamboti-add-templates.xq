xquery version "3.0";

declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace functx = "http:/www.functx.com";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace ext="http://exist-db.org/mods/extension";
declare namespace xlink="http://www.w3.org/1999/xlink";


declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

declare variable $out-collection := 'xmldb:exist:///db/test/out';


declare function local:add-ns-node(
 $elem as element(),
 $prefix as xs:string,
 $ns-uri as xs:string
) as element() {
   element { node-name($elem) } {
       for $prefix in in-scope-prefixes($elem)
       return
           try {
               namespace { $prefix } { namespace-uri-for-prefix($prefix, $elem) }
           } catch * {
               ()
           },
       namespace { $prefix } { $ns-uri },
       for $attribute in $elem/@*
              return attribute {name($attribute)} {$attribute},
       $elem/node()
   }
};


declare function functx:add-attribute ($element as element(), $name as xs:string, $value as xs:string?) as element() {
element { node-name($element)}
{ attribute {$name} {$value},
$element/@*,
$element/node() }
};

declare function local:insert-element($node as node()?, $new-node as node(), 
    $element-name-to-check as xs:string, $location as xs:string) { 
        if (local-name($node) eq $element-name-to-check)
        then
            if ($location eq 'before')
            then ($new-node, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-node)
                else
                    if ($location eq 'first-child')
                    then element { node-name($node) } { 
                        $node/@*
                        ,
                        $new-node
                        ,
                        for $child in $node/node()
                            return 
                                $child
                    }
                    else
                        if ($location eq 'last-child')
                        then element { node-name($node) } { 
                            $node/@*
                            ,
                            for $child in $node/node()
                                return 
                                    $child 
                            ,
                            $new-node
                        }
                        else () (:The $element-to-check is removed if none of the four options are used.:)
        else
            if ($node instance of element()) 
            then
                element { node-name($node) } { 
                    $node/@*
                    , 
                    for $child in $node/node()
                        return 
                            local:insert-element($child, $new-node, $element-name-to-check, $location) 
             }
         else $node
};

declare function local:remove-elements($nodes as node()*, $remove as xs:anyAtomicType+)  as node()* {
   for $node in $nodes
   return
     if ($node instance of element())
     then 
        if ((local-name($node) = $remove))
        then ()
        else element { node-name($node)}
                { $node/@*,
                  local:remove-elements($node/node(), $remove)}
     else 
        if ($node instance of document-node())
        then local:remove-elements($node/node(), $remove)
        else $node
 } ;


let $input := doc('/db/test/in/modsCollection.xml')
  
for $mods-record in $input/mods:modsCollection/*
    let $myuid := concat("uuid-",util:uuid())
    let $language := $mods-record/mods:language/mods:languageTerm/string()
    let $language := if ($language) then $language else 'eng'
    let $record-content-source := $mods-record/mods:recordInfo/mods:recordContentSource/string()
    let $mods-record := local:remove-elements($mods-record, 'recordInfo')
    let $record-info := 
            <recordInfo lang="eng" script="Latn">
                <recordContentSource authority="marcorg">DE-16-158</recordContentSource>
                <recordContentSource>{$record-content-source}</recordContentSource>
                  <recordCreationDate encoding="w3cdtf">{current-date()}</recordCreationDate>
                  <recordChangeDate encoding="w3cdtf"/>
                  <languageOfCataloging>
                      <languageTerm authority="iso639-2b" type="code">{$language}</languageTerm>
                      <scriptTerm authority="iso15924" type="code">Latn</scriptTerm>
              	</languageOfCataloging>
          	</recordInfo>
    let $mods-record := local:insert-element($mods-record, $record-info, 'mods', 'last-child')
    let $template := 
        if ($mods-record/mods:genre[@authority eq 'local'] eq 'book')
        then 
            <extension xmlns="http://www.loc.gov/mods/v3">
                <ext:template>monograph-latin</ext:template>
                <ext:transliterationOfResource/>
                <ext:catalogingStage/>
            </extension>
        else
            if ($mods-record/mods:genre[@authority eq 'local'] eq 'journalArticle')
            then 
                <extension xmlns="http://www.loc.gov/mods/v3">
                    <ext:template>article-in-periodical-latin</ext:template>
                    <ext:transliterationOfResource/>
                    <ext:catalogingStage/>
                </extension>
            else
                if ($mods-record/mods:genre[@authority eq 'local'] eq 'bookSection')
                then 
                    <extension xmlns="http://www.loc.gov/mods/v3">
                        <ext:template>contribution-to-edited-volume-latin</ext:template>
                        <ext:transliterationOfResource/>
                        <ext:catalogingStage/>
                    </extension>

                else 
                    if ($mods-record/mods:genre[@authority eq 'local'] eq 'conferencePaper')
                    then 
                        <extension xmlns="http://www.loc.gov/mods/v3">
                            <ext:template>contribution-to-edited-volume-latin</ext:template>
                            <ext:transliterationOfResource/>
                            <ext:catalogingStage/>
                        </extension>
                    else
                        <extension xmlns="http://www.loc.gov/mods/v3">
                            <ext:template/>
                            <ext:transliterationOfResource/>
                            <ext:catalogingStage/>
                        </extension>
    let $mods-record := local:insert-element($mods-record, $template, 'mods', 'last-child')
        let $mods-record := functx:add-attribute($mods-record, "ID", $myuid)
    let $mods-record := functx:add-attribute($mods-record, "version", "3.5")
    (:local:add-ns-node() maintains both namespaces and attributes, therefore it must come last. functx:add-attribute() maintains attributes, but not namespaces, so it cannot come last.:)
    let $mods-record := local:add-ns-node($mods-record, "xlink", "http://www.w3.org/1999/xlink")
    let $mods-record := local:add-ns-node($mods-record, "ext", "http://exist-db.org/mods/extension")
    let $mods-record := local:add-ns-node($mods-record, "xsi", "http://www.w3.org/2001/XMLSchema-instance")
    let $mods-record := local:add-ns-node($mods-record, "schemaLocation", "http://www.loc.gov/mods/v3 http://cluster-schemas.uni-hd.de/modsCluster.xsd")

        return
            xmldb:store($out-collection,  concat($myuid, ".xml"), $mods-record)