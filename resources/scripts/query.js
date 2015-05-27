tamboti = {};

tamboti.utils = {};
tamboti.browser = {};

tamboti.browser.chrome = (typeof window.chrome === "object");

tamboti.selectedSearchResultOptions = {};

tamboti.createGuid = function() {
	return 'xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
		var r = Math.random()*16|0, v = c === 'x' ? r : (r&0x3|0x8);
		return v.toString(16);
	});
};

// Add a hidden span with status display on 
function addStatusDisplay(selector){
    selector.append('<span class="result"> \
                        <image class="progress" style="height:2em;vertical-align:bottom;display:none;" src="theme/images/ajax-loader.gif"/> \
                        <image class="success" style="height:2em;vertical-align:bottom;display:none;" src="theme/images/task-complete.png"/> \
                    </span>');
    selector.bind('showLoading', function(){
        selector.find('span.result img.progress').show();
    });
    selector.bind('showDone', function(){
        selector.find('span.result img.progress').fadeOut( "fast", function() {
            selector.find('span.result img.success').fadeIn("slow").delay( 800 ).fadeOut("slow");
        });
    });
}

// get roles for sharing defined in config.xml
tamboti.shareRoles = {};
tamboti.shareRoles.options = [];
$.ajax({
    url: "operations.xql",
        dataType: "json",
        data: {
            action: 'getSharingRoles'
        },
        type: 'POST',
        success: function(data, message) {
            tamboti.shareRoles = data;
        },
        error: function(response, message) {
        }
    });

$(function() {
    $('#keyword-form').submit(function() {
        loadIndexTerms();
        return false;
    });
    
    $("#simple-search-form").on("submit", function(){
        sessionStorage.setItem("tamboti.simple-search-term", $("#simple-search-form input[name = 'input1']").val());
    });
    
    $("#simple-search-form input[name = 'input1']").val(sessionStorage.getItem("tamboti.simple-search-term"));    

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

    $("#splash").fadeOut(1000);

    // add event listener for sharing dialog. If closed: update selected node
    $("#sharing-collection-dialog").on("dialogclose", function( event, ui) {
        // ToDo: check for Sharing and add/remove class instead of refresh complete tree
        refreshParentTreeNode();
    });
    
    $("#results").on("mouseover", "td.list-image", function() {
        $(this).qtip({
              content: function() {
                var element = $(this);
                var record = element.closest("tr").find("div[class $= '-record']");
                var recordType = record.attr("class").replace("-record", "");
                var caption = record.html();
                
                return $("<div class='" + recordType + "-record'>" + caption + "</div>");
              },
              position: {
                      my: 'top left',
                      at: 'bottom right'
                  },            
          //     position: {
      	   // 	target: 'mouse',
      	   //     adjust: { x: 5, y: 5 }           
          //     },          
              show: {
               ready: true
              },
      	    style: {
      	        classes: 'qtip-light'
      	    }            
        });
      });    

      $("#results").on("mouseover", "td.list-image > *", function() {
        $(this).qtip({
              content: function() {
                var element = $(this);

                if (element.is("img")) {
                    var src = element.attr("src");
                    return $("<img class='image-tooltip' alt='" + element.attr("alt") + "' src='" + src + "' />");    
                }
                
                if (element.is("svg")) {
                    //alert("<svg xmlns='http://www.w3.org/2000/svg' height='300' width='300' viewBox='323.526 442.775 425.197 425.197'>" + $(this).html() + "</svg>");
                    return $("<svg xmlns='http://www.w3.org/2000/svg' height='300' width='300' viewBox='323.526 442.775 425.197 425.197'>" + $(this).html() + "</svg>");
                }
                
              },
              position: {
                      my: 'bottom left',
                      at: 'top right'
                  },    
          //     position: {
      	   // 	target: 'mouse',	    
      	   //     adjust: { x: 5, y: 5 }
          //     },          
              show: {
              ready: true
              },
            style: {
              classes: 'qtip-light'
            }
        });
      });

  // $("#results table").tooltip({
//       items: "td.list-image a img",
//       content: function() {
//           var element = $(this);
//           var src = element.attr("src");
          
//           return $("<img class='image-tooltip' alt='" + element.attr("alt") + "' src='" + src + "' />");
//       },
//       position: {
//           my: "left+15 bottom-15",
//           at: "right top",
//           collision: 'flipfit'
//       },
//       track: true
  // });

  // $("#results").tooltip({
//           items: "td.list-image a",    
//         content: function() {
//           var element = $(this);
//           var caption = element.closest("tr").find("div.vra-record").html();
          
//           return $("<div class='vra-record'>" + caption + "</div>");
//         },
//         position: {
//           my: "left+15 bottom+170",
//           at: "right bottom",
//           collision: 'flipfit'
//         },
//         track: true
//       });         

});

