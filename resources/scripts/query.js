$(function() {
    $("#edit-action-form").submit(function() {
        console.log("Submit ................");
        var $form = $(this);
        var records = $form.find("input").val().split(',');
        var url = $form.attr("action");
        var xml = "<data>";

        for (var i = 0; i < records.length; i++) {
            xml += "<file>" + records[i] + "</file>";
        }
        xml += "</data>";

        $.ajax({
            type: "POST",
            url: url,
            contentType: "application/xml",
            dataType: 'text',
            data: xml,
            error: function() {
                showMessage("Could not send record ids to ziziphus.");
            },
            success: function(data) {
                if (data !== null) {
                    var win = window.open('about:blank');
                    with (win.document)
                    {
                        open();
                        write(data);
                        close();
                    }
                }
            }
        });

        return false;
    });

    $('#keyword-form').submit(function() {
        loadIndexTerms();
        return false;
    });

    if ($("*[name='render-collection-path']")[0]) {
        var renderCollectionPath = $("#simple-search-form input[name='render-collection-path']").data("collection-path");
        $("#simple-search-form input[name='render-collection-path']").val(renderCollectionPath);
        $("#simple-search-form input[name='collection']").val(renderCollectionPath);
        updateCollectionPathOutputs($("#simple-search-form input[name = 'render-collection-path']").val());
    }

    initCollectionTree();

    galleries = new tamboti.galleries.Viewer($("#lightbox"));

    // Init pagination
    tamboti.apis.initialSearch();

    $(".pagination-mode-gallery").click(function(ev) {
        ev.preventDefault();
        $("#results").pagination("option", "params", {mode: "gallery"});
        $("#results").pagination("option", "itemsPerPage", 20);
        $("#results").pagination("refresh");
    });
    $(".pagination-mode-grid").click(function(ev) {
        ev.preventDefault();
        $("#results").pagination("option", "params", {mode: "grid"});
        $("#results").pagination("option", "itemsPerPage", 40);
        $("#results").pagination("refresh");
    });
    $(".pagination-mode-list").click(function(ev) {
        ev.preventDefault();
        $("#results").pagination("option", "params", {mode: "list"});
        $("#results").pagination("option", "itemsPerPage", 20);
        $("#results").pagination("refresh");
    });
    $("#simple-search-form-submit-button").click(function() {
        tamboti.apis.simpleSearch();
    });
    $("#advanced-search-form-submit-button").click(function() {
        tamboti.apis.advancedSearch();
    });

    pingSession();

    // initialize the dropDownListCheckbox
    tamboti.ddlcb = $("#ddlcb").dropDownListCheckbox({
        containerCls: "#ddlcb",
        mainOption: '#ddlcb-select-all',
        mainComponentOptionSelected: function() {
            $("#pagination input:checkbox").attr("checked", "checked").each(
                    function(index) {
                        tamboti.ddlcb.dropDownListCheckbox.registerExternalOption([$(this).attr("data-tamboti-record-id")]);
                    }
            );
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        },
        mainComponentOptionUnselected: function() {
            $("#pagination input:checkbox").removeAttr('checked').each(
                    function(index) {
                        tamboti.ddlcb.dropDownListCheckbox.unregisterExternalOption([$(this).attr("data-tamboti-record-id")]);
                    }
            );
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        },
        otherComponentOptionSelected: function($option) {
            $(".search-list-item-checkbox").prop("checked", "checked").each(
                    function(index) {
                        tamboti.ddlcb.dropDownListCheckbox.registerExternalOption([$(this).attr("data-tamboti-record-id")]);
                    }
            );
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        },
        otherComponentOptionUnselected: function($option) {
            $(".search-list-item-checkbox").removeAttr('checked').each(
                    function(index) {
                        tamboti.ddlcb.dropDownListCheckbox.unregisterExternalOption([$(this).attr("data-tamboti-record-id")]);
                    }
            );
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        },
        showComponentStatusMessage: true,
        componentStatusMessage: "$numberOfSelectedOptions of $maxNumberOfOptions record(s) selected"
    });

    // initialize the check boxes of the search list
    $(".search-list-item-checkbox").live("click", function(ev) {
        //ev.preventDefault();
        var $this = $(this);
        if ($this.is(":checked")) {

            tamboti.ddlcb.dropDownListCheckbox.registerExternalOption([$this.attr("data-tamboti-record-id")]);
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        } else {
            tamboti.ddlcb.dropDownListCheckbox.unregisterExternalOption([$this.attr("data-tamboti-record-id")]);
            var value = tamboti.ddlcb.dropDownListCheckbox.selectedOptionsIndex;
            $("#edit-action-form input").val(value.toString());
        }
    });

    $("#search-list-action").change(function() {
        var $this = $(this);
        if ($this.val() == "edit") {
            $("#edit-action-form").submit();
        } else {
            alert("This action is not yet implemented!");
        }
        $this.val("actions");
    });

    $("#splash").fadeOut(1000);

    // add event listener for sharing dialog. If closed: update selected node
    $("#sharing-collection-dialog").on("dialogclose", function( event, ui) {
        // ToDo: check for Sharing and add/remove class instead of refresh complete tree
        refreshParentTreeNode();
    });

});

/* collection action buttons */
function hideCollectionActionButtons() {
    $('#collection-create-folder').hide();
    $('#collection-rename-folder').hide();
    $('#collection-move-folder').hide();
    $('#collection-remove-folder').hide();
    $('#collection-sharing').hide();
    $('#collection-create-resource').hide();
    $('#remove-group-button').hide();
    $('#upload-file-to-resource').hide();
}

