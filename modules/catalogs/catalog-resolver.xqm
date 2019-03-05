xquery version "3.1";

module namespace catalog-resolver = "http://hra.uni-heidelberg.de/ns/tamboti/catalog-resolver/";

declare namespace catalog = "urn:oasis:names:tc:entity:xmlns:xml:catalog";

declare variable $catalog-resolver:catalog := doc("catalog.xml")/*;

declare function catalog-resolver:resolve-system-id($document-type-identifier) {
    let $location-uri-group := $catalog-resolver:catalog/catalog:group[@id = "location-uri-for-document-types-modules"]
    let $namespace-uri-group := $catalog-resolver:catalog/catalog:group[@id = "namespace-uri-for-document-types-modules"]
    
    return map {
        "namespace-uri": $namespace-uri-group/@xml:base || $namespace-uri-group/catalog:public[@publicId = $document-type-identifier]/@uri,
        "location-uri": $location-uri-group/@xml:base || $location-uri-group/catalog:public[@publicId = $document-type-identifier]/@uri
    }
};