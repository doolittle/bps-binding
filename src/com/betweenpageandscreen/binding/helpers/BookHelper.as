package com.betweenpageandscreen.binding.helpers
{
  import com.betweenpageandscreen.binding.config.BookState;
  import com.bradwearsglasses.utils.helpers.DateHelper;

import flash.display.Stage;

public class BookHelper {
    
    public static function camera_to_index(camera:String):String {
      var camera_num:Number = 0;
      BookState.CAMERAS.forEach(
        function(name:String, index:Number, ...rest):void {
          if (name==camera) camera_num = index;
        }
      );
      return camera_num.toString();
    }

    // Returns true if aspect ratio is close enough to 16x9
    public static function isScreen16x9(stage:Stage):Boolean {
      var ratio:Number = screen_aspect_ratio(stage);
      return (ratio > 1.55 && ratio < 2.1);
    }

    public static function screen_aspect_ratio(stage:Stage):Number {
      var fullHeight:uint = stage.fullScreenHeight;
      var fullWidth:uint = stage.fullScreenWidth;
      var ratio:Number = fullWidth/fullHeight;
      trace("Screen aspect ratio: " + ratio + "(" + fullWidth + "x" + fullHeight + ")");
      return ratio;
    }

    public static function debug(s:String):void {
      trace("  ## (" + DateHelper.timestamp_utc()  + ") :: " + s);
    }
  }
}