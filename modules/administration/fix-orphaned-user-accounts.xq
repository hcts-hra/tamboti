xquery version "3.0";

declare function local:get-aces($collection-path as xs:anyURI) as element()* {
    (
        try {
            sm:get-permissions($collection-path)/*
        } catch * {
            <error>{"Error at: " || $collection-path}</error>
        },
        for $subcollection in xmldb:get-child-collections($collection-path)
        return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection)),
        for $resource in xmldb:get-child-resources($collection-path)
        let $resource-path := xs:anyURI($collection-path || "/" || $resource)
        return
            try {
                sm:get-permissions($resource-path)/*
            } catch * {
                <error>{"Error at: " || $resource-path}</error>
            }            
            
            
    )
};

let $local-users := sm:get-group-members("biblio.users")

let $orphaned-users := ("a02", "am370", "anna.grasskamp", "anna.vinogradova", "ce372", "chenying.pi", "christiane.brosius", "co402", "daniel.stumm", "eric.decker", "f8h", "fx400", "g05", "ge414", "gf395", "hg7", "hx405", "j0k", "j35", "jens.petersen", "johannes.alisch", "kd416", "kjc_hyperimage", "labuerr5", "lucie.bernroider", "m2b", "m5c", "marnold1", "matthias.arnold", "melissa.butcher", "mw385", "mz404", "nina.nessel", "qd418", "rg399", "roos.gerritsen", "simon.gruening", "swithan3", "ty403", "ud011", "ug400", "v4a", "vk383", "vu067", "wg397", "wmeier", "wu399")

let $aces := <aces>{local:get-aces(xs:anyURI("/resources/users"))}</aces>


return $aces