/* Initialize JS functionality (i.e. bind click actions) */
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
    	tamboti.utils.resetAdvancedSearchForm();
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

    /********* BIND FANCYTREE TOOLBAR  BUTTONS ***************/
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
    
//     $("#collection-tree-tree").contextmenu({
//       delegate: "span.fancytree-title",
// //      menu: "#options",
//       menu: [
//           {title: "Cut", cmd: "cut", uiIcon: "ui-icon-scissors"},
//           {title: "Copy", cmd: "copy", uiIcon: "ui-icon-copy"},
//           {title: "Paste", cmd: "paste", uiIcon: "ui-icon-clipboard", disabled: false },
//           {title: "----"},
//           {title: "Edit", cmd: "edit", uiIcon: "ui-icon-pencil", disabled: true },
//           {title: "Delete", cmd: "delete", uiIcon: "ui-icon-trash", disabled: true },
//           {title: "More", children: [
//             {title: "Sub 1", cmd: "sub1"},
//             {title: "Sub 2", cmd: "sub1"}
//             ]}
//           ],
//       beforeOpen: function(event, ui) {
//         var node = jQuery.ui.fancytree.getNode(ui.target);
// //                node.setFocus();
//         node.setActive();
//       },
//       select: function(event, ui) {
//         var node = jQuery.ui.fancytree.getNode(ui.target);
//         alert("select " + jQuery.ui.cmd + " on " + node);
//       }
//     });

    
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

function updateCollectionPaths(title, key) {
    // key = key.replace(/^\/db/, "");

    $("#simple-search-form input[name = collection]").val(key);
    $("#advanced-search-form input[name = collection]").val(key);
    
    //dialog collection paths
    $('span[id $= collection-path_]').text(title);
    $('input[id $= collection-path_]').val(key);

    // $('#collection-create-resource').attr("href", "../edit/edit.xq?type=book-chapter&collection=" + key);
}

function getCurrentCollection() {
    return "/db" + $("#simple-search-form input[name = collection]").val();
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

/**
 * Called after the user clicked "Login" on the login form.
 * Checks if the supplied credentials are valid. If yes, submit
 * the form to reload the page.
 */
function login(dialog) {
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
        			$.ajax({
        				url: "index.html",
        				data: "user=" + user.val() + "&password=" + escape(password.val()),
        				type: 'POST',
        				success: function(data, message) {
        					location.reload();
        				}
        			});
                },
        error: function(response, message) {
            showMessage('Login failed: ' + response.responseText);
        }
    });
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
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");

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
        var collection = $('#file-location-folder').html();
        ev.preventDefault();
        $('#upload-resource-id').html($(this).attr('href').substr(1));
        $('#file-upload-folder').empty();
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

// Function for show a simple message
function showMessage(message){
    // ToDo: use Tamboti internal dialog instead of JS alert 
    //$('#message').html(message);
    alert(message);
}


// *****************************************************************************
// *            FANCY TREE FUNCTIONS
// *****************************************************************************
/* Initialize the collection tree. Connect toolbar button events. */
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
            tamboti.utils.resetSimpleSearchForm();
            tamboti.utils.resetAdvancedSearchForm();
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

function expandPath(fancyTreeObj, fullPath, actualPath){
    // get the rest of the path to expand
    var rest = fullPath.substr(actualPath.length);
    // cut the leading "/"
    if (rest.substr(0,1) == "/") rest = rest.substr(1);
    var next = rest.substr(0, rest.indexOf("/"));
    // get the node
    var node = fancyTreeObj.getNodeByKey(actualPath);

    // expand the node if not already expanded
    if (node && !node.isExpanded()){
        node.setExpanded(true).done(function(){
            // if any rest, recursively call expandPath
            if (next.length > 0){
                expandPath(fancyTreeObj, fullPath, actualPath + "/" + next);
            }
        });
    }
    //if node is not found at least try to expand the rest
    else if (next.length > 0){
        expandPath(fancyTreeObj, fullPath, actualPath + "/" + next);
    }
}

