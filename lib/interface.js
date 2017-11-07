// shows or hides an instructions overlay for a model
function toggleInstructionsOverlay() {
  if ($('#instructions-overlay').css('display') != 'block') {
    $('#instructions-overlay').fadeIn('slow');
    $('#instructions-toggle').text('ocultar ayuda');
  } else {
    $('#instructions-overlay').fadeOut('slow');
    $('#instructions-toggle').text('mostrar ayuda');
  }
}
