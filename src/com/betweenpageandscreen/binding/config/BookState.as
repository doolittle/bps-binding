package com.betweenpageandscreen.binding.config
{
  import com.betweenpageandscreen.binding.events.BookEvent;

  public class BookState
  {
    public static var PAUSED:Boolean  = false
    public static var CAMERAS:Array   = []
    public static var SELECTED_CAMERA:String

    public static var initSequence:Array = [ //Commands to run for initialization
        BookEvent.CAMERA_LOAD,
        BookEvent.MARKER_LOAD,
        BookEvent.INTRO
    ]


  }
}
