/*  SiteStats Server JS Sensor, version 1.0 (c) 2015 Legendum Ltd (UK) 
 *
 *  SiteStats Server JS Sensor is freely distributable under the terms of an
 *  MIT-style license. For details, see http://www.sitestats.com/
 *
 *--------------------------------------------------------------------------*/

if (!window.Guanoo) Guanoo = {

  version: '1.4',

  base: '//guanoo.net/work/',

  callbacks: {},

  error: '',

  attachEvent: function(object, name, callback) {
    if (!object || !name || !callback) return;
    if (object.addEventListener) // Mozilla
      object.addEventListener(name, callback, false);
    else if (object.attachEvent) // IE
      object.attachEvent('on'+name, callback);
    else // old
     eval('var event = object.on'+name+'; object.on'+name+' = event ? function() { event.call(); callback.call() } : callback;');
  },

  getCookie: function(name) {
    var cookie = document.cookie;
    var prefix = 'guanoo_' + name + '=';
    var begin = cookie.indexOf('; ' + prefix);
    if (begin == -1) {
      begin = cookie.indexOf(prefix);
      if (begin != 0) return '';
    }
    else begin += 2;
    var end = document.cookie.indexOf(';', begin);
    if (end == -1) end = cookie.length;
    return unescape(cookie.substring(begin + prefix.length, end));
  },

  getVersion: function() {
    return this.version;
  },

  getElementText: function(el) {
    var text = new String(el.innerText ? el.innerText : (el.textContent ? el.textContent : ''));
    if (text.length > 255) text = text.substring(0, 255);
    return text;
  },

  getId: function(name, hours, defaultId) {
    var id = this.getCookie(name);
    if (!id) id = defaultId ? defaultId : '' + new Date().getTime() + Math.floor(Math.random()*1000);
    this.setCookie(name, id, hours);
    return id;
  },

  getError: function() {
    return this.error;
  },

  loadScript: function(src) {
    var script = document.createElement('SCRIPT');
    script.src = src
    script.type = 'text/javascript';
    var head = document.getElementsByTagName('HEAD')[0];
    head.appendChild(script);
  },

  loadService: function(service, args, callback) {
    if (callback) this.callbacks[service] = callback;
    var url = '';
    for (var key in args) {
      url += (url == '' ? '?' : '&');
      url += key + '=' + escape(args[key]);
    }
    this.loadScript(this.base + 'services/' + service + '.php' + url);
  },

  setCookie: function(name, value, hours) {
    var cookie = 'guanoo_' + name + '=' + escape(value) + '; path=/'
    if (hours) {
        var expires = new Date();
        expires.setTime(expires.getTime() + 3600000*hours);
        cookie += '; expires=' + expires.toGMTString();
    }
    document.cookie = cookie;
    return value;
  },

  setError: function(message) {
    this.error = message;
  }
};

Guanoo.Sensor = {

  data: { site: 0, channel: 0 },

  getCampaign: function() {
    var match = /campaign=([^&]+)/.exec(window.location);
    return match ? Guanoo.setCookie('campaign', match[1]) : Guanoo.getCookie('campaign');
  },

  getData: function() {
    return this.data;
  },

  getFlashVersion: function() {
    if (navigator && navigator.plugins && navigator.plugins['Shockwave Flash']) {
      return navigator.plugins['Shockwave Flash'].description.split(' ')[2];
    } else if (window.ActiveXObject) {
      for (v = 10; v > 1; v--) {
        try {
          var o = new ActiveXObject('ShockwaveFlash.ShockwaveFlash.' + v);
          if (o) return (v + '.0');
        } catch(e) {}
      }
    }
    return 'no';
  },

  getJavaVersion: function() {
    try {
      return java.lang.System.getProperty('java.version');
    } catch(e) {
      return (navigator.javaEnabled() ? 'yes' : 'no');
    }
  },

  load: function() {
    this.data.referrer = document.referrer;
    this.data.campaign = this.getCampaign();
    var Sensor = this;
    var unload = window.attachEvent ? 'beforeunload' : 'unload'; // for IE
    var name = window.location;
    Guanoo.attachEvent(window, 'load', function() {Sensor.sendEvent('page', name, document.title); Sensor.watchLinks()});
    Guanoo.attachEvent(window, unload, function() {Sensor.sendEvent('exit', name)});
  },

  populateForm: function(f) {
    var site = this.data.site; if (!site) return Guanoo.setError('Guanoo.Sensor.data.site not set');
    if (f.site_id) f.site_id.value = site;
    if (f.visit_id) f.visit_id.value = Guanoo.getCookie('site'+site+'_visit_id');
    if (f.user_id) f.user_id.value = Guanoo.getCookie('site'+site+'_user_id');
  },

  sendData: function(data) {
    var name = '';
    for (var key in data) {
      name += key + '=[' + data[key] + '],';
    }
    this.sendEvent('user', name);
  },

  sendEvent: function(type, name, desc, win) {
    var site = this.data.site; if (!site) return Guanoo.setError('Guanoo.Sensor.data.site not set');
    if (!win) win = window;
    var init = win.initGuanoo ? win.initGuanoo : {};
    if (init.eventName) {
      name = init.eventName;
      desc = init.eventDesc;
      init.eventName = init.eventDesc = '';
    }
    var klass = init.eventClass ? init.eventClass : '';
    var loadTime = 0; if (init.eventTime) loadTime = (new Date()).getTime() - init.eventTime.getTime();
    var newVisit = !Guanoo.getCookie('site'+site+'_visit_id');
    var visitId = Guanoo.getId('site'+site+'_visit_id', 0.5);
    var userId = Guanoo.getId('site'+site+'_user_id', 24*365, visitId);
    if (this.data.channel) site += '/' + this.data.channel;
    var src = Guanoo.base + 'event.php?site=' + site + '&type=' + type + '&name=' + escape(name) + "&desc=" + escape(desc ? desc : '');
    src += '&class=' + escape(klass) + '&campaign=' + escape(this.data.campaign);
    src += '&referrer=' + escape(this.data.referrer) + '&refer_id=' + Guanoo.getCookie('refer_id');
    if (type == 'page') Guanoo.setCookie('refer_id', '');
    src += '&new_visit=' + newVisit + '&visit_id=' + visitId + '&user_id=' + userId;
    src += '&resolution=' + screen.width + 'x' + screen.height;
    src += '&color_bits=' + screen.colorDepth;
    src += '&java=' + this.getJavaVersion();
    var flash = Guanoo.getCookie('flash_version');
    if (!flash) flash = Guanoo.setCookie('flash_version', this.getFlashVersion());
    src += '&flash=' + flash;
    var date = init.eventTime = new Date();
    src += '&clock_time=' + date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds();
    src += '&load_time=' + loadTime;
    Guanoo.loadScript(src);
  },

  watchLinks: function(doc) {
    if (!doc) doc = document;
    var Sensor = this;
    for (var i = 0; i < doc.links.length; i++) {
      var link = doc.links[i];
      link.index = i;
      if (!link.onmousedown) {
        var exts = 'doc,pdf,png,gif,jpg,bmp,exe,zip,msi,mp3,wmv';
        var href = new String(link.href);
        var ext = href.substring(href.length-3).toLowerCase();
        link.onmousedown = (exts.indexOf(ext) > -1) ? function() {Sensor.sendEvent('file', this.href, Guanoo.getElementText(this))} : function() {Guanoo.setCookie('refer_id', this.index+1)};
      }
    }
  }
};
