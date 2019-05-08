angular.module('app', [], function() {});
FileUploadCtrl.$inject = ['$scope'];
function FileUploadCtrl(scope) {
    //============== DRAG &amp; DROP =============
    // source for drag&amp;drop: http://www.webappers.com/2011/09/28/drag-drop-file-upload-with-html5-javascript/
    var dropbox = document.getElementById("dropbox");
    scope.dropText = 'Drop files here...';
    
    // init event handlers
    function dragEnterLeave(evt) {
        evt.stopPropagation();
        evt.preventDefault();
        scope.$apply(function(){
            scope.dropText = 'Drop files here...';
            scope.dropClass = '';
        });
    }
    dropbox.addEventListener("dragenter", dragEnterLeave, false);
    dropbox.addEventListener("dragleave", dragEnterLeave, false);
    dropbox.addEventListener("dragover", function(evt) {
        evt.stopPropagation();
        evt.preventDefault();
        var clazz = 'not-available';
        //var ok = evt.dataTransfer &amp;&amp; evt.dataTransfer.types &amp;&amp; evt.dataTransfer.types.indexOf('Files') &gt;= 0
        scope.$apply(function(){
          //  scope.dropText = ok ? 'Drop files here...' : 'Only files are allowed!'
          //  scope.dropClass = ok ? 'over' : 'not-available'
          scope.dropText  = 'Drop files here...';
          scope.dropClass = 'over'; 
        });
    }, false);
    dropbox.addEventListener("drop", function(evt) {
        //console.log('drop evt:', JSON.parse(JSON.stringify(evt.dataTransfer)))
        evt.stopPropagation();
        evt.preventDefault();
        scope.$apply(function(){
            scope.dropText = 'Drop files here...';
            scope.dropClass = '';
        });
        var files = evt.dataTransfer.files;
        if (files.length > 0) {
            scope.$apply(function(){
                scope.files = [];
                for (var i = 0; i < files.length; i++) {
                    scope.files.push(files[i]);
                }
            });
        }
    }, false);
    //============== DRAG &amp; DROP =============
    
    scope.setFiles = function(element) {
        scope.$apply(function(scope) {
        //console.log('files:', element.files);
        // Turn the FileList object into an Array
            scope.files = [];
            for (var i = 0; i < element.files.length; i++) {
                scope.files.push(element.files[i]);
            }
            scope.progressVisible = true;
        });
    };
    
    scope.uploadFile = function() {
        var fd = new FormData();
        for (var i in scope.files) {
            fd.append("uploadedFile", scope.files[i]);
        }
        var xhr = new XMLHttpRequest();
        xhr.upload.addEventListener("progress", uploadProgress, false);
        xhr.addEventListener("load", uploadComplete, true);
        xhr.addEventListener("error", uploadFailed, false);
        xhr.addEventListener("abort", uploadCanceled, false);
        
        xhr.open("POST", "../upload/upload.xq");
        scope.progressVisible = false;        
        
        if (document.getElementById('upload-resource-id')!==null) {
            var parent_record = document.getElementById('upload-resource-id').innerHTML;
            xhr.setRequestHeader("X-File-Parent", parent_record);
        }
                
        //for folder uploads
        if ($('#file-upload-folder') !== null) {
            var upload_folder = $('#file-upload-folder').html();
            xhr.setRequestHeader("X-File-Folder", upload_folder);
		}       
        
        xhr.send(fd);
        scope.files = [];
    };
    
    scope.hideUploadDialog = function() {
        scope.files = [];
        $("#upload-file-dialog").dialog("close");
    };
    
    function uploadProgress(evt) {
        scope.$apply(function(){
            if (evt.lengthComputable) {
                scope.progress = Math.round(evt.loaded * 100 / evt.total);
            } else {
                scope.progress = 'unable to compute';
            }
        });
    }
    
    function uploadComplete(evt) {
        /* This event is raised when the server send back a response */
        //$('#upload-file-dialog').dialog('close');
         tamboti.apis.simpleSearch();
        //alert(evt.target.responseText)
    }
    
    function uploadFailed(evt) {
        alert("There was an error attempting to upload the file.");
    }
    
    function uploadCanceled(evt) {
        scope.$apply(function(){
            scope.progressVisible = false;
        });
        alert("The upload has been canceled by the user or the browser dropped the connection.");
    }
}