/* refreshes the tree node */
function refreshTreeNode(node) {
    if (node) {
        node.resetLazy();
        node.setExpanded(true);
    }
}

/* refreshes the tree node */
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

/* refreshes the currently selected tree node */
function refreshCurrentTreeNode() {
    var node = $("#collection-tree-tree").fancytree("getActiveNode");
    refreshTreeNode(node);
}

/* refreshes the parent of the currently selected tree node */
function refreshParentTreeNode() {
    //reload the parent tree node
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var targetNode = fancyTree.getActiveNode();
    var parentNode = targetNode.getParent();
    parentNode.resetLazy();
    parentNode.setExpanded();
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

// *****************************************************************************
// *            DIALOG FUNCTIONS
// *****************************************************************************
//called each time the collection/folder sharing dialog is opened
function updateFileList() {
    $('#uploadFileList').dataTable().fnReloadAjax("filelist.xql?collection=" + escape(getCurrentCollection()));
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

//custom rendered for each row of the sharing dataTable
function collectionSharingDetailsRowCallback(nRow, aData, iDisplayIndex) {
    // console.debug(aData);
    var aceTarget = aData[0];
    var name = aData[2];

    //add attribute defining the entry type
    $(nRow).attr("data-entry-type", aceTarget);
    //determine user or group icon for first column
    if (aceTarget == "USER") {
        $('td:eq(0)', nRow).html('<img alt="User Icon" src="theme/images/user.png"/>');
    } else if (aceTarget == "GROUP") {
        $('td:eq(0)', nRow).html('<img alt="Group Icon" src="theme/images/group.png"/>');
    }

    // build role dropdown
    var collectionMode = aData[3];
    var dropdown = $("<select/>");
    $.each(tamboti.shareRoles.options, function (key, data) {
        // console.debug("colMode: " + collectionMode + " selectMode: " + data.collectionPermissions);
        dropdown.append("<option value='"  + data.value + "' " + (collectionMode == data.collectionPermissions?"selected='selected'":"") + ">" + data.title + "</option>");
    });
    // register change event listener to update Permissions
    dropdown.change(function() {
        var selectedShareType = this.value;
        var fancyTree = $('#collection-tree-tree').fancytree("getTree");
        var collection = fancyTree.getActiveNode().key;
        $.ajax({
            url: "operations.xql",
            data: {
                action: 'share',
                collection: collection,
                name: name,
                target: aceTarget,
                type: selectedShareType
            },
            type: 'POST',
            success: function(data, message) {
                $.each(tamboti.shareRoles.options, function (key, data){
                    if(data.value == selectedShareType) $('td:eq(3)', nRow).html(data.collectionPermissions);
                } );
            },
            error: function(response, message) {
                showMessage('Updating Permissions failed: ' + response.responseText);
            }
        });
    });

    $('td:eq(4)', nRow).html(dropdown);
    // //add a delete button, with action to perform an update on the server
    var imgDeleteId = 'imgDelete_' + iDisplayIndex;
    $('td:eq(5)', nRow).html('<img id="' + imgDeleteId + '" alt="Delete Icon" src="theme/images/cross.png" onclick="javascript: removeAceByName(\'' + getCurrentCollection() + '\',\'' + aData[0] + '\',\'' + aData[2] + '\');"/>');

    return nRow;
}


// *****************************************************************************
// *            SHARING ACTIONS
// *****************************************************************************
//share Collection to an user
function addUserACE(options) {
    var username = options.username;
    //check if this is a duplicate user
    if (tamboti.checkDuplicateSharingEntry(username, "USER")) {
        return;
    }
    // //check this is a valid user otherwise show error
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "is-valid-user-for-share",
            username: escape(username)
        },
        success: function(data, status, xhr) {
            var fancyTree = $('#collection-tree-tree').fancytree("getTree");
            var collection = fancyTree.getActiveNode().key;
            
            //2) create the user ace on the server
            $.ajax({
                type: 'POST',
                url: "operations.xql",
                data: { 
                    action: "add-user-ace",
                    collection: collection,
                    write: options.write,
                    execute: options.execute,
                    inherit: options.inherit,
                    username: escape(username)
                },
                success: function(data, status, xhr) {
                    //3) reload dataTable
                    //$('#collectionSharingDetails').dataTable().fnAddData(["USER", $('#user-auto-list').val(), "ALLOWED", "r--", $(data).find("status").attr("ace-id")]);
                    $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(collection));

                    //(4) go to the last page
                    //$('#collectionSharingDetails').dataTable().fnPageChange("last");
                },
                error: function(xhr, status, error) {
                    showMessage("User '" + username + "' already added to this folder!");
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
function addGroupACE(options) {
    var groupname = options.groupname;

    //check if this is a duplicate user
    if (tamboti.checkDuplicateSharingEntry(groupname, "GROUP")) {
        return;
    }
    //1) check this is a valid group otherwise show error
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "is-valid-group-for-share",
            groupname: escape(groupname)
        },        
        success: function(data, status, xhr) {
            var fancyTree = $('#collection-tree-tree').fancytree("getTree");
            var collection = fancyTree.getActiveNode().key;

            //2) create the ace on the server
            $.ajax({
                type: 'POST',
                url: "operations.xql",
                data: { 
                    action: "add-group-ace",
                    collection: collection,
                    write: options.write,
                    execute: options.execute,
                    inherit: options.inherit,
                    groupname: escape(groupname)
                },
                success: function(data, status, xhr) {
                    //3) reload dataTable
//                  $('#collectionSharingDetails').dataTable().fnAddData(["GROUP", $('#group-auto-list').val(), "ALLOWED", "r--", $(data).find("status").attr("ace-id")]);
                    $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(collection));

                    //(4) go to the last page
                    //$('#collectionSharingDetails').dataTable().fnPageChange("last");
                },
                error: function(xhr, status, error) {
                    showMessage("Could not create entry");
                }
            });
        },
        error: function(xhr, status, error) {
            showMessage("The group '" + groupname + "' does not exist!");
        }
    });
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

//sets an ACE by type/name on a share to executeeable or not
function setAceExecutableByName(checkbox, collection, target, name, isExecutable) {
    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "set-ace-executable-by-name",
            collection: collection,
            target: target,
            name:  name,
            'is-executable': isExecutable
        },
        success: function(data, status, xhr) {
            checkbox.checked = isExecutable;
        },
        error: function(xhr, status, error) {
            showMessage("Could not modify entry");
            checkbox.checked = ! isExecutable;
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
            }
        });
    }
}