/* sharing dialog actions */
$(document).ready(function() {

    bindKeyPressActions();

    $('#clear-all').click(function() {
        var form = $('#advanced-search-form > form');
        form.find(':input').each(function() {
            switch (this.type) {
                case 'text':
                    $(this).val('');
                    break;
            }
        });
    });

    $('#clear-search-fields').click(function() {
        var form = $('#advanced-search-form > form');
        $("td.operator select option:first-child", form).each(function() {
            $(this).prop("selected", "selected");
        });
        $("td.search-term input.ui-autocomplete-input", form).each(function() {
            $(this).val('');
        });
        $("td.search-field select option:first-child", form).each(function() {
            $(this).prop("selected", "selected");
        });
    });

    $(".delete-search-field-button").click(function(ev) {
        ev.preventDefault();
        $(this).parent().parent().remove();
        return false;
    });

    $("td.search-term input").bind("keyup keypress", function(e) {
        var code = e.keyCode || e.which;
        if (code == 13) {
            e.preventDefault();
            tamboti.apis.advancedSearch();
            return false;
        }
    });

    $("#simple-search-form input[name='input1']").bind("keyup keypress", function(e) {
        var code = e.keyCode || e.which;
        if (code == 13) {
            e.preventDefault();
            tamboti.apis.simpleSearch();
            return false;
        }
    });

    $("#login-form input").bind("keyup keypress", function(e) {
        var code = e.keyCode || e.which;
        if (code == 13) {
            e.preventDefault();
            $('#login-form').submit();
            return false;
        }
    });

    bindAdditionalDialogTriggers();

    hideCollectionActionButtons();

    //prepareAttachmentSharingDetails();

    prepareCollectionSharingDetails();
    //attachment



    //add new user to share event
    $('#add-new-user-to-share-button').click(function() {
        //clear the textbox for user name
        $('#user-auto-list').val("");
        $('#add-user-to-share-dialog').dialog('open');
    });

    $('#add-user-to-share-button').click(function() {
        addUserToShare();
    });

    //add new project to share event
    $('#add-new-project-to-share-button').click(function() {
        //clear the textbox for project name
        $('#project-auto-list').val("");
        $('#add-project-to-share-dialog').dialog('open');
    });

    $('#add-project-to-share-button').click(function() {
        addProjectToShare();
    });
    emptyFileList();
    showNotices();
    $('a#upload-file-to-resource').click(function() {
        $('#upload-resource-id').empty();
        //$('#file-location-folder').empty();
        //var collection = getCurrentCollection();
        //$('#file-location-folder').val(collection);
    });

    tamboti.checkDuplicateSharingEntry = function(entryName, entryType) {
        var entries = $("#collectionSharingDetails tr[data-entry-type = '" + entryType + "'] td:nth-child(2)");
        var entriesString = " ";
        for (var i = 0, il = entries.length; i < il; i++) {
            entriesString += entries[i].textContent + " ";
        }
        if (entriesString.indexOf(" " + entryName + " ") != -1) {
            showMessage("Duplicate entry!");
            return true;
        }

        return false;
    };
});


function pingSession() {
    $.getJSON("check-session.xql", function(result) {
        if (result) {
            setTimeout(pingSession, 120000);
            $("#login-since").html(result);
        } else {
            $("#login-message").html("<a href=\"#\" id=\"login-link\">Login</a>");
        }
    });
}

function bindAdditionalDialogTriggers() {

    $("#collection-move-folder").click(function() {
        refreshCollectionMoveList();
    });


    $("#collection-create-folder").click(function() {
        $("#new-collection-name").val('');
    });

    $("#collection-rename-folder").click(function() {
        var node = $("#collection-tree-tree").fancytree("getActiveNode");
        if (node !== null) {
            $("#rename-new-name").val(node.title);
        }
    });
}

function bindKeyPressActions() {

    //login username, when enter is pressed, move to password
    $('#loginUsername').keyup(function(e) {
        if ($('#loginUsername').val() !== null && $('#loginUsername').val() !== "") {
            if (e.keyCode == 13) {
                $('#loginPassword').focus();
            }
        }
    });

    //login password, when enter is pressed, login
    $('#loginPassword').keyup(function(e) {
        if ($('#loginPassword').val() !== null && $('#loginPassword').val() !== "") {
            if (e.keyCode == 13) {
                login();
            }
        }
    });

    //new collection name, when enter is pressed, dont submit
    $('#create-collection-form').submit(function() {
        if ($('#new-collection-name').val() !== null && $('#new-collection-name').val() !== "") {
            createCollection($('#new-collection-dialog'));
        }
        return false;
    });

    //rename collection name, when enter is pressed, dont submit
    $('#rename-collection-form').submit(function() {
        if ($('#rename-new-name').val() !== null && $('#rename-new-name').val() !== "") {
            renameCollection($('#rename-collection-dialog'));
        }
        return false;
    });
}

function showNotices() {

    $('#notices-dialog').dialog({
        modal: true,
        width: 460,
        close: function(event, ui) {
            var params = {action: "seen-notices"};
            $.get("notices.xql", params, function(data) {
            });
        }
    });
}

/*
 Initialize the collection tree. Connect toolbar button events.
 */
