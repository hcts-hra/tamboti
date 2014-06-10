xquery version "1.0";

(: Adapted from Joe's Punch workshop :)
(:~ Module: tei-to-html.xqm
 :
 :  This module uses XQuery 'typeswitch' expression to transform TEI into HTML.
 :  It performs essentially the same function as XSLT stylesheets, but uses
 :  XQuery to do so.  If your project is already largely XQuery-based, you will 
 :  find it very easy to change and maintain this code, since it is pure XQuery.
 :
 :  This design pattern uses one function per TEI element (see
 :  the tei-common:dispatch() function starting on ~ line 47).  So if you 
 :  want to adjust how the module handles TEI div elements, for example, go to 
 :  tei-common:div().  If you need the module to handle a new element, just add 
 :  a function.  The length of the module may be daunting, but it is quite clearly
 :  structured.  
 :
 :  To use this module from other XQuery files, include the module 
 :     import module namespace render = "http://history.state.gov/ns/tei-to-html" at "../modules/tei-to-html.xqm";
 :  and pass the TEI fragment to tei-common:render() as
 :     tei-common:render($teiFragment, $options)
 :  where $options contains parameters and other info you might want your 
 :  tei-to-html functions to make use of in a parameters element:
 :     <parameters xmlns="">
 :         <param name="relative-image-path" value="/rest/db/punch/data/images/"/>
 :     </parameters>
 :)

module namespace tei-common = "http://exist-db.org/tei/common";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: A helper function in case no options are passed to the function :)
declare function tei-common:render($content as node()*) as element() {
    tei-common:render($content, $destination)
};

(: The main function for the tei-to-html module: Takes TEI content, turns it into HTML, and wraps the result in a div element :)
declare function tei-common:render($content as node()*, $options as element(parameters)*) as element() {
    <div class="document">
        { tei-common:dispatch($content, $options) }
    </div>
};

(: Typeswitch routine: Takes any node in a TEI content and either dispatches it to a dedicated 
 : function that handles that content (e.g. div), ignores it by passing it to the recurse() function
 : (e.g. text), or handles it directly (e.g. lb). :)
declare function tei-common:dispatch($node as node()*, $options) as item()* {
    typeswitch($node)
        case text() return $node
        case element(tei:TEI) return tei-common:recurse($node, $options)
        case element(tei:text) return tei-common:recurse($node, $options)
        case element(tei:front) return tei-common:recurse($node, $options)
        case element(tei:body) return tei-common:recurse($node, $options)
        case element(tei:back) return tei-common:recurse($node, $options)
        case element(tei:div) return tei-common:div($node, $options)
        case element(tei:head) return tei-common:head($node, $options)
        case element(tei:p) return tei-common:p($node, $options)
        case element(tei:hi) return tei-common:hi($node, $options)
        case element(tei:list) return tei-common:list($node, $options)
        case element(tei:item) return tei-common:item($node, $options)
        case element(tei:label) return tei-common:label($node, $options)
        case element(tei:ref) return tei-common:ref($node, $options)
        case element(tei:said) return tei-common:said($node, $options)
        case element(tei:lb) return <br/>
        case element(tei:figure) return tei-common:figure($node, $options)
        case element(tei:graphic) return tei-common:graphic($node, $options)
        case element(tei:table) return tei-common:table($node, $options)
        case element(tei:row) return tei-common:row($node, $options)
        case element(tei:cell) return tei-common:cell($node, $options)
        case element(tei:pb) return tei-common:pb($node, $options)
        case element(tei:lg) return tei-common:lg($node, $options)
        case element(tei:l) return tei-common:l($node, $options)
        case element(tei:name) return tei-common:name($node, $options)
        case element(persName) return tei-common:name($node, $options) (:where is the namespace:)
        case element(tei:milestone) return tei-common:milestone($node, $options)
        case element(tei:quote) return tei-common:quote($node, $options)
        case element(tei:said) return tei-common:said($node, $options)
        default return tei-common:recurse($node, $options)
};

(: Recurses through the child nodes and sends them tei-common:dispatch() :)
declare function tei-common:recurse($node as node()?, $options) as item()* {
    for $node in $node/node()
    return 
        tei-common:dispatch($node, $options)
};

declare function tei-common:div($node as element(tei:div), $options) {
    if ($node/@xml:id) 
    then tei-common:xmlid($node, $options) 
    else ()
    ,
    tei-common:recurse($node, $options)
};

(:NB: why can this not return element()?:)
declare function tei-common:head($node as element(tei:head), $options) as item() {
    (: div heads :)
    if ($node/parent::tei:div) then
        let $type := $node/parent::tei:div/@type/string()
        let $div-level := count($node/ancestor::div)
        return
        (:Do not augment header level:)
            element {concat('h', $div-level (:+ 2:))} {tei-common:recurse($node, $options)}
    (: figure heads :)
    else if ($node/parent::tei:figure) then
        if ($node/parent::tei:figure/parent::tei:p) then
            <strong>{tei-common:recurse($node, $options)}</strong>
        else (: if ($node/parent::tei:figure/parent::tei:div) then :)
            <p><strong>{tei-common:recurse($node, $options)}</strong></p>
    (: list heads :)
    else if ($node/parent::tei:list) then
        <li>{tei-common:recurse($node, $options)}</li>
    (: table heads :)
    else if ($node/parent::tei:table) then
        <p class="center">{tei-common:recurse($node, $options)}</p>
    (: other heads? :)
    else
        tei-common:recurse($node, $options)
};

