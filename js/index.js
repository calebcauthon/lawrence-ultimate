$(document).ready(function() {
	var has_cleared_input = false;
	var inputHasBeenCleared = function() {
		if(has_cleared_input)
			return true;
		else
			return false;
	};

	var original_input = '';
	var clearInput = function() {
		original_input = $('#lusl-signup').val();
		has_cleared_input = true;
		$('#lusl-signup').removeClass('pristine').val('');
	};
	var undo_clearInput = function() {
		has_cleared_input = false;
		$('#lusl-signup').addClass('pristine').val(original_input);
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
