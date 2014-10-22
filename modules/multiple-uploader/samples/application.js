/*global $ */

$(function() {
	'use strict';

	var SIZE = 100 * 1024 * 1024; // 100 MB

	var errorFct = function(e) {
		console.error(e);
	};

	var getFileSystem = function(successFct) {
		window.requestFileSystem;
	};

	var createTempName = function() {
		return 'temp.name.dummy.jpg';
	};

	var addToSyncQueue = function(filename) {
		// adding to sync queue
		console.log('Adding to queue', filename);
	};

	var showImage = function(fileName) {
		var src = 'filesystem:' + window.location.origin + '/persistent/'
				+ fileName;
		var img = $('<img />').attr('src', src);
		$('.js-image-container').append(img);
	};

	var readImage = function(fileName, successFct) {
		getFileSystem(function(fileSystem) {
			fileSystem.root.getFile(fileName, {}, function(fileEntry) {

				fileEntry.file(successFct, errorFct);

			}, errorFct);
		});
	};

	var writeSuccessFull = function() {
		addToSyncQueue(fileName);
		showImage(fileName);
	};

	function writeImage(fileName, file) {
		getFileSystem(function(fileSystem) {
			fileSystem.root.getFile(fileName, {
				create : true
			}, function(fileEntry) {

				fileEntry.createWriter(function(fileWriter) {
					fileWriter.onwriteend = writeSuccessFull;

					fileWriter.onerror = errorFct;

					fileWriter.write(file);

				}, errorFct);

			});
		});
	}

	$(document).on('change', '.js-image-upload', function(event) {

		var file = event.target.files[0];
		var fileName = createTempName(file);

		writeImage(fileName, file);
	});

});