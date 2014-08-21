xquery version "3.0";

module namespace biblio="http://exist-db.org/xquery/biblio";

(:~
    The core XQuery script for the bibliographic demo. It receives a template XML document
    from the controller and expands it. If a search was triggered by the user, the script
    proceeds as follows:
    
    <ul>
        <li>the input form parameters are transformed into a simple XML structure
            to describe the query</li>
        <li>an XPath string is generated from the XML query structure</li>
        <li>the XPath is executed and the sort criteria applied</li>
        <li>query results, XML query and sort criteria are stored into the HTTP session</li>
        <li>the template is expanded, forms are regenerated to match the query</li>
    </ul>
    
    To apply a filter to an existing query, we just extend the XML representation
    of the query.
:)

declare namespace request="http://exist-db.org/xquery/request";
declare namespace session="http://exist-db.org/xquery/session";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace functx="http://www.functx.com";
declare namespace xlink="http://www.w3.org/1999/xlink";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace theme="http://exist-db.org/xquery/biblio/theme" at "../theme.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "../templates.xql";
import module namespace jquery="http://exist-db.org/xquery/jquery" at "resource:org/exist/xquery/lib/jquery.xql";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";

declare option exist:serialize "method=xhtml media-type=application/xhtml+xml omit-xml-declaration=no enforce-xhtml=yes";

declare function functx:number-of-matches 
  ( $arg as xs:string? ,
    $pattern as xs:string )  as xs:integer {
       
   count(tokenize($arg,$pattern)) - 1
 } ;

