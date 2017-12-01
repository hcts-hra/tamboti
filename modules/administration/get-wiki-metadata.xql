xquery version "3.1";

declare namespace file = "http://exist-db.org/xquery/file";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace contents = "http://exist.sourceforge.net/NS/exist";

declare function local:date-from-dateTime($date-time) {
    format-dateTime($date-time, "[Y0001]-[M01]-[D01]")
};

declare function local:get-collection-size($directory, $file-list) {
    let $images-directory := $directory || "/VRA_images"
    
    return
        if (file:exists($images-directory))
        then format-number(sum(file:list($images-directory)//file:file[not(ends-with(@name, '.xml'))]/@size ! (xs:integer(.) div 1048576)),"#,##0.00")
        else 0
};

declare function local:get-private-resource-paths() {
    for $contents-file-description in file:directory-list($base-directory || $wiki-path, "**/__contents__.xml")//file:file
    let $contents-file-path := $base-directory || $wiki-path || "/" || $contents-file-description/@subdir || "/__contents__.xml"
    let $contents-file := parse-xml(file:read($contents-file-path))
    let $private-acls := $contents-file//contents:acl[count(contents:ace) = 1 and parent::*/@name != 'feed.atom' and ends-with(parent::*/@name, '.atom')]
    let $private-resource-paths := 
        for $private-acl in $private-acls
        let $parent-element-name := $private-acl/parent::*/local-name()
        
        return
            if ($parent-element-name = 'resource')
            then $private-acl/parent::*/parent::*/@name || "/" || $private-acl/parent::*/@name
            else $private-acl/parent::*/@name
        
    
    return $private-resource-paths
};

declare variable $base-directory := "/home/claudius/tamboti/full20171110-0300";
declare variable $wiki-path := "/db/apps/wiki/data";

let $private-resource-paths := local:get-private-resource-paths()

return
    xmldb:store("/db/resources", "collection-metadata.xml",
        <metadata>
            {(
                "Article name (title),Path,Access rights,Creator&#10;"
                ,
                for $article-description in file:directory-list($base-directory || $wiki-path, "**/*.atom")//file:file[not(@name = ('feed.atom', '_nav.html'))]
                let $subdir := if ($article-description/@subdir) then $article-description/@subdir || "/" else ""
                let $file-path := $base-directory || $wiki-path || "/" || $subdir || $article-description/@name
                let $article := parse-xml(file:read($file-path))
                let $article-path := substring-after($file-path, $base-directory)
                let $rights := if (count(index-of($private-resource-paths, $article-path)) > 0) then "private" else "public"
                
                return string-join(("&#34;" || $article/element()/atom:title || "&#34;", $article-path, $rights, $article/element()/atom:author/atom:name), ',') || "&#10;"
            )}
        </metadata>
    ) 