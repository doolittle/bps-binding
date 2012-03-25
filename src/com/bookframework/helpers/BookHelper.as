package com.bookframework.helpers
{
  import com.bookframework.config.BookState;
  import com.bradwearsglasses.utils.helpers.DateHelper;
  
  public class BookHelper {
    
    public static function camera_to_index(camera:String):String {
      var camera_num:Number = 0
      trace("Finding camera index:" + camera)
      BookState.CAMERAS.forEach(function(name:String, index:Number, ...rest):void { if (name==camera) camera_num = index; })
      trace("camera num:" + camera_num)
      return camera_num.toString() 
    }

    public static function debug(s:String):void {
      trace("  ## (" + DateHelper.timestamp_utc()  + ") :: " + s) 
    }    
  }
}