declare function functx:substring-before-if-contains($arg as xs:string?, $delim as xs:string)  as xs:string? {       
   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;
 
declare function functx:replace-first($arg as xs:string?, $pattern as xs:string, $replacement as xs:string ) as xs:string {       
   replace($arg, concat('(^.*?)', $pattern),
             concat('$1',$replacement))
};

(:~
    Mapping field names to XPath expressions.
    NB: Changes in field names should be reflected in autocomplete.xql, biblio:construct-order-by-expression() and biblio:get-year().
    Fields used should be reflected in the collection.xconf in /db/system/config/db/resources/.
    'q' is expanded in biblio:generate-query().
    An XLink may be passed through retrieve-mods:format-detail-view() without a hash or or it may be passed with a hash through the search interface; 
    therefore any leading hash is first removed and then added, to prevent double hashes. 
:)
declare variable $biblio:FIELDS :=
<fields>
    <field name="any Field (MODS, TEI, VRA, Wiki)" short-name="All">
        <search-expression>
            (
            mods:mods[ft:query(., '$q', $options)]
            union
            vra:vra[ft:query(., '$q', $options)]
            union
            tei:TEI[ft:query(., '$q', $options)]
            union
            atom:entry[ft:query(., '$q', $options)]
            union
            ft:search('page:$q')
            union
            mods:mods[@ID eq '$q']
            union
            mods:mods[mods:relatedItem/@xlink:href eq '$q']
            union
            atom:entry[atom:id eq '$q']
            )
        </search-expression>
        <targets>
            <target>mods:mods</target>
            <target>vra:vra</target>
            <target>tei:TEI</target>
            <target>atom:entry</target>
        </targets>
    </field>
    <field name="the Date Field (MODS)" short-name="Date">
        <search-expression>
            (
            mods:mods[ft:query(.//mods:dateCreated, '$q*', $options)]
            union
            mods:mods[ft:query(.//mods:dateIssued, '$q*', $options)]
            union
            mods:mods[ft:query(.//mods:dateCaptured, '$q*', $options)]
            union
            mods:mods[ft:query(.//mods:copyrightDate, '$q*', $options)]
            union
            mods:mods[ft:query(.//mods:date, '$q*', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:dateCreated</target>
            <target>mods:dateIssued</target>
            <target>mods:dateCaptured</target>
            <target>mods:copyrightDate</target>
            <target>mods:date</target>
        </targets>
    </field>
    <field name="the Description/Abstract Field (MODS, VRA)" short-name="Description">
        <search-expression>
            (
            mods:mods[ft:query(mods:abstract, '$q', $options)]
            union
            vra:vra[ft:query(.//vra:descriptionSet, '$q', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:abstract</target>
            <target>vra:descriptionSet</target>
        </targets>
    </field>
    <field name="the Extracted Text Field (PDF)">
        <search-expression>
            ft:search('page:$q')
        </search-expression>
        <targets/>
    </field>
    <field name="the Genre Field (MODS)" short-name="Genre">
        <search-expression>
            mods:mods[ft:query(.//mods:genre, '$q', $options)]
        </search-expression>
        <targets>
            <target>mods:genre</target>
        </targets>
    </field>
    <field name="the Name Field (MODS, TEI, VRA)" short-name="Name">
        <search-expression>
            (
            mods:mods[ft:query(.//mods:name, '$q', $options)]
            union
            vra:vra[ft:query(.//vra:agentSet, '$q', $options)]
            union
            tei:TEI//tei:p[ft:query(tei:name, '$q', $options)]
            union
            tei:TEI//tei:bibl[ft:query(.//tei:name, '$q', $options)]
            union
            tei:TEI//tei:person[ft:query(.//tei:persName, '$q', $options)]
            union
            atom:entry[ft:query(.//atom:name, '$q', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:name</target>
            <target>vra:agentSet</target>
            <target>tei:name</target>
            <target>tei:persName</target>
            <target>atom:name</target>
        </targets>
    </field>
    <field name="the Language Codes Field (MODS)" short-name="Language">
        <search-expression>
            mods:mods[ft:query(.//mods:language, '$q', $options)]
        </search-expression>
        <targets>
            <target>mods:language</target>
        </targets>
    </field>
    <field name="the Note Field (MODS)" short-name="Note">
        <search-expression>
            mods:mods[ft:query(mods:note, '$q', $options)]
        </search-expression>
        <targets>
            <target>mods:note</target>
        </targets>
    </field>
    <field name="the Origin Field (MODS)" short-name="Origin">
        <search-expression>
            (
            mods:mods[ft:query(.//mods:placeTerm , '$q*', $options)]
            union
            mods:mods[ft:query(.//mods:publisher , '$q*', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:placeTerm</target>
            <target>mods:publisher</target>
        </targets>
    </field>
    <field name="the Record ID Field (MODS, VRA, Wiki)" short-name="ID">
        <search-expression>
            (
            mods:mods[@ID eq '$q']
            union
            vra:vra[vra:collection/@id eq '$q']
            union
            vra:vra[vra:work/@id eq '$q']
            union
            vra:vra[vra:image/@id eq '$q']
            union
            atom:entry[atom:id eq '$q']
            )
        </search-expression>
        <targets/>
    </field>
    <field name="the Resource Identifier Field (MODS)" short-name="Identifier">
        <search-expression>
            mods:mods[mods:identifier = '$q']
        </search-expression>
        <targets>
            <target>mods:identifier</target>
        </targets>
    </field>
    <field name="the Subject/Term Field (MODS, TEI, VRA)" short-name="Subject">
        <search-expression>
            (
            mods:mods[ft:query(mods:subject, '$q', $options)]
            union
            vra:vra[ft:query(.//vra:subjectSet, '$q', $options)]
            union
            tei:TEI//tei:p[ft:query(.//tei:term, '$q', $options)]
            union
            tei:TEI//tei:head[ft:query(.//tei:term, '$q', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:subject</target>
            <target>vra:subjectSet</target>
            <target>tei:term</target>
        </targets>
    </field>
    <field name="the Title Field (MODS, TEI, VRA, Wiki)" short-name="Title">
        <search-expression>
            (
            mods:mods[ft:query(.//mods:titleInfo, '$q', $options)]
            union
            vra:vra[ft:query(.//vra:titleSet, '$q', $options)]
            union
            tei:TEI//tei:p[ft:query(tei:title, '$q', $options)]
            union
            tei:TEI//tei:bibl[ft:query(.//tei:title, '$q', $options)]
            union
            tei:TEI//tei:titleStmt[ft:query(./tei:title, '$q', $options)]
            union
            atom:entry[ft:query(.//atom:title, '$q', $options)]
            )
        </search-expression>
        <targets>
            <target>mods:titleInfo</target>
            <target>vra:titleSet</target>
            <target>tei:title</target>
            <target>atom:title</target>
        </targets>
    </field>
    <field name="the XLink Field (MODS)" short-name="XLink">
        <search-expression>
            mods:mods[mods:relatedItem[ends-with(@xlink:href, '$q')]]
        </search-expression>
        <targets/>
    </field>
</fields>
;

(:
    The different record formats and their combinations are listed. 
:)
declare variable $biblio:FORMATS :=
    <select name="format">
        <option value="MODS-TEI-VRA-WIKI">MODS or TEI or VRA or Wiki</option>
        <option value="MODS">MODS</option>
        <option value="TEI">TEI</option>
        <option value="VRA">VRA</option>
        <option value="WIKI">Wiki</option>
        <option value="MODS-TEI">MODS or TEI</option>
        <option value="MODS-VRA">MODS or VRA</option>
        <option value="TEI-VRA">TEI or VRA</option>
    </select>
;

(:
    Default query to be used if no query is specified. 
    This sets a search for all records in the theme's default collection.
:)
declare variable $biblio:DEFAULT_QUERY :=
    <query>
        <collection>{theme:get-root()}</collection>
        <and>
            <field m="1" name="any Field (MODS, TEI, VRA, Wiki)"></field>
        </and>
    </query>;

(:~
    Regenerate the HTML form to match the query, e.g. after adding more filter clauses.
    $incoming-query returns XML as follows:
    <query>
        <collection>/resources/commons/Cluster%20Publications</collection>
        <not>
            <and>
                <or>
                    <field m="1" name="any Field (MODS, TEI, VRA)">france</field>
                    <field m="2" name="any Field (MODS, TEI, VRA)">germany</field>
                </or>
                <field m="3" name="any Field (MODS, TEI, VRA)">identity</field>
            </and>
            <field m="4" name="Name">fuhr</field>
        </not>
    </query> 
    for: 
        - "france" All
        or "germany" All
        and "identity" All
        not "fuhr" Name
:)
declare function biblio:form-from-query($node as node(), $params as element(parameters)?, $model as item()*) as element()+ {
    let $incoming-query := $model[1]
    let $search-format := request:get-parameter("format", '')
    let $default-operator := request:get-parameter("default-operator", '')
    let $field1 := request:get-parameter("field1", '')
    let $query := 
        if ($incoming-query//field) 
        then $incoming-query 
        else $biblio:DEFAULT_QUERY
    return
    (
        <tr>
            <td colspan="3">Search for records in
                <select name="format">
                    {
                        for $format in $biblio:FORMATS/option
                        return
                        <option>
                            { if ($format eq $search-format) then attribute selected { "selected" } else () } 
                            {$format/text()}
                        </option>
                    }
                </select>
                format, using the
                <select name="default-operator">
                { for $operator in ('or', 'and')
                    return
                        <option>
                            { if ($operator eq $default-operator) then attribute selected { "selected" } else () } 
                            {$operator}
                        </option>
                }        
                </select>
                search operator, searching for
            </td>
            
        </tr>
    ,
        for $field-chosen at $pos in $query//field
            return
                <tr class="repeat">
                    <td class="operator">
                    {
                        let $operator := 
                            if ($field-chosen/preceding-sibling::*)
                            then string($field-chosen/../local-name(.))
                            else ()
                        (:NB: This returns "query" if there is only one search field.:)
                        return
                            <select name="operator{$pos}">
                            { if (empty($operator)) then attribute style { "display: none;" } else () }
                            {
                                for $opt in ("and", "or", "not")
                                return
                                    <option>
                                    {
                                        if ($opt eq $operator)
                                        then attribute selected { "selected" }
                                        else ()
                                    }
                                    { $opt }
                                    </option>
                            }
                            </select>
                    } 
                    </td>
                    <td class="search-term"> 
                        <jquery:input name="input{$pos}" value="{$field-chosen/string()}">
                            <jquery:autocomplete url="autocomplete.xql"
                                width="300" multiple="false"
                                matchContains="false"
                                paramsCallback="autocompleteCallback">
                            </jquery:autocomplete>
                        </jquery:input>
                    </td>
                    <td class="search-field">
                        in 
                        <select name="field{$pos}">
                        {
                            for $field-available in $biblio:FIELDS/field
                                return
                                    <option>
                                        { if (($field-available/@name/string() eq $field-chosen/@name/string()) or ($field-available/@short-name/string() eq $field-chosen/@name/string())) then attribute selected { "selected" } else () } 
                                        {$field-available/@name/string()}
                                    </option>
                        }
                        </select>
                    </td>
                    <td class="delete-search-field-button-container">
                        <input class="delete-search-field-button" title="Delete search field" type="image" name="deleteSearchFieldButton{$pos}" src="theme/images/delete.png" height="22" width="22" />                        
                    </td>                    
                </tr>
    )
};

(:~
    Generate an XPath query expression from the XML representation of the query, $query-as-xml.
    $query-as-xml has the form:
    <query>
        <collection>/resources/commons/EAST</collection>
        <and>
            <field m="1" name="Name">Kellner</field>
            <field m="2" name="Title">buddhist</field>
        </and>
    </query>
    $query-as-xml is composed by biblio:prepare-query($id, $collection, 
    $reload, $history, $clear, $filter, $mylist, $value) in biblio:query().
    $query-as-xml gets stored in the session-attribute 'query'.
    $query-as-xml is decomposed from the outside in, first treating the operators, 
    then the fields and last the collection.
    An operator gathers together two fields or one field and one operator.
    The function is called from the outside in biblio:eval-query().
:)
declare function biblio:generate-query($query-as-xml as element()) as xs:string* {
    let $query :=
    typeswitch ($query-as-xml)
        case element(query) return
            for $child in $query-as-xml/*
                return biblio:generate-query($child)
        case element(and) return
            (
                (:get the fields under "and":)
                biblio:generate-query($query-as-xml/*[1]), 
                " intersect ", 
                biblio:generate-query($query-as-xml/*[2])
            )
        case element(or) return
            (
                (:get the fields under "or":)
                biblio:generate-query($query-as-xml/*[1]), 
                " union ", 
                biblio:generate-query($query-as-xml/*[2])
            )
        case element(not) return
            (
                (:get the fields under "not":)
                biblio:generate-query($query-as-xml/*[1]), 
                " except ", 
                biblio:generate-query($query-as-xml/*[2])
            )
        (:Determine which field to search in: if a field has been specified, use it; otherwise default to "any Field (MODS, TEI, VRA)".:)
        case element(field) return
            let $expr := $biblio:FIELDS/field[@name eq $query-as-xml/@name or @short-name eq $query-as-xml/@short-name]/search-expression
            let $expr := 
                if ($expr) 
                then $expr
                (:Default to a search in All if no search field is chosen, i.e. when Simple Search is used.:)
                else $biblio:FIELDS/field[@name eq $biblio:FIELDS/field[1]/@name]/search-expression
            (:This results in expressions like:
            <field name="Title">mods:mods[ft:query(.//mods:titleInfo, '$q', $options)]</field>.
            The search term, to be substituted for '$q', is held in $query-as-xml. :)
            
            (: When searching for ID and xlink:href, do not use the chosen collection-path, but search throughout all of /resources. :)
            let $collection-path := 
                if ($expr/@name = ('the Record ID Field (MODS, VRA)', 'ID', 'the XLink Field (MODS)')) 
                then '/resources'
                else $query-as-xml/ancestor::query/collection/string()
            let $collection :=
                if ($collection-path eq $config:groups-collection)
                then
                (
                    (: searching the virtual 'groups' collection means searching the users collection. ??? :)
                    (:NB: Yes, but the user's home collection should perhaps not be included here.:)
                    concat("collection('", $config:users-collection, "')//")
                )
                else
                (
                    (: search one of the user's own collections or a commons collection. :)
                    concat("collection('", $collection-path, "')//")
                )
            return
                (:The search term held in $query-as-xml is substituted for the '$q' held in $expr.:)
                ($collection, replace($expr, '\$q', biblio:normalize-search-string($query-as-xml/string())))
        case element(collection)
            return
                if (not($query-as-xml/..//field)(: and not($config:require-query):)) 
                then 
                    (:If a search is made in /db/resources, we want /db/resources/temp to be excluded from the search, 
                    since it may contain stray files left there if the user is logged out.
                    Therefore a search is made in all other sub-collections of /db/resources.
                    Both this and the identical replacement in biblio:evaluate-query() are necessary.:)
                    if ($query-as-xml/string() eq '/resources')
                    then ('(collection("/resources/commons","/resources/users", "/resources/groups"))//(mods:mods | vra:vra | tei:TEI | atom:entry)')
                    else ('collection("', $query-as-xml, '")//(mods:mods | vra:vra | tei:TEI | atom:entry)')
                else ()
            default 
                return ()
         (:Leading wildcards cannot appear in searches within extracted text. :) 
         let $query := 
            for $q in $query
                return replace(replace($q, ':[?*]', ':'), '\s[?*]', ' ')
         return
            $query
};

(: If an apostrophe occurs in the search string (as in "China's"), it is escaped. 
This means that phrase searches can only be performed with double quotation marks.:)
(: ":" and "&" are replaced with spaces.:)
(: In the case of an unequal number of double quotation marks, all double quotation marks are removed.:)
declare function biblio:normalize-search-string($search-string as xs:string?) as xs:string? {
	let $search-string := 
	   if (functx:number-of-matches($search-string, '"') mod 2) 
	   then replace($search-string, '"', '') 
	   else $search-string 
	let $search-string := replace($search-string, "'", "''")
	let $search-string := translate($search-string, "[:&amp;]", " ")
    	return $search-string
};

(:~
    Transform the XML representation of the query into a simple string
    for display to the user in the query history.
:)
declare function biblio:xml-query-to-string($query-as-xml as element()) as xs:string* {
    typeswitch ($query-as-xml)
        case element(query) return
            for $query-term in $query-as-xml/*
                return biblio:xml-query-to-string($query-term)
        case element(and) return
            (
                biblio:xml-query-to-string($query-as-xml/*[1]), 
                " AND ", 
                biblio:xml-query-to-string($query-as-xml/*[2])
            )
        case element(or) return
            (
                biblio:xml-query-to-string($query-as-xml/*[1]), 
                " OR ", 
                biblio:xml-query-to-string($query-as-xml/*[2])
            )
        case element(not) return
            (
                biblio:xml-query-to-string($query-as-xml/*[1]), 
                " NOT ", 
                biblio:xml-query-to-string($query-as-xml/*[2])
            )
        case element(collection) return
            concat("collection(""", $query-as-xml, """):")
        case element(field) return
            concat($query-as-xml/@name, ':', $query-as-xml/string())
        default return
            ()
};

(:~
    Process single form parameter. Called from biblio:process-form().
:)
declare function biblio:process-form-parameters($params as xs:string*) as element() {
    (:Only take the new param. The form of params is "input1".:)
    let $param := $params[1]
    let $search-number := substring-after($param, 'input')
    (:This "param" is the search term, so get the search term for the param in question.:)
    let $search-term := request:get-parameter($param, "")
    let $search-field := request:get-parameter(concat("field", $search-number), 'any Field (MODS, TEI, VRA)')
    let $search-operator := request:get-parameter(concat("operator", $search-number), "and")
        return
            if (count($params) eq 1)
            then <field m="{$search-number}" name="{$search-field}">{$search-term}</field>
            else element { xs:QName($search-operator) } {
                    biblio:process-form-parameters(subsequence($params, 2)),
                    <field m="{$search-number}" name="{$search-field}" short-name="{$biblio:FIELDS/field[@name eq $search-field]/@short-name}">{$search-term}</field>
                }
};

(:~
    Process the received form parameters and create an XML representation of
    the query. Filter out empty parameters and take care of boolean operators.
:)
declare function biblio:process-form() as element(query)? {
let $collection := xmldb:encode-uri(request:get-parameter("collection", theme:get-root()))
(:    let $collection := uu:escape-collection-path(request:get-parameter("collection", theme:get-root())):)
    let $fields :=
        (:  Get a list of all input parameters which are not empty,
            ordered by input name. :)
        for $param in request:get-parameter-names()[starts-with(., 'input')]
        let $value := request:get-parameter($param, ())
        where string-length($value) gt 0
        order by $param descending
        return
            $param
    return
        if (exists($fields))
        then
            (:  process-form recursively calls itself for every parameter and
                generates and XML representation of the query. :)
            <query>
                <collection>{$collection}</collection>
                { biblio:process-form-parameters($fields) }
            </query>
        else
            <query>
                <collection>{$collection}</collection>
            </query>
};

(:~
    Helper function used to sort by name within the "order by"
    clause of the query.
:)

declare variable $biblio:eastern-languages := ('chi', 'jpn', 'kor', 'skt', 'tib');
declare variable $biblio:author-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt', 'photographer', 'pht');
(: This function is adapted in nameutil:format-name() in names.xql. Any changes should be coordinated. :)
declare function biblio:order-by-author($hit as element()) as xs:string?
{
    (: Pick the first occurring name element of an author/creator. :)
    let $vra-name := $hit//vra:agent[vra:role = $biblio:author-roles][1]/vra:name
    let $mods-name :=
        if ($vra-name)
        then () 
        else $hit/mods:name[mods:role/mods:roleTerm = $biblio:author-roles or not(mods:role/mods:roleTerm)][1] 

    return
        if ($mods-name) 
                then
                        (: Sort according to family and given names.:)
                        let $mods-sortFirst :=
                       (: If there is a namePart marked as being in a Western language, there could in addition be a transliterated and a Eastern-script "nick-name", but the Western namePart should have precedence over the nick-name, therefore pick out the Western-language nameParts first. :)
                       if ($mods-name/mods:namePart[@lang != $biblio:eastern-languages]/text())
                       then
                           (: If it has a family type, take it; otherwise take whatever namePart there is (in case of a name which has not been analysed into given and family names. :)
                           if ($mods-name/mods:namePart[@type eq 'family']/text())
                           then $mods-name/mods:namePart[@lang != $biblio:eastern-languages][@type eq 'family'][1]/text()
                           else $mods-name/mods:namePart[@lang != $biblio:eastern-languages][1]/text()
                       else
                           (: If there is not a Western-language namePart, check if there is a namePart with transliteration; if this is the case, take it. :)
                           if ($mods-name/mods:namePart[@transliteration]/text())
                           then
                               (: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
                               if ($mods-name/mods:namePart[@type eq 'family']/text())
                               then $mods-name/mods:namePart[@type eq 'family'][@transliteration][1]/text()
                               else $mods-name/mods:namePart[@transliteration][1]/text()
                           else
                               (: If the name does not have a transliterated namePart, it is probably a "standard" (unmarked) Western name, if it does not have a script attribute or uses Latin script. :)
                               if ($mods-name/mods:namePart[@script eq 'Latn']/text() or $mods-name/mods:namePart[not(@script)]/text())
                               then
                               (: If it has a family type, take it; otherwise takes whatever untransliterated namePart there is.:) 
                                   if ($mods-name/mods:namePart[@type eq 'family']/text())
                                   then $mods-name/mods:namePart[not(@script) or @script eq 'Latn'][@type eq 'family'][1]/text()
                                   else $mods-name/mods:namePart[not(@script) or @script eq 'Latn'][1]/text()
                               (: The last step should take care of Eastern names without transliteration. These will usually have a script attribute :)
                               else
                                   if ($mods-name/mods:namePart[@type eq 'family']/text())
                                   then $mods-name/mods:namePart[@type eq 'family'][1]/text()
                                   else $mods-name/mods:namePart[1]/text()
                   let $mods-sortLast :=
                           if ($mods-name/mods:namePart[@lang != $biblio:eastern-languages]/text())
                           then $mods-name/mods:namePart[@lang != $biblio:eastern-languages][@type eq 'given'][1]/text()
                           else
                               if ($mods-name/mods:namePart[@transliteration]/text())
                               then $mods-name/mods:namePart[@type eq 'given'][@transliteration][1]/text()
                               else
                                   if ($mods-name/mods:namePart[@script eq 'Latn']/text() or $mods-name/mods:namePart[not(@script)]/text())
                                   then $mods-name/mods:namePart[@type eq 'given'][not(@script) or @script eq 'Latn'][1]/text()
                                   else $mods-name/mods:namePart[@type eq 'given'][1]/text()
                    let $mods-sort-string :=
                        if (concat($mods-sortFirst, $mods-sortLast)) 
                        then upper-case(concat($mods-sortFirst, ' ', $mods-sortLast)) 
                        else ()
                    return
                        $mods-sort-string
                    else
                        if ($vra-name) 
                        then 
                            let $vra-sort-string := upper-case($vra-name)
                            return 
                                $vra-sort-string
                        else ()   
};

declare function biblio:get-year($hit as element()) as xs:string? {
(:number() is used to filter out string values like "unknown".:)
(:NB: year is sorted as string.:)
(:NB: TEI documents hard to fit in.:)
    if ($hit/mods:originInfo[1]/mods:dateIssued[1]/number()) 
    then functx:substring-before-if-contains($hit/mods:originInfo[1]/mods:dateIssued[1],'-') 
    else 
        if ($hit/mods:originInfo[1]/mods:copyrightDate[1]/number()) 
        then functx:substring-before-if-contains($hit/mods:originInfo[1]/mods:copyrightDate[1],'-') 
        else
            if ($hit/mods:originInfo[1]/mods:dateCreated[1]/number()) 
            then functx:substring-before-if-contains($hit/mods:originInfo[1]/mods:dateCreated[1],'-') 
            else
                if ($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:dateIssued[1]/number()) 
                then functx:substring-before-if-contains($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:dateIssued[1],'-') 
                else
                    if ($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:copyrightDate[1]/number()) 
                    then functx:substring-before-if-contains($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:copyrightDate[1],'-') 
                    else
                        if ($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:dateCreated[1]/number()) 
                        then functx:substring-before-if-contains($hit/mods:relatedItem[1]/mods:originInfo[1]/mods:dateCreated[1],'-') 
                        else
                            if ($hit/mods:relatedItem[1]/mods:part[1]/mods:date[1]/number()) 
                            then functx:substring-before-if-contains($hit/mods:relatedItem[1]/mods:part[1]/mods:date[1],'-') 
                            else ()
};



(: Map order parameter to xpath for order by clause :)
(: NB: It does not make sense to use Score if there is no search term to score on. :)
declare function biblio:construct-order-by-expression($sort as xs:string?) as xs:string?
{
    let $sort-direction := request:get-parameter("sort-direction", '')
        return
            if ($sort eq "Score") 
            (:If no sort direction has been chosen, the search comes from simple search and the highest scores should be first.:)
            then concat("ft:score($hit) ", if ($sort-direction) then $sort-direction else 'descending') 
            else 
                if ($sort eq "Author") 
                then concat("biblio:order-by-author($hit) ", if ($sort-direction) then $sort-direction else 'ascending', " ", if ($sort-direction eq 'descending') then "empty least" else "empty greatest")
                else 
                    if ($sort eq "Title") 
                    then concat("$hit/(mods:titleInfo[not(@type)][1]/mods:title[1] | vra:work/vra:titleSet[1]/vra:title[1] | tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1] | atom:entry/atom:title)", " ", if ($sort-direction) then $sort-direction else 'ascending', " ", if ($sort-direction eq 'descending') then "empty least" else "empty greatest")
                    else 
                        if ($sort eq "Year") 
                        then concat("biblio:get-year($hit) ", if ($sort-direction) then $sort-direction else 'descending', " ", if ($sort-direction eq 'descending') then "empty least" else "empty greatest")
                        else ()
        };

(:~
    Evaluate the actual XPath query and order the results
:)
declare function biblio:evaluate-query($query-as-string as xs:string, $sort as xs:string?) {
    (:If a search is made in /db/resources, we want /db/resources/temp to be excluded from the search, 
    since it may contain stray files left there if the user is logged out.
    Therefore a search is made in all other sub-collections of /db/resources.
    Both this and the identical replacement in biblio:generate-query() are necessary.:)
    let $query-as-string := replace($query-as-string, "'/resources'", "'/resources/commons','/resources/users', '/resources/groups'")
    (:NB: The following hack is required because some queries end up with "//" before "order by", raising the error that "by" is an unexpected expression.:)
    let $query-as-string := if (ends-with($query-as-string, "//")) then concat($query-as-string, "*") else $query-as-string
    let $order-by-expression := biblio:construct-order-by-expression($sort)
    let $query-with-order-by-expression :=
        (:The condition should be added that there is a search term. This will address comment in biblio:construct-order-by-expression(). :)
        if ($order-by-expression) then
            concat("for $hit in ", $query-as-string, " order by ", $order-by-expression, " return $hit")
        else
            $query-as-string
    let $options := request:get-parameter("default-operator", '')
    let $options :=
        if ($options eq 'and')
        then
            <options>
                <default-operator>and</default-operator>
                <leading-wildcard>yes</leading-wildcard>
                <filter-rewrite>yes</filter-rewrite>
            </options>
        else
            <options>
                <default-operator>or</default-operator>
                <leading-wildcard>yes</leading-wildcard>
                <filter-rewrite>yes</filter-rewrite>
            </options>
    return
        util:eval($query-with-order-by-expression)
};

(:~
    Add a query to the user's query history. We store the XML representation
    of the query.
:)
declare function biblio:add-to-history($query-as-xml as element()) {
    let $oldHistory := session:get-attribute('history')
    let $newHistory :=
        let $n := if ($oldHistory) then max(for $n in $oldHistory/query/@n return xs:int($n)) + 1 else 1
        return
            <history>
                <query id="q{$n}" n="{$n}">
                    { $query-as-xml/* }
                </query>
                { $oldHistory/query }
            </history>
    return
        session:set-attribute('history', $newHistory)
};

(:~
    Retrieve a query from the query history
:)
declare function biblio:query-from-history($id as xs:string) {
    let $history := session:get-attribute('history')
    return
        $history/query[@id = $id]
};

(:~
    Returns the query history as a HTML list. The queries are
    transformed into a simple string representation.
:)
declare function biblio:query-history($node as node(), $params as element(parameters)?, $model as item()*) {
    <ul>
    {
        let $history := session:get-attribute('history')
        for $query-as-string in $history/query
        return
            <li><a href="?history={$query-as-string/@id}&amp;query-tabs=advanced-search-form">{biblio:xml-query-to-string($query-as-string)}</a></li>
    }
    </ul>
};

declare function biblio:last-collection-queried($node as node(), $params as element(parameters)?, $model as item()*) {
        let $search-collection := $model[1]//collection
        let $search-collection := 
            if ($search-collection) 
            then replace(replace(xmldb:decode-uri($search-collection), '/resources/commons', 'resources'), '/resources/users', 'resources') 
            else 'resources' 
        let $search-collection := 
            if (starts-with($search-collection, '/db'))
            then replace($search-collection, '/db', '')
            else $search-collection
        let $search-collection := concat(' found in ', $search-collection)
            return
                $search-collection
};

(:~
    Evaluate the query given as XML and store its results into the HTTP session
    for later reference.
:)
declare function biblio:eval-query($query-as-xml as element(query)?, $sort as item()?) as xs:int {
    if ($query-as-xml) 
    then
        let $search-format := request:get-parameter("format", '')
        let $query := string-join(biblio:generate-query($query-as-xml), '')
        (:Simple search does not have the parameter format, but should search in all formats.:)
        let $search-format := 
            if ($search-format)
            then $search-format
            else 'MODS-TEI-VRA-WIKI'
        (:If the format parameter does not contain a certain string, 
        the corresponding namepsace is stripped from the search expression, 
        leading to a search for the element in question in no namespace.:)
        let $query :=
            if (not(contains($search-format, 'MODS')))
            then replace($query, 'mods:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'VRA')))
            then replace($query, 'vra:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'TEI')))
            then replace($query, 'tei:', '')
            else $query
        let $query :=
            if (not(contains($search-format, 'Wiki') or contains($search-format, 'WIKI')))
            then replace($query, 'atom:', '')
            else $query
        let $sort := if ($sort) then $sort else session:get-attribute("sort")
        let $results := biblio:evaluate-query($query, $sort)
        let $results-vra-work := $results[vra:work]
        let $results-vra-image := 
            (:treat vra:image records only if there is a search term in the query; 
            otherwise empty searches will be slowed down by finding all work records for all image records:)
            (:NB: searches exclusively in extracted text from vra:image records are omitted, since these proceed through "ft:search('page:$q')", i.e. do not contain a "[":)
            if (contains($query, '['))
            then $results[vra:image]
            else ()
        (:since vra:collection are not captured, these are in effect filtered away:)
        let $results-vra-image := 
            if ($results-vra-image)
            then $results-vra-image/vra:image/vra:relationSet/vra:relation[@type eq "imageOf"]/@relids
            else ()
        let $results-vra-image := 
            if ($results-vra-image)
            then collection($config:mods-root)//vra:work[@id = $results-vra-image]/..
            else ()
        let $results-vra := ($results-vra-work union $results-vra-image)
        (:we assume that all mods records will have a titleInfo element - otherwise we cannot process them:)
        let $results-mods := $results[mods:titleInfo]
        (:we will have tei objects returned that are not whole documents, so this has to be filtered by namespace, but using namespace-uri() is too expensive:)
        let $results-tei := $results[self::tei:p | self::tei:bibl | self::tei:titleStmt | self::tei:person | self::tei:TEI | self::tei:title | self::tei:name | self::tei:persName | self::tei:term | self::tei:head]
        (:using "let $results-tei := $results[self::tei:*]" should work, but gives error: context is missing for node 1 !:)
        let $results-atom := $results[atom:title]
        let $results := ($results-vra, $results-mods, $results-tei, $results-atom)
        let $processed :=
            for $item in $results
            return
                typeswitch ($item)
                    case element(results) 
                        return $item/search
                    default 
                        return $item
        (:~ Take the query results and store them into the HTTP session. :)
        let $null := session:set-attribute('mods:cached', $processed)
        let $null := session:set-attribute('query', $query-as-xml)
        let $null := session:set-attribute('sort', $query-as-xml)
        let $null := session:set-attribute('collection', $query-as-xml)
        let $null := biblio:add-to-history($query-as-xml)
        return
            count($processed)
    (:NB: When 0 is returned to a query, it is set here.:)
    else 0 
};

(:~ 
: Outputs a notice (if any) to the user
:)
declare function biblio:notice() as element(div)* {
    
    (: have we already seen the notices for this session? :)
    if (session:get-attribute("seen-notices") eq true()) 
    then ()
    else
    (
        (: 1 - is there a login notice :)
        
        (: find all collections that are shared with the current user and whoose modification time is after our last login time :)
        
        let $shared-roots := sharing:get-shared-collection-roots(false()) return
        if (not(empty($shared-roots)))
        then
        (
            let $last-login-time := security:get-last-login-time(security:get-user-credential-from-session()),
            $collections-modified-since-last-login := local:find-collections-modified-after($shared-roots, $last-login-time) return
               
                if (not(empty($collections-modified-since-last-login))) 
                then
                (
                    <div id="notices-dialog" title="System Notices">
                        <p>The following Groups have published new or updated documents since you last logged in:</p>
                        <ul>
                            {
                                for $modified-collection in $collections-modified-since-last-login 
                                return
                                    <li>{replace($modified-collection, ".*/", "") } ({count(xmldb:get-child-resources($modified-collection)[$last-login-time lt xmldb:last-modified($modified-collection, .)]) })</li>
                            }
                        </ul>
                    </div>
                )
                else ()
        )
        else ()
    )
};

(:~
: Get the last-modified date of a collection
:)
declare function local:get-collection-last-modified($collection-path as xs:string) as xs:dateTime {
	let $resources-last-modified := 
		for $resource in xmldb:get-child-resources($collection-path) return
			xmldb:last-modified($collection-path, $resource)
	return
		if (not(empty($resources-last-modified)))
		then max($resources-last-modified)
		else xmldb:created($collection-path)
};

(:~
: Find all sub-collections that have a group and are modified after a dateTime
:)
declare function local:find-collections-modified-after($collection-paths as xs:string*, $modified-after as xs:dateTime) as xs:string* {
	
	for $collection-path in $collection-paths 
	return
	(
	   if ($modified-after lt local:get-collection-last-modified($collection-path)) 
	   then $collection-path
	   else (),
       local:find-collections-modified-after(xmldb:get-child-collections($collection-path), $modified-after)
   )
};

(:~
    Clear the search terms on the advanced search tab by performing an empty search in the selected collection.
:)
declare function biblio:clear-search-terms($collection) {
    <query><collection>{$collection}</collection></query>

};

(:~
    Clear the query history.
:)
declare function biblio:clear-history() {
    let $null := session:remove-attribute('history')
    let $null := session:set-attribute("history", ())
    return
        ()
};


declare function biblio:current-user($node as node(), $params as element(parameters)?, $model as item()*) {
    <span>{request:get-attribute("xquery.user")}</span>
};

declare function biblio:login($node as node(), $params as element(parameters)?, $model as item()*) {
    let $user := request:get-attribute("xquery.user")
    return 
        if ($user eq 'guest')
        then
        (
            <div class="help"><a href="../../docs/" target="_blank">Help</a></div>
            ,
            <div class="login"><a href="#" id="login-link">Login</a></div>
        )
        else
            if ($user eq 'admin')
            then 
                (
                    <div class="help"><a href="../../docs/">Help</a></div>
                    ,   
                    <div class="help"><a id="optimize-trigger" href="#">Create custom indexes for sorting</a></div>
                    ,
                    <div class="login">Logged in as <span class="username">{$user}</span>. <a href="?logout=1">Logout</a></div>
                )
            else
            (
                <div class="help"><a href="../../docs/">Help</a></div>
                ,
                <div class="login">Logged in as <span class="username">{let $human-name := security:get-human-name-for-user($user) return if (not(empty($human-name))) then $human-name else $user}</span>. <a href="?logout=1">Logout</a></div>
            )
};

declare function biblio:collection-path($node as node(), $params as element(parameters)?, $model as item()*) {
    (:let $collection := functx:replace-first(xmldb:encode-uri(request:get-parameter("collection", theme:get-root())), "/db/", ""):)
    let $collection := functx:replace-first(xmldb:encode-uri(request:get-parameter("collection", theme:get-root())), "/db/", "")    
        return
            (:templates:copy-set-attribute($node, "value", uu:unescape-collection-path($collection), $model):)
            templates:copy-set-attribute($node, "value", xmldb:decode-uri($collection), $model)
};

declare function biblio:result-count($node as node(), $params as element(parameters)?, $model as item()*) {
    let $hitCount := $model[2]
    return
        if ($hitCount ne 1)
        then (<span class="hit-count">{$hitCount}</span>, ' records')
        else (<span class="hit-count">{$hitCount}</span>, ' record')
};

declare function biblio:resource-types($node as node(), $params as element(parameters)?, $model as item()*) {
    let $classifier := tokenize($node/@class, "\s")
    let $classifier := $classifier[2]
    let $code-table-path := concat($config:edit-app-root, '/code-tables')
    
    let $document-type-codes-path := concat($code-table-path, '/document-type-codes.xml')
    let $document-type-code-table := doc($document-type-codes-path)/code-table
    
    let $language-type-codes-path := concat($code-table-path, '/language-3-type-codes.xml')
    let $language-type-code-table := doc($language-type-codes-path)/code-table
    let $language-options :=
                    for $item in $language-type-code-table//item[(frequencyClassifier)]
                        let $label := $item/label/text()
                        let $labelValue := $item/value/text()
                        let $sortOrder :=                                  
                            if ($item/frequencyClassifier[. = 'common']) 
                            then 'A' 
                            (: else frequencyClassifier = 'default':)
                            else ''
                        order by $sortOrder, $label
                        return
                            <option value="{$labelValue}">{$item/label/text()}</option>
    (:to get all values:
                    for $item in $language-type-code-table//item
                        let $label := $item/label/text()
                        let $labelValue := $item/value/text()
                        let $sortOrder := 
                            if (empty($item/frequencyClassifier)) 
                            then 'B' 
                            else 
                                if ($item/frequencyClassifier[. = 'common']) 
                                then 'A' 
                                else ''
                        order by $sortOrder, $label
                        return
                            <option value="{$labelValue}">{$item/label/text()}</option>:)
                            
    let $script-codes-path := concat($code-table-path, '/script-short-codes.xml')
    let $script-code-table := doc($script-codes-path)/code-table
    let $script-options :=
                    for $item in $script-code-table//item
                        let $label := $item/label/text()
                        let $labelValue := $item/value/text()
                        let $sortOrder := 
                        if (empty($item/frequencyClassifier)) 
                        then 'B' 
                        else 
                            if ($item/frequencyClassifier[. = 'common']) 
                            then 'A'
                            else ''
                        order by $sortOrder, $label
                        return
                            <option value="{$labelValue}">{$item/label/text()}</option>
    
    let $transliteration-codes-path := concat($code-table-path, '/transliteration-short-codes.xml')
    let $transliteration-code-table := doc($transliteration-codes-path)/code-table
    let $transliteration-options :=
                    for $item in $transliteration-code-table//item
                        let $labelValue := $item/value/text()
                        return
                            <option value="{$labelValue}">{$item/label/text()}</option>
                    
    
    return 
        <div class="content">
            <form id="{if ($classifier eq 'stand-alone') then 'new-resource-form' else 'add-related-form'}" action="../edit/edit.xq" method="GET">
                <ul>
                {
                    for $item in $document-type-code-table//item[classifier = $classifier]
                    order by $item/sort/text(), $item/label/text()
                    return
                        <li>
                          <input type="radio" name="type" value="{$item/value/text()}"/><span> {$item/label/text()}</span>
                        </li>
                }
                </ul>
                
                <div class="language-label">
                    <label for="languageOfResource">Language: </label>
                <span class="language-list">
                <select name="languageOfResource">
                    {$language-options}
                    </select>
                </span>
                </div>
                
                <div class="language-label">
                    <label for="scriptOfResource">Script: </label>
                <span class="language-list">
                <select name="scriptOfResource">
                    {$script-options}
                    </select>
                </span>
                </div>
                
                <div class="language-label">
                    <label for="transliterationOfResource">Transliteration Scheme: </label>
                <span class="language-list">
                <select name="transliterationOfResource">
                    {$transliteration-options}
                    </select>
                </span>
                </div>
                
                <input type="hidden" name="collection"/>
                <input type="hidden" name="host"/>
            </form>
        </div>
};

declare function biblio:optimize-trigger($node as node(), $params as element(parameters)?, $model as item()*) {
    let $user := request:get-attribute("xquery.user")
    return
        if (xmldb:is-admin-user($user))
        then <a id="optimize-trigger" href="#">Create custom indexes for sorting</a>
        else ()
};

declare function biblio:form-select-current-user-groups($select-name as xs:string) as element(select) {
    let $user := request:get-attribute("xquery.user") return
        <select name="{$select-name}">
        {
            for $group in xmldb:get-user-groups($user) return
                <option value="{$group}">{$group}</option>
        }
        </select>
};

declare function biblio:get-writeable-subcollection-paths($path as xs:string) {
    
	for $sub in xmldb:get-child-collections($path)
	let $col := concat($path, "/", $sub) return
		(
			if (security:can-write-collection($col))
			then $col
			else (), biblio:get-writeable-subcollection-paths($col)
		)
};

(:~
    Perform a search from scratch
:)
declare function biblio:apply-search($collection as xs:string?, $search-field as xs:string, $value as xs:string) {
    let $collection := if ($collection) then $collection else '/db/resources/'
    return
        <query>
            { $collection }
            <field name="{$biblio:FIELDS/field[(@name, @short-name) = $search-field]/@name}">{$value}</field>
        </query>
    
};

(:~
    Filter an existing result set by applying an additional
    clause with "and".
:)
declare function biblio:apply-filter($collection as xs:string?, $filter as xs:string, $value as xs:string) {
    let $prevQuery := session:get-attribute("query")
    return
        (:If there is no collection parameter, then fill in the collection from the previous query:)
        if (empty($collection))
        then
            if (empty($prevQuery//field))
            then
                <query>
                    { $prevQuery/collection }
                    <field name="{$biblio:FIELDS/field[(@name, @short-name) = $filter]/@name}">{$value}</field>
                </query>
            else
            (:NB: what about the default operator?:)
                <query>
                    { $prevQuery/collection }
                    <and>
                    { $prevQuery/*[not(self::collection)] }
                    <field name="{$biblio:FIELDS/field[(@name, @short-name) = $filter]/@name}">{$value}</field>
                    </and>
                </query>
        else
        (:If there is a collection parameter, then use it:)
            if (empty($prevQuery//field))
            then
                <query>
                    <collection>{ $collection }</collection>
                    <field name="{$biblio:FIELDS/field[(@name, @short-name) = $filter]/@name}">{$value}</field>
                </query>
            else
                <query>
                    <collection>{ $collection }</collection>
                    <and>
                    { $prevQuery/*[not(self::collection)] }
                    <field name="{$biblio:FIELDS/field[(@name, @short-name) = $filter]/@name}">{$value}</field>
                    </and>
                </query>
};

(:~
: Prepare an XML fragment which describes the query to undertake

params passed:

$collection
    The selected collection.
$reload
    "true" is passed when clicking "Cancel Editing" in the editor. 
$history
    value like "q2" is passed when clicking on search in Query History tab.
$clear
    "clear" is passed when clicking "Clear All". This now leads to an error. $collection becomes "/db". 
$filter
    value like "name" is passed when clicking on facet item, along with $value, the item contents.
$mylist
    "clear" is passed when clicking "Clear"
    "display" is passed when clicking "Display"
    nothing is passed when clicking "Export".
$value
    (used with $filter.)

$field (plus number)
$id
$operator
$sort
query-tabs
    can have values "simple", "advanced-search-form", "personal-list" (search-form.html)

$param
:
:)
declare function biblio:prepare-query($id as xs:string?, $collection as xs:string?, $reload as xs:string?, 
    $history as xs:string?, $clear as xs:string?, $filter as xs:string?, $search-field as xs:string?, $mylist as xs:string?, 
    $value as xs:string?) as element(query)? {
    if ($id)
    then
        <query>
            <collection>{$config:mods-root}</collection>
            <field m="1" name="the Record ID Field (MODS, VRA)">{$id}</field>
        </query>
    else 
        if (empty($collection)) 
        then ()
        else 
            if ($reload) 
            then session:get-attribute('query')
            else 
                if ($history)
                then biblio:query-from-history($history)
                else 
                    if ($clear)
                    then biblio:clear-search-terms($collection)
                    else 
                        if ($filter) 
                        then biblio:apply-filter($collection, $filter, $value)
                        else 
                            if ($search-field) 
                            then biblio:apply-search($collection, $search-field, $value)
                            else biblio:process-form()
                            (:"else" includes "if ($mylist eq 'display')", the search made when displaying items in My List.:)
};

(:~
: Gets cached results from the session;
: if no such results exist, then a query is performed
: and the results are then cached in the session
:
: @return a count of the results available
:)
declare function biblio:get-or-create-cached-results($mylist as xs:string?, $query-as-xml as element(query)?, $sort as item()?) as xs:int {
    if ($mylist) 
    then 
    (
        if ($mylist eq 'clear')
        then session:set-attribute("personal-list", ())
        else ()
        ,
        let $list := session:get-attribute("personal-list")
        let $items :=
            for $item in $list/listitem
            return
                util:node-by-id(doc(substring-before($item/@id, '#')), substring-after($item/@id, '#'))
        let $null := session:set-attribute('mods:cached', $items)
        return
            count($items)
    )
    else
        biblio:eval-query($query-as-xml, $sort)
};

declare function biblio:get-query-as-regex($query-as-xml) as xs:string { 
    let $query := string-join($query-as-xml//field, ' ')
    (:We prepare for later tokenization of expressions in boolean searches 
    by substituting spaces for the operators.:)
    let $query := 
        for $expression in $query
            return 
                replace(replace(replace($expression, '\sAND\s', ' '), '\sOR\s', ' '), '\sNOT\s', ' ')
    (:we first go through the outer expression, to see if there are any phrase searches, then tokenize on spaces:)
    let $query := 
        for $expression in $query
        return 
            (:if the expression is a phrase search, do not change it:)
            if (starts-with($expression, '"') and ends-with($expression, '"')) 
            then translate($expression, '"', '')
            else 
                (:We assume that '+' is only used for prefixing, so we strip it:)
                (:We assume that initial '-' is only used for prefixing, so we strip it:)
                (:'[' and ']' are used in text range searches; we strip them as well:)
                (:'{' and '}' are used in text range searches; we strip them as well:)
                (:'^' is used for boosting; we strip it as well:)
                (:Punctuation used in the formatting of names is deleted.:) 
                (:We strip the parentheses, since they are not used in highlighting:)
                (:We strip the fuzzy search postfix, since there is nothing we can do with it.
                We leave a space after it to isolate any number following it.:)
                (:Ideally speaking, it should be checked if the characters in question occur 
                in word-initial or word-final position, but if any of them occur elsewhere, 
                they will make the query invalid anyway, so there is actually no need to do this.:)
                (:Since a final period is itself treated as whitespace, it is removed, since otherwise it would reseult in expressions
                sunce as "\bW.\b" which do not highlight.:)
                let $query := 
                    for $expression in $query
                        return 
                            normalize-space(
                            translate(translate(translate(translate(translate(translate(translate(translate(translate(translate(translate($expression
                                , '^\-', ' ') (:appears to strip all hyphens:)
                                , '\{', ' ')
                                , '\}', ' ')
                                , '\[', ' ')
                                , '\]', ' ')
                                , '\^', ' ')
                                , '(', ' ')
                                , ')', ' ')
                                , '\~', ' ')
                                , ',', ' ')
                                , '\.^', ' ') (:appears to strip all periods:)
                            )
                (:First tokenize the expressions created by replacement by space above:)
                let $query := tokenize($query, ' ') 
                    return
                        (:For each of the tokenized expression, 
                        replace the lucene wildcards with the corresponding regex wildcard 
                        and wrap the resultant expression in regex word boundaries:)
                        for $expression in $query
                            return
                                concat(
                                    '\b'
                                    ,
                                    replace(
                                        replace(
                                            translate(
                                                $expression
                                            , ' ', '|')
                                        , '\?', '\\w')
                                    , '\*', '\\w*?')
                                    ,
                                    '\b')
                (:Join all regex expressions with the or operator.:)
                let $query := string-join($query, '|')
                    return $query
};


declare function biblio:query($node as node(), $params as element(parameters)?, $model as item()*) {
    session:create()
    ,
    (: We receive an HTML template as input :)
    (:the search field passed in the url:)
    let $filter := request:get-parameter("filter", ())
    (:the search term for added filters passed in the url:)
    let $search-field := request:get-parameter("search-field", ())
    (:the search term for new sarches passed in the url:)
    let $value := request:get-parameter("value", ())
    let $history := request:get-parameter("history", ())
    let $reload := request:get-parameter("reload", ())
    let $clear := request:get-parameter("clear", ())
    let $mylist := request:get-parameter("mylist", ()) (:clear, display:)
    let $collection := xmldb:encode-uri(request:get-parameter("collection", $config:mods-root))
(:    let $collection := uu:escape-collection-path(request:get-parameter("collection", $config:mods-root)):)
    let $collection := if (starts-with($collection, "/db")) then $collection else concat("/db", $collection)
    let $id := request:get-parameter("id", ())
    let $sort := request:get-parameter("sort", ())

    (: Process request parameters and generate an XML representation of the query :)
    let $query-as-xml := biblio:prepare-query($id, $collection, $reload, $history, $clear, $filter, $search-field, $mylist, $value)
    (: Get the results :)
    let $query-as-regex := biblio:get-query-as-regex($query-as-xml)
    let $null := session:set-attribute('regex', $query-as-regex)
    let $results := biblio:get-or-create-cached-results($mylist, $query-as-xml, $sort)
    return
        templates:process($node/node(), ($query-as-xml, $results))
};