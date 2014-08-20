xquery version "3.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace functx = "http:/www.functx.com";
declare namespace mods="http://www.loc.gov/mods/v3";


declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=yes indent=yes";

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

declare variable $out-collection := 'xmldb:exist:///db/test/out';


declare function local:add-ns-node(
    $elem   as element(),
    $prefix as xs:string,
    $ns-uri as xs:string
  ) as element()
{
  element { QName($ns-uri, concat($prefix, ":x")) }{ $elem }/*
};


declare function functx:add-attribute ($element as element(), $name as xs:string, $value as xs:string?) as element() {
element { node-name($element)}
{ attribute {$name} {$value},
$element/@*,
$element/node() }
};


  let $input := doc('/db/test/in/jsit-mods.xml')
  
  for $mods-record in $input/mods:modsCollection/*
    let $myuid := concat("uuid-",util:uuid())
    let $mods-record := functx:add-attribute($mods-record, "ID", $myuid)
    let $mods-record := functx:add-attribute($mods-record, "version", "3.4")
    let $mods-record := local:add-ns-node($mods-record, "xlink", "http://www.w3.org/1999/xlink")
    let $mods-record := local:add-ns-node($mods-record, "ext", "http://exist-db.org/mods/extension")
    let $mods-record := local:add-ns-node($mods-record, "xsi", "http://www.w3.org/2001/XMLSchema-instance")
    let $mods-record := local:add-ns-node($mods-record, "schemaLocation", "http://www.loc.gov/mods/v3 http://cluster-schemas.uni-hd.de/modsCluster.xsd")
    
    return
    
        xmldb:store($out-collection,  concat($myuid, ".xml"), $mods-record)