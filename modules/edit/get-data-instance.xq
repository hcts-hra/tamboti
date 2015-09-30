xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace mads = "http://www.loc.gov/mads/";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";

(: get-instance.xq - gets the instance data to load into the editor and prunes the mods record to only load the instance data that is needed for a given tab.
Note that the instance that this script returns MUST include an ID for saving.
:)

(: This is the id of the document we are going to edit if we are not creating a new record :)
let $id := request:get-parameter('id', '')
(:called once:)

(: This is the ID of the tab but we just use tab in the URL. If no tab-id is
   specified, then we use the title tab.  :)
let $tab-id := request:get-parameter('tab-id', 'title')

let $collection := $config:mods-temp-collection

(: Get the document with the parameter id in temp. :)
let $instance := collection($collection)//mods:mods[@ID = $id]


return
if ($tab-id eq 'mads')
then 
    <mads xmlns="http://www.loc.gov/mads/" ID="{$id}">
      { (: this is where we run the query that gets just the data we need for this tab :)
        $instance
      }
    </mads>
else
    $instance
