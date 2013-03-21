/************************************
GET FACET TERMS IN RESULTS PAGE
Written by Ethan Gruber, gruber@numismatics.org
Library: jQuery
Description: This utilizes ajax to populate the list of terms in the facet category in the results page.  
If the list is populated and then hidden, when it is re-activated, it fades in rather than executing the ajax call again.
************************************/
$(document).ready(function() {
	var popupStatus = 0;
	
	dateLabel();
	
	$("#backgroundPopup").click(function() {
		disablePopup();
	});
	
	//hover over remove facet link
	$(".remove_filter").hover(
		function () {
			$(this).parent().addClass("ui-state-hover");
		},
		function () {
			$(this).parent().removeClass("ui-state-hover");
		}
	);
	$("#clear_all").hover(
		function () {
			$(this).parent().addClass("ui-state-hover");
		},
		function () {
			$(this).parent().removeClass("ui-state-hover");
		}
	);
	
	//enable multiselect
	$(".multiselect").multiselect({	
   		//selectedList: 3,   		
   		minWidth: 180,
   		header:'<a class="ui-multiselect-none" href="#"><span class="ui-icon ui-icon-closethick"/><span>Uncheck all</span></a>',
   		create: function(){
   			var title = $(this).attr('title');
   			var array_of_checked_values = $(this).multiselect("getChecked").map(function(){
				return this.value;
			}).get();	
			var length = array_of_checked_values.length;
			
			if (length > 3){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title + ': ' + length + ' selected');
			} else if (length > 0 && length <= 3){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title + ': ' + array_of_checked_values.join(', '));
			} else if (length == 0){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title);
			}			
   		},
   		open: function(){      			
      			var id = $(this) .attr('id');
      			if ($('#' + id).html().indexOf('<option') < 0){
	      			var q = $(this).attr('q');
	      			var category = id.split('-select')[0];
	      			//var mincount = $(this).attr('mincount');	      			
	      			$.get('../get_facets/', {
					q: q, category: category, sort: 'index', limit:-1
					},
					function (data) {
						$('#ajax-temp').html(data);
						$('#ajax-temp option').each(function(){
							$(this).clone().appendTo('#' + id);
						});
						$("#" + id).multiselect('refresh')
					}
				);
			}
   		},
   		//close menu: restore button title if no checkboxes are selected
   		close: function(){
   			var title = $(this).attr('title');
      			var id = $(this) .attr('id');
      			var array_of_checked_values = $(this).multiselect("getChecked").map(function(){
				return this.value;
			}).get();	
			if (array_of_checked_values.length == 0){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title);
			}
   		},
   		click: function(){
   		   	var title = $(this).attr('title');
   		   	var id = $(this) .attr('id');
   			var array_of_checked_values = $(this).multiselect("getChecked").map(function(){
				return this.value;
			}).get();	
			var length = array_of_checked_values.length;
			if (length > 3){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title + ': ' + length + ' selected');
			} else if (length > 0 && length <= 3){
				$('button[title=' + title + ']').children('span:nth-child(2)').text(title + ': ' + array_of_checked_values.join(', '));
			} else if (length == 0){
				var q = $(this).attr('new_query');
				if (q.length > 0){
					var category = id.split('-select')[0];
					//var mincount = $(this).attr('mincount');
					$.get('get_facets', {
						q: q, category: category, sort: 'index', limit:-1
						},
						function (data) {
							$('#' + id) .attr('new_query', '');
							$('#' + id) .html(data);
							$('#' + id).multiselect('refresh');
						}
					);
				}
			}
   		}, 
   		uncheckAll: function(){
   			var id = $(this) .attr('id');
   			var q = $(this).attr('new_query');
   			if (q.length > 0){
				var category = id.split('-select')[0];				
				//var mincount = $(this).attr('mincount');
				$.get('get_facets', {
					q: q, category: category, sort: 'index', limit:-1
					},
					function (data) {
						$('#' + id) .attr('new_query', '');
						$('#' + id) .html(data);
						$('#' + id).multiselect('refresh');
					}
				);
			}
   		}
	});
	//.multiselectfilter();
	
	//handle expandable dates
	$('#century_sint_link').hover(function () {
    		$(this) .attr('class', 'ui-multiselect ui-widget ui-state-default ui-corner-all ui-state-focus');
	}, 
	function () {
		$(this) .attr('class', 'ui-multiselect ui-widget ui-state-default ui-corner-all');
	});
	
	$('.century-close') .click(function(){
		disablePopup();
	});
	
	$('#century_sint_link').click(function () {
		if (popupStatus == 0) {
			$("#backgroundPopup").fadeIn("fast");
			popupStatus = 1;
		
		}
		var list_id = $(this) .attr('id').split('_link')[0] + '-list';
		$('#' + list_id).parent('div').attr('style', 'width: 192px;display:block;');
	});
	
	$('.expand_century').click(function(){
		var century = $(this).attr('century');
		var q = $(this).attr('q'); 
		var expand_image = $(this).children('img').attr('src');
		//hide list if it is expanded
		if (expand_image.indexOf('minus') > 0){
			$(this).children('img').attr('src', expand_image.replace('minus','plus'));
			$('#century_' + century + '_list') .hide();
		} else{
			$(this).children('img').attr('src', expand_image.replace('plus','minus'));
			//perform ajax load on first click of expand button
			if ($(this).parent('li').children('ul').html().indexOf('<li') < 0){				
				$.get('../get_decades/', {
					q: q, century: century
					}, function (data) {
						$('#decades-temp').html(data);
						$('#decades-temp li').each(function(){
							$(this).clone().appendTo('#century_' + century + '_list');
						});
					}
				);
			}
			$('#century_' + century + '_list') .show();			
		}
	});
	
	//check parent century box when a decade box is checked
	$('.decade_checkbox').livequery('click', function(event){
		if ($(this) .is(':checked')) {
			//alert('test');
			$(this) .parent('li').parent('ul').parent('li') .children('input') .attr('checked', true);			
		}
		//set label
		dateLabel();
	});
	//uncheck child decades when century is unchecked
	$('.century_checkbox').livequery('click', function(event){
		if ($(this).not(':checked')) {
			$(this).parent('li').children('ul').children('li').children('.decade_checkbox').attr('checked',false);
		}
		//set label
		dateLabel();
	});	
	
	$('#search_button') .click(function () {
		//get categories
		query = new Array();
		
		//get non-facet and not decade/century fields that may have been passed from search
		var query_terms = $('#facet_form_query').attr('value').split(' AND ');	
		var non_facet_terms = new Array();
		for (i in query_terms){
			if (query_terms[i].indexOf('_facet') < 0 && query_terms[i].indexOf('decade_sint') < 0 && query_terms[i].indexOf('century_sint') < 0 && query_terms[i] != '*:*'){
				non_facet_terms.push(query_terms[i]);				
			}
		}
		if (non_facet_terms.length > 0){
			query.push(non_facet_terms.join(' AND '));
		}
		
		//get century/decades
		var date = getDate();
		if (date.length > 0){
			query.push(getDate());
		}		
		
		//get multiselects
		$('.multiselect').each(function () {
			var facet = $(this).attr('id').split('-')[0];
			segment = new Array();
			$(this) .children('option:selected').each(function () {
				if ($(this) .val().length > 0){
					segment.push(facet + ':"' + $(this).val() + '"');
				}				
			});
			if (segment[0] != null) {
				if (segment.length > 1){
					query.push('(' + segment.join(' OR ') + ')');
				}
				else {
					query.push(segment[0]);
				}
			}			
		});
		//set the value attribute of the q param to the query assembled by javascript
		if (query.length > 0){
			$('#facet_form_query').attr('value', query.join(' AND '));
		} else {
			$('#facet_form_query').attr('value', '*:*');
		}		
	});
	
	//function for assembling the Lucene syntax string for querying on centuries and decades
	function getDate(){
		var date_array = new Array();
		$('.century_checkbox:checked').each(function(){
			var century = 'century_sint:' + $(this).val();
			var decades = new Array();
			$(this).parent('li').children('ul').children('li').children('.decade_checkbox:checked').each(function(){
				decades.push('decade_sint:' + $(this).val());
			});
			var decades_concat = '';
			if (decades.length > 1){
				decades_concat = '(' + decades.join(' OR ') + ')';
				date_array.push(decades_concat);
			} else if (decades.length == 1){				
				date_array.push(decades[0]);
			} else {
				date_array.push(century);
			}
			
		});
		var date_query;
		if (date_array.length > 1) {
			 date_query = '(' + date_array.join(' OR ') + ')'
		} else if (date_array.length == 1){
			 date_query = date_array[0];
		} else {
			date_query = '';
		}
		return date_query;
	};
	
	function dateLabel(){
		dates = new Array();
		$('.century_checkbox:checked').each(function(){
			if ($(this).parent('li').children('ul').children('li').children('.decade_checkbox:checked').length == 0){				
				dates.push($(this).val() + '00s');
			} 				
			$(this).parent('li').children('ul').children('li').children('.decade_checkbox:checked').each(function(){
					dates.push($(this).val());
			});				
		});
		if (dates.length > 3) {
			var date_string = 'Date: ' + dates.length + ' selected';
		} else if (dates.length > 0 && dates.length <= 3) {
			var date_string = 'Date: ' + dates.join(', ');
		} else if (dates.length == 0){
			var date_string = 'Date';
		}
		//set labels
		$('#century_sint_link').attr('title', date_string);
		$('#century_sint_link').children('span:nth-child(2)').text(date_string);
	}

	/***************************/
	//@Author: Adrian "yEnS" Mato Gondelle
	//@website: www.yensdesign.com
	//@email: yensamg@gmail.com
	//@license: Feel free to use it, but keep this credits please!
	/***************************/
	
	//disabling popup with jQuery magic!
	function disablePopup() {
		//disables popup only if it is enabled
		if (popupStatus == 1) {	
			$("#backgroundPopup").fadeOut("fast");
			$('#century_sint-list') .parent('div').attr('style', 'width: 192px;');
			popupStatus = 0;		
		}
	}

});