function initCollectionTree() {
    var fancyTree = $('#collection-tree-tree');
    var treeDiv = $('#collection-tree-main').css('display', 'none');
    fancyTree.fancytree({
        debugLevel: 2,
        clickFolderMode: 1,
        autoFocus: false,
        fx: {
            height: "toggle", 
            duration: 200
        },
        // persist: true,
        source: {
            url: "collections.xql",
            data: {
            },
            type: "POST",
            addActiveKey: true, // add &activeKey= parameter to URL
            addFocusedKey: true, // add &focusedKey= parameter to URL
            addExpandedKeyList: true // add &expandedKeyList= parameter to URL
        },
        onActivate: function(dtnode) {
            /**
             Executed when a tree node is clicked
             */
            var title = dtnode.data.title;
            var key = dtnode.data.key;
            updateCollectionPaths(title, key);
            showHideCollectionControls();
        },
        lazyLoad: function(event, data) {
            var node = data.node;
            
            data.result = {
                url: "collections.xql",
                data: {
                    "key": node.key,
                },
                type: "POST"
            };
        },
        onPostInit: function() {
            // when tree is reloaded, reactivate the current node to trigger an onActivate event
            this.reactivate();
        },
        click: function(event, data) {
            var node = data.node;
            var title = node.title;
            var key = node.key;
            updateCollectionPaths(title, key);
            showHideCollectionControls();
        },
        dblclick: function(event, data) {
            var node = data.node;
            var title = node.title;
            var key = node.key;
            updateCollectionPaths(title, key);
            showHideCollectionControls();
            tamboti.apis.simpleSearch();
            return false;
        },
        collapse: function(event, data){
            data.node.resetLazy();
        }
    });

    toggleCollectionTree(true);
    var fancyTreeInstance = fancyTree.fancytree("getTree");

    
    // register click handles
    $('#toggle-collection-tree').click(function() {
        if (treeDiv.css('display') == 'none') {
            toggleCollectionTree(true);
        } else {
            toggleCollectionTree(false);
        }
    });
    $('#collection-expand-all').click(function() {
        // var activeNode = fancyTreeInstance.getActiveNode();
        fancyTreeInstance.getRootNode().visit(function(node) {
            node.setExpanded(true);
        });
        return false;
    });
    $('#collection-collapse-all').click(function() {
        fancyTreeInstance.getRootNode().visit(function(node) {
            node.setExpanded(false);
        });
        return false;
    });
    $('#collection-reload').click(function() {
        //reload the entire tree
        if (fancyTreeInstance) {
            fancyTreeInstance.reload();
        }
        return false;
    });
}

function toggleCollectionTree(show) {
    if (show) {
        $('#collection-tree').css({width: '310px', height: 'auto', 'background-color': 'transparent'});
        $('#main-content').css('margin-left', '320px');
        $('#collection-tree-main').css('display', '');
        $('#simple-search-form input[name = collection-tree]').val('show');
        $('#advanced-search-form input[name = collection-tree]').val('show');
    } else {
        $('#collection-tree').css({width: '40px', height: '450px', 'background-color': '#EDEDED'});
        $('#main-content').css('margin-left', '50px');
        $('#collection-tree-main').css('display', 'none');
        $('#simple-search-form input[name = collection-tree]').val('hidden');
        $('#advanced-search-form input[name = collection-tree]').val('hidden');
    }
}

function updateCollectionPaths(title, key) {
    key = key.replace(/^\/db/, "");

    $("#simple-search-form input[name = collection]").val(key);
    $("#advanced-search-form input[name = collection]").val(key);

    //search forms
    updateCollectionPathOutputs(key);

    //dialog collection paths
    $('span[id $= collection-path_]').text(title);
    $('input[id $= collection-path_]').val(key);

    // $('#collection-create-resource').attr("href", "../edit/edit.xq?type=book-chapter&collection=" + key);
}

function getCurrentCollection() {
    return "/db" + $("#simple-search-form input[name = collection]").val();
}

