$(document).ready(function() {
	$('td').click(function() {
		$(this).find('span').hide();
		$(this).find('input').show().focus();
	});
});