declare function tei-common:p($node as element(tei:p), $options) as element() {
    let $rend := $node/@rend/string()
    return 
        if ($rend = ('right', 'center') ) 
        then
            <p>{ attribute class {data($rend)} }{ tei-common:recurse($node, $options) }</p>
        else 
            <p>{tei-common:recurse($node, $options)}</p>
};

declare function tei-common:hi($node as element(tei:hi), $options) as element()* {
    let $rend := $node/@rend/string()
    return
        if ($rend = ('it', 'italic')) then
            <em>{tei-common:recurse($node, $options)}</em>
        else if ($rend = 'bold') then
            <strong>{tei-common:recurse($node, $options)}</strong>
        else if ($rend = 'sc') then
            <span style="font-variant: small-caps;">{tei-common:recurse($node, $options)}</span>
        else 
            <span>{tei-common:recurse($node, $options)}</span>
};

declare function tei-common:list($node as element(tei:list), $options) as element() {
    <ul>{tei-common:recurse($node, $options)}</ul>
};

declare function tei-common:item($node as element(tei:item), $options) as element()+ {
    if ($node/@xml:id) 
    then tei-common:xmlid($node, $options) 
    else ()
    ,
    <li>{tei-common:recurse($node, $options)}</li>
};

declare function tei-common:label($node as element(tei:label), $options) as element() {
    if ($node/parent::tei:list) then 
        (
        <dt>{$node/text()}</dt>,
        <dd>{$node/following-sibling::tei:item[1]}</dd>
        )
    else tei-common:recurse($node, $options)
};

declare function tei-common:xmlid($node as element(), $options) as element() {
    <a name="{$node/@xml:id/string()}"/>
};

declare function tei-common:ref($node as element(tei:ref), $options) {
    let $target := $node/@target/string()
    return
        element a { 
            attribute href {$target},
            attribute title {$target},
            $target,
            tei-common:recurse($node, $options) 
            }
};

declare function tei-common:said($node as element(tei:said), $options) as element() {
    <p class="said">{tei-common:recurse($node, $options)}</p>
};

declare function tei-common:figure($node as element(tei:figure), $options) {
    <div class="figure">{tei-common:recurse($node, $options)}</div>
};

declare function tei-common:graphic($node as element(tei:graphic), $options) {
    let $url := $node/@url/string()
    let $head := $node/following-sibling::tei:head
    let $width := if ($node/@width) then $node/@width/string() else '800px'
    let $relative-image-path := $options/*:param[@name='relative-image-path']/@value/string()
    return
        <img src="{if (starts-with($url, '/')) then $url else concat($relative-image-path, $url)}" alt="{normalize-space($head[1])}" width="{$width}"/>
};

declare function tei-common:table($node as element(tei:table), $options) as element() {
    <table>{tei-common:recurse($node, $options)}</table>
};

declare function tei-common:row($node as element(tei:row), $options) as element() {
    let $label := $node/@role[. = 'label']/string()
    return
        <tr>{if ($label) then attribute class {'label'} else ()}{tei-common:recurse($node, $options)}</tr>
};

declare function tei-common:cell($node as element(tei:cell), $options) as element() {
    let $label := $node/@role[. = 'label']/string()
    return
        <td>{if ($label) then attribute class {'label'} else ()}{tei-common:recurse($node, $options)}</td>
};

declare function tei-common:pb($node as element(tei:pb), $options) {
    if ($node/@xml:id) 
    then tei-common:xmlid($node, $options) 
    else ()
    ,
    if ($options/*:param[@name='show-page-breaks']/@value = 'true') 
    then
        <span class="pagenumber">{
            concat('Page ', $node/@n/string())
        }</span>
    else ()
};

declare function tei-common:lg($node as element(tei:lg), $options) {
    <div class="lg">{tei-common:recurse($node, $options)}</div>
};

declare function tei-common:l($node as element(tei:l), $options) {
    let $rend := $node/@rend/string()
    return
        if ($node/@rend eq 'i2') then 
            <div class="l" style="padding-left: 2em;">{tei-common:recurse($node, $options)}</div>
        else 
            <div class="l">{tei-common:recurse($node, $options)}</div>
};

declare function tei-common:name($node as element(tei:name), $options) {
    let $rend := $node/@rend/string()
    let $key := $node/@key/string()
    return
        if ($options/destination eq 'detail-view' and $key) 
        then
            if ($rend eq 'sc') 
            then 
                <a href="{$key}" target="_blank"><span class="name" style="font-variant: small-caps;">{tei-common:recurse($node, $options)}</span></a>
            else
                <a href="{$key}" target="_blank"><span class="name">{tei-common:recurse($node, $options)}</span></a>
        else
        (:Do not generate links on hitlist, since each <td> there is a link:)
            if ($rend eq 'sc') 
            then 
                <span class="name" style="font-variant: small-caps;">{tei-common:recurse($node, $options)}</span>
            else 
                <span class="name">{tei-common:recurse($node, $options)}</span>
};

declare function tei-common:milestone($node as element(tei:milestone), $options) {
    if ($node/@unit/string() eq 'rule') 
    then
        if ($node/@rend/string() eq 'stars') 
        then 
            <div style="text-align: center">* * *</div>
        else 
            if ($node/@rend/string() eq 'hr') 
            then
                <hr style="margin: 7px;"/>
            else
                <hr/>
    else 
        <hr/>
};

declare function tei-common:quote($node as element(tei:quote), $options) {
    <blockquote>{tei-common:recurse($node, $options)}</blockquote>
};

declare function tei-common:said($node as element(tei:said), $options) {
    <span class="said">{tei-common:recurse($node, $options)}</span>
};