function updateCollectionPathOutputs(collectionPath) {
    collectionPath = collectionPath.replace(/^\//, "").replace(/\/commons\//, "/").replace(/\/users\//, "/");
    $("#simple-search-form input[name = 'render-collection-path']").val(collectionPath);
    $("#advanced-search-form input[name = 'render-collection-path']").val(collectionPath);
}

function showHideCollectionControls() {
    var collection = getCurrentCollection();

    var params = {action: "collection-relationship", collection: collection};
    $.post("checkuser.xql", params, function(data) {

        /**
         data looks like this -
         
         <relationship user="" collection="">
            <home/>
            <owner/>
            <read/>
            <write/>
            <execute/>
            <read-parent/>
            <write-parent/>
            <execute-parent/>
         </relationship>
         */

        var write = $(data).find('write');
        var isWriteable = (write !== null && write.text() == 'true');

        var execute = $(data).find('execute');
        var isExecutable = (execute !== null && execute.text() == 'true');

        var home = $(data).find('home');
        var isUsersHome = (home !== null && home.text() == 'true');

        var owner = $(data).find('owner');
        var isOwner = (owner !== null && owner.text() == 'true');

        var parentWrite = $(data).find('write-parent');
        var isParentWriteable = (parentWrite !== null && parentWrite.text() == 'true');

        var parentExecute = $(data).find('execute-parent');
        var isParentExecutable = (parentExecute !== null && parentExecute.text() == 'true');
        //collection is writeable
        if (isWriteable) {
            $('#collection-create-folder').show();
            $('#collection-create-resource').show();
            if (!isUsersHome) {
                $('#upload-file-to-resource').show();
            }
            else {
                $('#upload-file-to-resource').hide();
            }
        } else {
            $('#collection-create-folder').hide();
            $('#collection-create-resource').hide();
            $('#upload-file-to-resource').hide();
        }

        //collection is not current users home and is owned by current user
        if (!isUsersHome && isExecutable && isWriteable) {
            $('#collection-sharing').show();
        } else {
            $('#collection-sharing').hide();
        }

        // moving and renaming needs parentCollection to be writeable and executable
        if (isParentWriteable && isParentExecutable && !isUsersHome) {
            $('#collection-rename-folder').show();
            $('#collection-move-folder').show();
            //$('#upload-file-to-resource').show();
        } else {
            $('#collection-rename-folder').hide();
            $('#collection-move-folder').hide();
            //$('#upload-file-to-resource').hide();
        }

        //parent is writeable and executable and its not the current users home folder
        if (isParentWriteable && isParentExecutable && !isUsersHome) {
            $('#collection-remove-folder').show();
            //$('#upload-file-to-resource').show();
        } else {
            $('#collection-remove-folder').hide();
            //$('#upload-file-to-resource').hide();
        }
    });
}

/*
 Called when the user clicks on the "remove" button in the remove resource dialog
 */
function removeResource(dialog) {
    var resource = $('#remove-resource-form input[name = resource]').val();
    var params = { action: 'remove-resource', 
            resource: resource,
            uuid : $('#remove-resource').attr('id')
    };
    $.get("operations.xql", params, function(data) {
        dialog.dialog("close");
        $(location).attr('href', 'index.html?reload=true&collection=' + getCurrentCollection());
    });
}

function refreshResourceMoveList() {

//  var collection = getCurrentCollection();
    var collection = "/" + $('#file-location-folder').html();
    // console.debug($('#file-location-folder').html());

    //set the current collection on the form
    $("#move-resource-collection-path-label").html(collection);
    $("#move-resource-collection").val(collection);

    //get the destination collection options
    var params = {
        action: 'get-move-resource-list',
        collection: collection
    };
    $.get("operations.xql", params, function(data) {

        //clear the list
        $("#resource-move-destinations").find("option").remove();

        $("option", data).each(function() {
            $("#resource-move-destinations").append("<option value='" + $.trim($(this).attr("value")) + "'>" + $.trim($(this).text()) + "</option>");
        });
    });
}



/*
 * called when the user  clicks the add attachment button
 */
function emptyFileList() {
    //  $('#file-list').empty();

}

/*
 Called when the user clicks on the "move" button in the move resource dialog
 */
function moveResource(dialog) {
    var path = $('#move-resource-form select[name = path]').val();
    var resource = $('#move-resource-form input[name = resource]').val();
    var resource_type = $('#record-format').html();
    var source_collection = "/" + $('#file-location-folder').html();
    var params = {
            action: 'move-resource',
            path: path,
            resource: resource,
            source_collection: source_collection,
            resource_type:resource_type
    };
    $.get("operations.xql", params, function(data) {
        dialog.dialog("close");
    });
}

/*
 Called when the user clicks on the "create" button in the create collection dialog.
 */
function createCollection(dialog) {
    var name = $("#new-collection-name").val();
    var collection = getCurrentCollection();
//    console.log(collection);
    var params = {
        action: 'create-collection', 
        name: name, 
        collection: collection
    };
    
    $.ajax({
        url: "operations.xql",
        data: {
            action: 'create-collection', 
            name: name, 
            collection: collection
        },
        type: 'POST',
        success:
                function(data, message) {
                    //reload the tree node
                    refreshCurrentTreeNode();
                    var node = $("#collection-tree-tree").fancytree("getActiveNode");
                    node.setExpanded();
                },
        error: function(response, message) {
            // alert("creating collection failed!")
            //ToDo: Popup when creating Collection failed
            showMessage('Creating collection failed: ' + response.responseText);
        }
    });

    //close the dialog
    dialog.dialog("close");
}

//refreshes the tree node
function refreshTreeNode(node) {
    if (node) {
        node.resetLazy();
        node.setExpanded(true);
    }
}


//refreshes the tree node
function refreshTreeNodeAndFocusOnChild(node, focusOnKey) {
    if (node) {
        refreshTreeNode(node);
        $(node.children).each(function() {
            if (this.key == focusOnKey) {
                this.activate();
            }
        });
    }
}

//refreshes the currently selected tree node
function refreshCurrentTreeNode() {
    var node = $("#collection-tree-tree").fancytree("getActiveNode");
    refreshTreeNode(node);
}

//refreshes the parent of the currently selected tree node
function refreshParentTreeNode() {
    //reload the parent tree node
    var parentNode = $("#collection-tree-tree").fancytree("getActiveNode").getParent();
    refreshTreeNode(parentNode);
    parentNode.setExpanded(true); //expand the node after reloading the children
}

function refreshParentTreeNodeAndFocusOnChild(focusOnKey) {
    //reload the parent tree node

    //find parent of the key to focus on
    var parentFocusKey = focusOnKey.replace(/(.*)\/.*/, "$1");
    var tree = $("#collection-tree-tree").fancytree("getTree");
    var parentNode = tree.getNodeByKey(parentFocusKey);

    refreshTreeNodeAndFocusOnChild(parentNode, focusOnKey);
    parentNode.setExpanded(true); //expand the node after reloading the children
}



//called each time the collection/folder sharing dialog is opened
function updateFileList() {
    $('#uploadFileList').dataTable().fnReloadAjax("filelist.xql?collection=" + escape(getCurrentCollection()));
}

/*
 Called when the user clicks on the "rename" button in the rename collection dialog.
 */
function renameCollection(dialog) {
    var name = $('#rename-collection-form input[name = name]').val();
    var collection = getCurrentCollection();

    $.ajax({
        url: "operations.xql",
        data: {
            action: 'rename-collection',
            name: name, 
            collection: collection
        },
        type: 'POST',
        success:
            function(data, message) {
                //current node
                var currentNode = $("#collection-tree-tree").fancytree("getActiveNode");
                var currentNodeKey = currentNode.key;
                currentNode.setTitle(name);
                currentNode.key = currentNodeKey.substring(0, currentNodeKey.lastIndexOf("/") + 1) + name;
                refreshCurrentTreeNode();
                //If it has children, trigger reload to regenerate keys with new name
                //ToDo: add recursive change child-keys to avoid reloading
                
            },
        error: function(response, message) {
            showMessage('Creating collection failed: ' + response.responseText);
        }
    });

    //close the dialog
    dialog.dialog("close");
}

function refreshCollectionMoveList() {
    var node = $("#collection-tree-tree").fancytree("getActiveNode");
    if (node !== null) {
        var selectedCollection = node.key;
        //clear the list
        $("#collection-move-destinations").find("option").remove();
        $.ajax({
            url: "operations.xql",
            data: {
                action: 'get-move-folder-list', 
                collection: selectedCollection
            },
            type: 'POST',
            success: function(data, message) {
                $("option", data).each(function() {
                    $("#collection-move-destinations").append("<option value='" + $.trim($(this).attr("value")) + "'>" + $.trim($(this).text()) + "</option>");
                });
            },
            error: function(response, message) {
            }
        });
    }
}

/*
 Called when the user clicks on the "move" button in the move collection dialog.
 */
function moveCollection(dialog) {
    var path = $('#move-collection-form select[name = path]').val();
    var collection = getCurrentCollection();
    $.ajax({
        url: "operations.xql",
        data: {
            action: 'move-collection', 
            path: path, 
            collection: collection
        },
        type: 'POST',
        success: function(data, message) {
            var currentNode = $("#collection-tree-tree").fancytree("getActiveNode");
            var ft = $("#collection-tree-tree").fancytree("getTree");
            // var currentKey = currentNode.key;
    
            //new key
            // var newKey = $("#collection-tree-tree").fancytree("getActiveNode").getParent().key;
            
            var newCollection = $('#collection-move-destinations option:selected').text();
            var newNode = ft.getNodeByKey(newCollection);
            
            console.debug(newNode);

            //remove the former node
            currentNode.remove();
            //reload the destination node
            newNode.load(true);
            newNode.setExpanded(true);
            // refreshTreeNode(newNode);
            // newNode.setEx
        },
        error: function(response, message) {
            showMessage('Moving collection failed: ' + response.responseText);
        }
    });

    //close the dialog
    dialog.dialog("close");
}

/*
 Called when the user clicks on the "remove" button in the remove collection dialog.
 */
function removeCollection(dialog) {
    var collection = getCurrentCollection();
    $.ajax({
        url: "operations.xql",
        data:{ 
            action: 'remove-collection', 
            collection: collection 
        },
        type: 'POST',
        success:
            function(data, message) { 
                //reload the parent tree node
                refreshParentTreeNode();
               
            },
        error: 
            function (response, message) { 
                showMessage('Creating collection failed: ' + response.responseText);
            }
    });
    //close the dialog
    dialog.dialog("close");
}

/**
 * Called after the user clicked "Login" on the login form.
 * Checks if the supplied credentials are valid. If yes, submit
 * the form to reload the page.
 */
function login() {
    var user = $('#login-dialog input[name = user]');
    var password = $('#login-dialog input[name = password]');
    $('#login-message').text('Checking ...');
    $.ajax({
        url: "checkuser.xql",
        data: {
            user: user.val(),
            password: escape(password.val())
        },
        type: 'POST',
        success:
                function(data, message) {
                    $('#login-form').submit();
                },
        error: function(response, message) {
            showMessage('Login failed: ' + response.responseText);
        }
    });
}

function newResource() {
    var collection = getCurrentCollection();
    $("#new-resource-form input[name = collection]").val(collection);
    $("#new-resource-form").submit();
}

function newRelatedResource() {
    var collection = getCurrentCollection();
    $("#add-related-form input[name = collection]").val(collection);
    $("#add-related-form").submit();
}

/**
 * Called from the create indexes dialog if the user clicks on "Start".
 */
function createIndexes() {
    var pass = $('#optimize-dialog input[name = password]');
    $('#optimize-message').text('Running ...');
    $.get('optimize.xql?pass=' + pass.val(),
            function(data, status) {
                if (status != "success")
                    $('#optimize-message').text('Error during optimize!');
                else
                    $('#optimize-dialog').dialog("close");
            });
}

function loadIndexTerms() {
    var input = $('input[name = input-keyword-prefix]');
    $('#keywords-result').load("filters.xql?type=keywords&prefix=" + input.val(), function() {
        if ($('#keywords-result ul').hasClass('complete'))
            $('#keyword-form').css('display', 'none');
    });
}

function autocompleteCallback(node, params) {
    params.collection = getCurrentCollection();

    var name = node.attr('name');
    var select = node.parent().parent().find('select[name ^= field]');
    if (select.length == 1) {
        params.field = select.val();
    }
}

function repeatCallback() {
    var input = $('input[name ^= input]', this);
    input.autocomplete({
        source: function(request, response) {
            var data = {term: request.term};
            autocompleteCallback(input, data);
            $.ajax({
                url: "autocomplete.xql",
                dataType: 'json',
                type : 'POST',
                data: data,
                success: function(data) {
                    response(data);
                }});
        },
        minLength: 3
    });

    $('select[name ^= operator]', this).each(function() {
        $(this).css('display', '');
    });
}

function saveToPersonalList(anchor) {
    var img = $('img', anchor);
    var pos = anchor.hash.substring(1);
    if (img.hasClass('stored')) {
        var id = anchor.id;
        img.removeClass('stored');
        img.attr('src', 'theme/images/disk.gif');
        $.get('user.xql', {list: 'remove', id: id});
    } else {
        img.attr('src', 'theme/images/disk_gew.gif');
        img.addClass('stored');
        $.get('user.xql', {list: 'add', pos: pos});
    }
    $('#personal-list-size').load('user.xql', {action: 'count'});
    return false;
}

function resultsLoaded(options) {
    if (options.itemsPerPage > 1) {
        $('tbody > tr:even > td', this).addClass('even');
        $(".pagination-mode", $(options.navContainer)).show();
    } else {
        $(".pagination-mode", $(options.navContainer)).hide();
    }
    var tallest = 0;
    $("#results li").each(function() {
        if ($(this).height() > tallest) {
            tallest = $(this).height();
        }
    });
    $("#results li").each(function() {
        $(this).height(tallest);
    });
    $('#filters').css('display', 'block');
    $('#filters .include-target').empty();
    $('#filters .expand').removeClass('expanded');

    // trigger image viewer when user clicks on thumbnail
    $("#results .detail-xml .magnify").click(function(ev) {
        ev.stopPropagation();
        var num = $(this).closest(".pagination-item").find(".pagination-number").text();
        if (num) {
            galleries.open();
            galleries.show(parseInt(num));
        }
    });

    //detail view
    $('.actions-toolbar .save', this).click(function(ev) {
        saveToPersonalList(this);
    });

    //list view
    $('.actions-cell .save', this).click(function(ev) {
        saveToPersonalList(this);
    });

    /** add remove resource action */
    $('.actions-toolbar .remove-resource', this).click(function(ev) {
        ev.preventDefault();
        $('#remove-resource-id').val($(this).attr('href').substr(1));
        $('#remove-resource-dialog').dialog('open');
    });

    /** add move resource action */
    $('.actions-toolbar .move-resource', this).click(function() {
        $('#move-resource-id').val($(this).attr('href').substr(1));
        var collection = getCurrentCollection();
        $("#move-resource-collection-path").val(collection);        
        refreshResourceMoveList();
        $('#move-resource-dialog').dialog('open');
        return false;
    });

    $('.actions-toolbar .add-related', this).click(function(ev) {
        ev.preventDefault();
        var params = this.hash.substring(1).split('#');
        $('#add-related-form input[name = collection]').val(params[0]);
        $('#add-related-form input[name = host]').val(params[1]);
        $('#add-related-dialog').dialog('open');

    });

    /**  add upload action*/
    $('.actions-toolbar .upload-file-style', this).click(function(ev) {
        ev.preventDefault();
        $('#upload-resource-id').html($(this).attr('href').substr(1));
        $('#file-upload-folder').empty();
        var collection = getCurrentCollection();
        $('#upload-resource-folder').html(collection);
        //clean old  files
        emptyFileList();
        $('#upload-file-dialog').dialog('open');


    });

    //notify zotero that the dom has changed
    if (document.createEvent) {
        var ev = document.createEvent('HTMLEvents');
        ev.initEvent('ZoteroItemUpdated', true, true);
        document.dispatchEvent(ev);
    }
}

function searchTabSelected(ev, ui) {
    if (ui.index == 3) {
        $('#personal-list-size').load('user.xql', {action: 'count'});
    }
}

//collection sharing dialog initialisation code
function prepareCollectionSharingDetails() {

    //add reloadAjax function
    $.fn.dataTableExt.oApi.fnReloadAjax = dataTableReloadAjax;

    //initialise with initial data
    $('#collectionSharingDetails').dataTable({
        "bProcessing": true,
        "sPaginationType": "full_numbers",
        "fnRowCallback": collectionSharingDetailsRowCallback,
        "sAjaxSource": "sharing.xql",
        "bFilter": false

    });
}

function prepareAttachmentSharingDetails() {
    //add reloadAjax function
    $.fn.dataTableExt.oApi.fnReloadAjax = attachedDataTableReloadAjax;


    //initialise with initial data
    $('#attachedFilesDetails').dataTable({
        "bProcessing": true,
        "sPaginationType": "full_numbers",
        "fnRowCallback": attachedDetailsRowCallback,
        "sAjaxSource": "sharing.xql",
        "bDestroy": true,
        "bFilter": false

    });
}


function attachedDetailsRowCallback(nRow, aData, iDisplayIndex) {
    //determine user or group icon for first column
    var img_src = aData[0];
    $('td:eq(0)', nRow).html('<img alt="User Icon" src="' + img_src + '" width="100px"/>');

    /*else if(aData[0] == "GROUP") {
     $('td:eq(0)', nRow).html('<img alt="Group Icon" src="theme/images/group.png"/>');
     }
     */

    //determine writeable for fourth column
    //var isWriteable = aData[3].indexOf("w") > -1;
    //add the checkbox, with action to perform an update on the server
    //var inpWriteableId = 'inpWriteable_' + iDisplayIndex;
    //$('td:eq(3)', nRow).html('<input id="' + inpWriteableId + '" type="checkbox" value="true"' + (isWriteable ? ' checked="checked"' : '') + ' onclick="javascript: setAceWriteable(this,\'' + getCurrentCollection() + '\',' + iDisplayIndex + ', this.checked);"/>');

    //add a delete button, with action to perform an update on the server
    //var imgDeleteId = 'imgDelete_' + iDisplayIndex;
    //$('td:eq(4)', nRow).html('<img id="' + imgDeleteId + '" alt="Delete Icon" src="theme/images/cross.png" onclick="javascript: removeAce(\'' + getCurrentCollection() + '\',' + iDisplayIndex + ');"/>');
    //add jQuery cick action to image to perform an update on the server

    return nRow;
}

//called each time the collection/folder sharing dialog is opened
function updateSharingDialog() {
    $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(getCurrentCollection()));

}


