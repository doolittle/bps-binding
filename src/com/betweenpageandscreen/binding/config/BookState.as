package com.betweenpageandscreen.binding.config
{
  import com.betweenpageandscreen.binding.events.BookEvent;
import com.bradwearsglasses.utils.helpers.ArrayHelper;

public class BookState
  {
    public static var PAUSED:Boolean  = false;
    public static var CAMERAS:Array   = [];
    public static var SELECTED_CAMERA:String;

    private static var defaultSequence:Array =  [ //Commands to run for initialization
      BookEvent.CAMERA_LOAD,
      BookEvent.MARKER_LOAD,
      BookEvent.INTRO
    ];

    //TODO: add webcam_attach and make this the same as the bootstrapper init.
    public static var initSequence:Array = ArrayHelper.clone(defaultSequence);

    public static function resetSequence():void {
      initSequence = ArrayHelper.clone(defaultSequence);
    }
  }
}
