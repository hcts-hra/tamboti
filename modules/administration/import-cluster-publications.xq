xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:install-cluster-publications-data() as item()* {
    let $http-headers := <headers/>    
    let $cluster-publications-collection-name := "Cluster%20Publications"    
    let $cluster-publications-db-path := $config:mods-commons || $cluster-publications-collection-name || "/"    
    let $decoded-cluster-publications-db-path := translate($cluster-publications-db-path, "%20", " ")    
    let $cluster-publications-url := "http://kjc-sv016.kjc.uni-heidelberg.de:8080/exist/rest" || $cluster-publications-db-path    
    let $resources := httpclient:get(xs:anyURI($cluster-publications-url), false(), $http-headers)/*[2]/*/*
    
    return
        (
            if (xmldb:collection-available($decoded-cluster-publications-db-path)) then (xmldb:remove($decoded-cluster-publications-db-path)) else (),
            xmldb:create-collection($config:mods-commons,  $cluster-publications-collection-name),
            for $resource-description in $resources/*
                let $resource-name := data($resource-description/@name)
                let $resource-contents := httpclient:get(xs:anyURI($cluster-publications-url || $resource-name), false(), $http-headers)/*[2]/*
                
            return xmldb:store($cluster-publications-db-path, $resource-name, $resource-contents)
        )    
};

local:install-cluster-publications-data()