function updateAttachmentDialog() {
    /**
     var oTable = $('#attachedFilesDetails').dataTable();
     oTable.fnClearTable();
     */
    var uuid = $('#upload-resource-id').html();
    if (uuid.length > 0) {
        $('#attachedFilesDetails').dataTable().fnReloadAjax("sharing.xql?file=" + uuid);
    }
    else
    {
        var collection = encodeURI(getCurrentCollection());
        $('#file-upload-folder').text(collection);
        //$('#attachedFilesDetails').dataTable().fnReloadAjax("sharing.xql?upload-folder="+escape(collection));
    }
}


//custom fnReloadAjax for sharing dataTable
function dataTableReloadAjax(oSettings, sNewSource, fnCallback, bStandingRedraw) {
    if (typeof sNewSource != 'undefined' && sNewSource !== null) {
        oSettings.sAjaxSource = sNewSource;
    }
    this.oApi._fnProcessingDisplay(oSettings, true);
    var that = this;
    var iStart = oSettings._iDisplayStart;
    oSettings.fnServerData(oSettings.sAjaxSource, [], function(json) {

        /* Clear the old information from the table */
        that.oApi._fnClearTable(oSettings);

        if (json) {
            for (var i = 0; i < json.aaData.length; i++) {
                that.oApi._fnAddData(oSettings, json.aaData[i]);
            }
        }

        oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
        that.fnDraw();

        if (typeof bStandingRedraw != 'undefined' && bStandingRedraw === true) {
            oSettings._iDisplayStart = iStart;
            that.fnDraw(false);
        }

        that.oApi._fnProcessingDisplay(oSettings, false);

        /* Callback user function - for event handlers etc */
        if (typeof fnCallback == 'function' && fnCallback !== null) {
            fnCallback(oSettings);
        }
    }, oSettings);
}

