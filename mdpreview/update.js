var head = document.getElementsByTagName('head')[0];
var RELOAD_TIME = 1000;

window.setInterval(function(){
    reload();
},RELOAD_TIME);

function reload() {
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = 'settext.js';
    script.charset = 'UTF-8';
    head.appendChild(script);
}
    