//removes an ACE by user-/group name from a share
function removeAceByName(collection, target, name) {
    if(confirm("Are you sure you wish to remove this entry?")){
        var fancyTree = $('#collection-tree-tree').fancytree("getTree");
        var collection = fancyTree.getActiveNode().key;
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
            }
        });
    }
}

function shareCollection(options){
    if (tamboti.checkDuplicateSharingEntry(options.name, options.target)) {
        return;
    }

    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var collection = fancyTree.getActiveNode().key;

    $.ajax({
        type: 'POST',
        url: "operations.xql",
        data: { 
            action: "share",
            collection: collection,
            name: options.name,
            target: options.target,
            type: options.type
            },
        success: function(data, status, xhr) {
            // reload dataTable
//                  $('#collectionSharingDetails').dataTable().fnAddData(["GROUP", $('#group-auto-list').val(), "ALLOWED", "r--", $(data).find("status").attr("ace-id")]);
            $('#collectionSharingDetails').dataTable().fnReloadAjax("sharing.xql?collection=" + escape(collection));

            // go to the last page
            //$('#collectionSharingDetails').dataTable().fnPageChange("last");
        },
        error: function(response, message) {
            showMessage('Sharing failed: ' + response.responseText);
        }
    });
}

// *****************************************************************************
// *            COLLECTION ACTIONS
// *****************************************************************************

/*
 Called when the user clicks on the "create" button in the create collection dialog.
 */
function createCollection(dialog) {
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var name = $("#new-collection-name").val();
    var collection = fancyTree.getActiveNode().key;
    // console.debug("create '" + name + "' in '" + collection + "'");
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

/*
 Called when the user clicks on the "rename" button in the rename collection dialog.
 */
function renameCollection(dialog) {
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var name = $('#rename-collection-form input[name = name]').val();
    var collection = fancyTree.getActiveNode().key;
    // console.debug("rename '" + collection + "' to '" + name + "'");
    
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
                currentNode.parent.sortChildren();
                //If it has children, trigger reload to regenerate keys with new name
                //ToDo: add recursive change child-keys to avoid reloading
                
            },
        error: function(response, message) {
            showMessage('Renaming collection failed: ' + response.responseText);
        }
    });

    //close the dialog
    dialog.dialog("close");
}