function attachedDataTableReloadAjax(oSettings, sNewSource, fnCallback, bStandingRedraw) {
    if (typeof sNewSource != 'undefined' && sNewSource !== null) {
        oSettings.sAjaxSource = sNewSource;
    }

    this.oApi._fnProcessingDisplay(oSettings, true);

    var that = this;
    var iStart = oSettings._iDisplayStart;

    oSettings.fnServerData(oSettings.sAjaxSource, [], function(json) {

        /* Clear the old information from the table */
        that.oApi._fnClearTable(oSettings);

        /* Got the data - add it to the table */

        if (json) {
            for (var i = 0; i < json.aaData.length; i++) {
                var t = json.aaData[i].items;
                if (t !== null) {
                    for (var j = 0; j < t.length; j++) {
                        //if (t[j].name.indexOf(".xml") == -1){ // check if the file is binary
                        var values = [t[j].collection, t[j].name, t[j].lastmodified];
                        that.oApi._fnAddData(oSettings, values);

                    }
                }
            }
        }

        oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
        that.fnDraw();

        if (typeof bStandingRedraw != 'undefined' && bStandingRedraw === true) {
            oSettings._iDisplayStart = iStart;
            that.fnDraw(false);
        }

        that.oApi._fnProcessingDisplay(oSettings, false);

        /* Callback user function - for event handlers etc */
        if (typeof fnCallback == 'function' && fnCallback !== null) {
            fnCallback(oSettings);
        }
    }, oSettings);
}


