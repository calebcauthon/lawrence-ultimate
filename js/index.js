$(document).ready(function() {
	var has_cleared_input = false;
	var inputHasBeenCleared = function() {
		if(has_cleared_input)
			return true;
		else
			return false;
	};
	var clearInput = function() {
		has_cleared_input = true;
		$('#lusl-signup').val('');
	};
	var undo_clearInput = function() {
		has_cleared_input = false;
		$('#lusl-signup').val('my email address is...');
	};
	
	var key_has_been_pressed = false;
	var markKeyAsPressed = function() {
		key_has_been_pressed = true;
	};
	var keyHasBeenPressed = function() {
		if(key_has_been_pressed)
			return true;
		else
			return false;
	};
	$('#lusl-signup').click(function() {
		if(!inputHasBeenCleared())
			clearInput();
	}).keypress(function() {
		markKeyAsPressed();
	}).blur(function() {
		if(!keyHasBeenPressed())
			undo_clearInput();
	});
	
	$('#lusl-signup-button').click(function() {
		$('.summerLeagueSignupWrap .overlay').css('display', 'block').animate({
			opacity: 1
		}, 600);
	});
	
});
