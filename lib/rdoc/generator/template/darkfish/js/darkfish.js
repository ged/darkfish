/**
 * 
 * Darkfish Page Functions
 * $Id$
 * 
 * Author: Michael Granger <mgranger@laika.com>
 * 
 */
function showSource( e ) {
	var target = e.target;
	var codeSections = $(target).
		parents('.method-detail').
		find('.method-source-code');

	$(target).
		parents('.method-detail').
		find('.method-source-code').
		slideToggle();
};

function hookSourceViews() {
	$('.method-description,.method-heading').click( showSource );
};

function hookQuickSearch() {
	$('.quicksearch-field').each( function() {
		var searchElems = $(this).parents('.section').find( 'li' );
		$(this).quicksearch( this, searchElems, {
			noSearchResultsIndicator: 'no-class-search-results',
			focusOnLoad: false
		});
	});
};

function highlightTarget() {
	console.debug( "Location hash: %s", window.location.hash );
	if ( ! window.location.hash || window.location.hash.length == 0 ) return;
	
	var anchor = window.location.hash.substring(1);
	console.debug( "Found anchor: %s", anchor );
	$("a[name=" + anchor + "]").each( function() {
		if ( !$(this).parent('div.target-section') ) {
			console.debug( "Wrapping the target-section" );
			$(this).parent().wrap( '<div class="target-section"></div>' );
		} else {
			console.debug( "Already wrapped." );
		}
	});
	
};