//custom rendered for each row of the sharing dataTable
function collectionSharingDetailsRowCallback(nRow, aData, iDisplayIndex) {
    //add attribute defining the entry type
    $(nRow).attr("data-entry-type", aData[0]);
    //determine user or group icon for first column
    if (aData[0] == "USER") {
        $('td:eq(0)', nRow).html('<img alt="User Icon" src="theme/images/user.png"/>');
    } else if (aData[0] == "GROUP") {
        $('td:eq(0)', nRow).html('<img alt="Group Icon" src="theme/images/group.png"/>');
    }

    //determine writeable for fifth column
    var isWriteable = aData[4].indexOf("w") > -1;
    //add the checkbox, with action to perform an update on the server
    var inpWriteableId = 'inpWriteable_' + iDisplayIndex;
    $('td:eq(4)', nRow).html('<input id="' + inpWriteableId + '" type="checkbox" value="true"' + (isWriteable ? ' checked="checked"' : '') + ' onclick="javascript: setAceWriteableByName(this,\'' + getCurrentCollection() + '\',\'' + aData[0] + '\',\'' + aData[2] + '\', this.checked);"/>');    

    //add a delete button, with action to perform an update on the server
    var imgDeleteId = 'imgDelete_' + iDisplayIndex;
    $('td:eq(5)', nRow).html('<img id="' + imgDeleteId + '" alt="Delete Icon" src="theme/images/cross.png" onclick="javascript: removeAceByName(\'' + getCurrentCollection() + '\',\'' + aData[0] + '\',\'' + aData[2] + '\');"/>');
    //add jQuery cick action to image to perform an update on the server

    return nRow;
}