/*
 Called when the user clicks on the "move" button in the move collection dialog.
 */
function moveCollection(dialog) {
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var path = $('#move-collection-form select[name = path]').val();
    var activeNode = fancyTree.getActiveNode();
    var collection = activeNode.key;

    // console.debug("moveCol '" + collection + "' to '" + path + "'");

    $.ajax({
        url: "operations.xql",
        data: {
            action: 'move-collection', 
            path: path, 
            collection: collection
        },
        type: 'POST',
        success: function(data, message) {
            var ft = $("#collection-tree-tree").fancytree("getTree");
            
            // expand target node
            expandPath(ft, path, "");
            var targetNode = ft.getNodeByKey(path);
            var currentNode = ft.getActiveNode();
            var collectionName = collection.substring(collection.lastIndexOf("/") + 1, collection.length);
            var originParentNode = currentNode.parent;

            currentNode.moveTo(targetNode, 'child');
            targetNode.load(true).done(function(){
                targetNode.setExpanded(true).done(function(){
                    // originParentNode.load(true);
                    var selectNode = ft.getNodeByKey(path + '/' + collectionName, targetNode);
                    selectNode.setActive(true);
                    // console.debug(originParentNode);
                    updateCollectionPaths(selectNode.title, selectNode.key);
                });
            });
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
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var collection = fancyTree.getActiveNode().key;
    
    $.ajax({
        url: "operations.xql",
        data:{ 
            action: 'remove-collection', 
            collection: collection 
        },
        type: 'POST',
        success:
            function(data, message) { 
                //remove Node from FancyTree
                fancyTree.getActiveNode().remove();
            },
        error: 
            function (response, message) { 
                showMessage('Removing collection failed: ' + response.responseText);
            }
    });
    //close the dialog
    dialog.dialog("close");
}

function copyCollectionACL(source, target) {
    $.ajax({
        url: "operations.xql",
        data: {
            action: 'copyCollectionACL', 
            collection: source,
            targetCollection: target, 
        },
        type: 'POST',
        success: function(data, message) {
            var fancyTree = $('#collection-tree-tree').fancytree("getTree");
            var targetNode = fancyTree.getNodeByKey(target);
            var parentNode = targetNode.getParent();
            parentNode.load(true).done(function(){
                parentNode.setExpanded();
            });
            return true;
        },
        error: function(response, message) {
            //ToDo: Popup when creating Collection failed
            return false;
        }
    });
}


// *****************************************************************************
// *            RESSOURCE ACTIONS
// *****************************************************************************

function newResource() {
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var collection = fancyTree.getActiveNode().key;

    $("#new-resource-form input[name = collection]").val(collection);
    $("#new-resource-form").submit();
}

function newRelatedResource() {
    var fancyTree = $('#collection-tree-tree').fancytree("getTree");
    var collection = fancyTree.getActiveNode().key;
    $("#add-related-form input[name = collection]").val(collection);
    $("#add-related-form").submit();
}

/*
 Called when the user clicks on the "move" button in the move resource dialog
 */
function moveResource(dialog) {
    var path = $('#move-resource-form select[name = path]').val();
    var resource = $('#move-resource-form input[name = resource]').val();
    var resource_type = $('#record-format').html();
    var source_collection = "/" + $('#file-location-folder').html();

    $.ajax({
        url: "operations.xql",
        data: {
            action: 'move-resource',
            path: path,
            resource: resource,
            source_collection: source_collection,
            resource_type: resource_type
        },
        type: 'POST',
        success: function(data, message) {
            // console.debug(path);
            var fancyTree = $("#collection-tree-tree").fancytree("getTree");
            var selectNode = fancyTree.getNodeByKey(path);
            selectNode.setActive(true);
            updateCollectionPaths(selectNode.title, selectNode.key);
            tamboti.apis.simpleSearch();
        },
        error: function(response, message) {
            showMessage('Moving collection failed: ' + response.responseText);
        }
    });
    dialog.dialog("close");
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
