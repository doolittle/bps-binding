package com.betweenpageandscreen.binding.config
{
  import com.betweenpageandscreen.binding.events.BookEvent;

  public class BookState
  {
    public static var PAUSED:Boolean  = false;
    public static var CAMERAS:Array   = [];
    public static var SELECTED_CAMERA:String;

    //TODO: add webcam_attach and make this the same as the bootstrapper init.
    public static var initSequence:Array = [ //Commands to run for initialization
        BookEvent.CAMERA_LOAD,
        BookEvent.MARKER_LOAD,
        BookEvent.INTRO
    ]
  }
}
