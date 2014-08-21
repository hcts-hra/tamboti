xquery version "1.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace theme="http://exist-db.org/xquery/biblio/theme" at "../modules/theme.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../modules/config.xqm";

let $uri := request:get-uri()
let $context := request:get-context-path()
let $path := substring-after($uri, $context)
let $name := replace($uri, '^.*/([^/]+)$', '$1')
return
    if ($exist:path eq '') 
    then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{concat(request:get-uri(), '/')}"/>
        </dispatch>
    else 
        if ($exist:path eq '/') 
        then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            	<redirect url="../docs/index.xml"/>
            </dispatch>
        else 
            if (ends-with($uri, '.xml')) 
            then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            	<view>
            		<forward servlet="XSLTServlet">
            			<set-attribute name="xslt.stylesheet" 
            				value="{$exist:root}/{$exist:controller}/stylesheets/db2xhtml.xsl"/>
            		    <set-attribute name="xslt.output.media-type"
                            value="text/html"/>
                        <set-attribute name="xslt.output.doctype-public"
                            value="-//W3C//DTD XHTML 1.0 Transitional//EN"/>
                        <set-attribute name="xslt.output.doctype-system"
                            value="resources/xhtml1-transitional.dtd"/>
            		</forward>
            	</view>
                <cache-control cache="no"/>
            </dispatch>
            else 
                if (starts-with($exist:path, "/theme")) 
                then
                    let $path := theme:resolve($exist:prefix, $exist:root, substring-after($exist:path, "/theme"))
                    let $themePath := replace($path, "^(.*)/[^/]+$", "$1")
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$path}">
                                <set-attribute name="theme-collection" value="{$themePath}"/>
                            </forward>
                        </dispatch>
                else
                    <ignore xmlns="http://exist.sourceforge.net/NS/exist">
                        <cache-control cache="yes"/>
                    </ignore>
