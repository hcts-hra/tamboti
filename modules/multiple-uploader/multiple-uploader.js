$(document).ready(function() {
	$("#work-view-container").droppable({
		tolerance : "intersect",
		accept : ".thumbnail-container",
		activeClass : "ui-state-default",
		hoverClass : "ui-state-hover",
		drop : function(event, ui) {
			$(this).append($(ui.draggable));
		}
	});
});

function browseForFiles() {
	document.getElementById("fileElem").click();
}

function saveWorks() {
	$("#work-view-container > div.thumbnail-container").each(function() {
		var imgUrl = "blob:" + $(this).attr("title");
		// FileUpload(imgUrl);
		var fileInput = document.getElementById("fileElem");

		// files is a FileList object (similar to NodeList)
		var files = fileInput.files;
		var file;

		// loop trough files
		for ( var i = 0; i < files.length; i++) {

			// get item
			file = files.item(i);
			// or
			file = files[i];

			uploadFile(file);
		}
	});
}

function uploadFile(file) {
	var uri = "upload.php";
	var xhr = new XMLHttpRequest();
	var fd = new FormData();

	xhr.open("POST", uri, true);
	xhr.onreadystatechange = function() {
		if (xhr.readyState == 4 && xhr.status == 200) {
			// Handle response.
			alert("Response: " + xhr.responseText); // handle response.
		}
	};
	fd.append("myFile", file);
	// Initiate a multipart/form-data upload
	xhr.send(fd);
}

function handleFiles(files) {
	var draggingOptions = {
		appendTo : "body",
		cursor : "move",
		helper : "clone",
		revert : "invalid"
	}
	var fileListContainer = document.getElementById("fileList");
	var fileList = document.createDocumentFragment();
	for ( var i = 0; i < files.length; i++) {
		var imgUrl = window.URL.createObjectURL(files[i]);

		var thumbnailContainer = document.createElement("div");
		var $thumbnailContainer = $(thumbnailContainer);
		thumbnailContainer.className = "thumbnail-container";
		thumbnailContainer.title = imgUrl.substring(5);
		$thumbnailContainer.draggable(draggingOptions);
		$thumbnailContainer.click(function() {
			$(this).toggleClass("selected-thumbnail-container");
		});

		// URL.createObjectURL(event.target.files[0])

		var img = document.createElement("img");
		img.src = imgUrl;
		// img.onload = function() {
		// window.URL.revokeObjectURL(this.src);
		// }
		thumbnailContainer.appendChild(img);

		fileList.appendChild(thumbnailContainer);
	}
	fileListContainer.appendChild(fileList);

}

function moveSelectedImageToSelectedWorkRecord() {
	$(".selected-thumbnail-container", "#picture-view-container").clone()
			.appendTo("#work-view-container");
}