//sets an ACE on a share to writeable or not
function setAceWriteable(checkbox, collection, aceId, isWriteable) {
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: "action=set-ace-writeable&collection=" + escape(collection) + "&id=" + aceId + "&is-writeable=" + isWriteable,
        success: function(data, status, xhr) {
            //do nothing
        },
        error: function(xhr, status, error) {
            showMessage("Could not modify entry");
            checkbox.checked = !isWriteable;
        }
    });
}

//sets an ACE by type/name on a share to writeable or not
function setAceWriteableByName(checkbox, collection, target, name, isWriteable) {
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "set-ace-writeable-by-name",
            collection: collection,
            target: target,
            name:  name,
            'is-writeable': isWriteable
        },
        success: function(data, status, xhr) {
            //do nothing
        },
        error: function(xhr, status, error) {
            showMessage("Could not modify entry");
            checkbox.checked = !isWriteable;
        }
    });
}

//removes an ACE from a share
function removeAce(collection, aceId) {
    if (confirm("Are you sure you wish to remove this entry?")) {
        $.ajax({
            type: 'POST',
            url: "operations.xql",
            data: "action=remove-ace&collection=" + escape(collection) + "&id=" + aceId,
            success: function(data, status, xhr) {
                //remove from dataTable
                $('#collectionSharingDetails').dataTable().fnDeleteRow(aceId);
            },
            error: function(xhr, status, error) {
                showMessage("Could not remove entry");
                checkbox.checked = !isWriteable;
            }
        });
    }
}

//removes an ACE by user-/group name from a share
function removeAceByName(collection, target, name) {
    if(confirm("Are you sure you wish to remove this entry?")){
        $.ajax({
            type: 'POST',
            url: "operations.xql",
            data: { 
                action: "remove-ace-by-name",
                collection: collection,
                target: target,
                name:  name
            },
            success: function(data, status, xhr) {
                //reload dataTable
                $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(getCurrentCollection()));
            },
            error: function(xhr, status, error) {
                showMessage("Could not remove entry");
                checkbox.checked = !isWriteable;
            }
        });
    }
}

//adds a user to a share
function addUserToShare() {
    //check if this is a duplicate user
    var input_value = $('#user-auto-list').val();
    var username_no_parenthesis = $('#user-auto-list').val().match( /\(.*\)/ );
    var username = "";
    if (username_no_parenthesis !== null)
        username = username_no_parenthesis[0].substring(1, username_no_parenthesis[0].length-1);
    else
        username = input_value;
    
    if (tamboti.checkDuplicateSharingEntry(username, "USER")) {
        return;
    }
    //check this is a valid user otherwise show error
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "is-valid-user-for-share",
            username: escape(username)
        },
        success: function(data, status, xhr) {

            //2) create the ace on the server
            $.ajax({
                type: 'POST',
                url: "operations.xql",
                data: { 
                    action: "add-user-ace",
                    collection: getCurrentCollection(),
                    username: escape(username)
                },
                success: function(data, status, xhr) {
                    //3) reload dataTable
                    //$('#collectionSharingDetails').dataTable().fnAddData(["USER", $('#user-auto-list').val(), "ALLOWED", "r--", $(data).find("status").attr("ace-id")]);
                    $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(getCurrentCollection()));

                    //4) close the dialog
                    $('#add-user-to-share-dialog').dialog('close');
                    //(5) go to the last page
                    //$('#collectionSharingDetails').dataTable().fnPageChange("last");
                },
                error: function(xhr, status, error) {
                    showMessage("Could not create entry");
                }
            });
        },
        error: function(xhr, status, error) {
            showMessage("The user '" + $('#user-auto-list').val() + "' does not exist!");
        }
    });
    $('#user-auto-list').val('');    
}

//adds a group to a share
function addProjectToShare() {
    //check if this is a duplicate user
    if (tamboti.checkDuplicateSharingEntry($("#project-auto-list").val(), "GROUP")) {
        return;
    }
    //1) check this is a valid group otherwise show error
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "is-valid-group-for-share",
            groupname: escape($('#project-auto-list').val())
        },        
        success: function(data, status, xhr) {

            //2) create the ace on the server
            $.ajax({
                type: 'POST',
                url: "operations.xql",
                data: { 
                    action: "add-group-ace",
                    collection: getCurrentCollection(),
                    groupname: escape($('#project-auto-list').val())
                },
                success: function(data, status, xhr) {
                    //3) reload dataTable
//                  $('#collectionSharingDetails').dataTable().fnAddData(["GROUP", $('#project-auto-list').val(), "ALLOWED", "r--", $(data).find("status").attr("ace-id")]);
                    $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(getCurrentCollection()));

                    //4) close the dialog
                    $('#add-project-to-share-dialog').dialog('close');
                    //(5) go to the last page
                    //$('#collectionSharingDetails').dataTable().fnPageChange("last");
                },
                error: function(xhr, status, error) {
                    showMessage("Could not create entry");
                }
            });
        },
        error: function(xhr, status, error) {
            showMessage("The project '" + $('#project-auto-list').val() + "' does not exist!");
        }
    });
}

// Function for show a simple message
function showMessage(message){
    // ToDo: use Tamboti internal dialog instead of JS alert 
    //$('#message').html(message);
    alert(message);
}