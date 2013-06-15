package com.betweenpageandscreen.binding.events
{
  import flash.events.Event;

  public class BookEvent extends Event {
    
    public static var INIT_NEXT:String          = 'init_next';
    public static var INIT_COMPLETE:String      = 'init_complete';

    public static var BOOTSTRAP_COMPLETE:String = 'bootstrap_complete';
    public static var BOOTSTRAP_ERROR:String    = 'bootstrap_error';
    public static var BOOTSTRAP_NEXT:String     = 'bootstrap_next';
    public static var BOOTSTRAP_STATUS:String   = 'bootstrap_status';

    public static var CAMERA_LOAD:String               = 'camera_load';
    public static var CAMERA_PARAMS_COMPLETE:String    = 'camera_params_complete';
      
    public static var CONTEXT_MENU:String       = 'context_menu';
    public static var SWITCH_EDITIONS:String    = 'switch_editions';
   
    public static var MARKER_LOAD:String        = 'marker_load';
    public static var MARKER_LOADED:String      = 'marker_loaded';
    public static var MARKER_TIMEOUT:String     = 'marker_timeout';
    public static var MARKER_FOUND:String       = 'marker_found';
    public static var MARKER_LOST:String        = 'marker_lost';
    public static var MARKER_PRINT:String       = 'marker_print';
    
    public static var MARKERS_RESET:String      = 'markers_reset';
    public static var MARKERS_REASSIGN:String   = 'markers_reassign';
    public static var MARKERS_COMPLETE:String   = 'markers_complete';
      
    public static var MODULE_DESTROY:String     = 'module_destroy';
    
    public static var BOOK_READY:String         = 'book_ready';
    public static var BOOK_COMPLETE:String      = 'book_complete';
    
    public static var WEBCAM_ATTACH:String      = 'webcam_attach';
    public static var WEBCAM_ATTACHED:String    = 'webcam_attached';
    public static var WEBCAM_FAIL:String        = 'webcam_fail';
    public static var WEBCAM_MULTIPLE:String    = 'webcam_multiple';
    public static var WEBCAM_MUTED:String       = 'webcam_muted';
    public static var WEBCAM_SWITCH:String      = 'webcam_switch';

    public static var VIEW_PREP:String          = 'view_prep';
    public static var VIEW_PREPPED:String       = 'view_prepped';


    public static var FULLSCREEN:String         = 'fullscreen';
    public static var HELP:String               = 'help';
    public static var SETTINGS:String           = 'settings';
    public static var INTRO:String              = 'intro';
    public static var RELOAD:String             = 'reload';
    public static var INTRO_COMPLETE:String     = 'intro_complete';
    
    public var mode:String = 'default';
    public function BookEvent(type:String, _mode:String='default', _data:*=null){
      super(type);
      mode = _mode;
      if (_data) data = _data;   
    }
    
    private var __data:*;
    public function get data():* { return __data; }
    public function set data(_data:*):void {  __data = _data; }
    
    override public function clone():Event {
      return new BookEvent(type);
    }
    
  }
}