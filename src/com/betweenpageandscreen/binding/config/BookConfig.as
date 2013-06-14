package com.betweenpageandscreen.binding.config
{
  import com.betweenpageandscreen.binding.fonts.BookHelveticaBold;
  import com.betweenpageandscreen.binding.models.vo.BrightnessVO;

  import flash.display.Stage;
  import flash.display.StageQuality;
import flash.utils.ByteArray;

import org.papervision3d.typography.Font3D;

  public class BookConfig {

    //Hardcoded config that changes behavior
    public static var DEBUG:Boolean           = false;
    public static var CACHED_MARKERS:Boolean  = true;
    public static var CACHED_CAMERA:Boolean   = true;
    public static var SHOW_FPS:Boolean        = true;
    public static var SHOW_INTRO:Boolean      = true; //Whether to show intro screen
    public static var HIDE_TIMEOUT:Boolean    = false; //Don't show timeout message when we can't find a marker, useful for presentations
    public static var TRACK_ANALYTICS:Boolean = true;

    //Hardcoded settings
    public static var QUALITY:String          = StageQuality.HIGH;
    public static var FPS:Number              = 31; // Tom swears 31 FPS runs faster.
    public static var CAM_FPS:Number          = 31;
    public static var SCREEN_ALPHA_MAX:Number = .5; //How white to make the screen over the image. Makes the black show up more.
    public static var SCREEN_ALPHA_MIN:Number = .0;
    public static var NUM_MARKERS:Number      = 17;

    public static var TYPEFACE:Font3D         = new BookHelveticaBold();

    public static var SCREENBACK_COLOR:Number = 0xFFFFFF;
    public static var LETTER_COLOR:Number     = 0x000000;

    public static var MOTION_LEVEL:Number     = 10;

    public static var LINE_JUSTIFICATION_TOLERANCE:Number = 1.75;

    //Containers
    public static var CACHE_ID:String;
    public static var MARKERS_DATA:ByteArray;
    public static var CAMERA_DATA:ByteArray;

    public static var CODE_WIDTH:Number       = 80;
    public static var MARKER_SIZE:Number      = 8; //Flar logo is 16
    public static var DOWNSAMPLE:Number       = .5;
    public static var SCALE:Number            = 1;
    public static var CAMERA_WIDTH:Number     = 640*SCALE;
    public static var CAMERA_HEIGHT:Number    = 480*SCALE;
    public static var SAMPLE_WIDTH:Number     = CAMERA_WIDTH*DOWNSAMPLE;
    public static var SAMPLE_HEIGHT:Number    = CAMERA_HEIGHT*DOWNSAMPLE;

    public static var DISPLAY_PADDING:Number  = 80;

    public static var MAX_UPSCALE:Number     = 1.5; //We can make the image a little bigger by scaling up the sprite
    public static function UPSCALE(stage:Stage):Number {
      if (((stage.stageHeight-DISPLAY_PADDING) > (VIEW_HEIGHT*MAX_UPSCALE)) && ((stage.stageWidth-DISPLAY_PADDING) > (VIEW_WIDTH*MAX_UPSCALE))) {
        return MAX_UPSCALE; //We've got a big screen, but let's not go crazy.
      } else if (stage.stageHeight < stage.stageWidth) {
        return (stage.stageHeight - DISPLAY_PADDING)/VIEW_HEIGHT;
      } else {
        return (stage.stageWidth - DISPLAY_PADDING)/VIEW_WIDTH;
      }
      return 1;
    }

    public static var HIGH_CONFIDENCE:Number  = 0.75; //If we don't already have a marker, require a higher tolerance
    public static var MIN_CONFIDENCE:Number   = 0.45;
    public static var THRESHOLD:Number        = 120; //How much the parser posterizes the image before analysis. Default is 80. Brightness of the room will be affected by this.

    public static var LOST_MARKER_TIMEOUT:Number = 30*10; //in seconds

    private static var __room_brightness:String = BrightnessVO.AVERAGE;

    public static function get ROOM_BRIGHTNESS():String {
      return __room_brightness;
    }

    public static function set ROOM_BRIGHTNESS(s:String):void {
      __room_brightness = s
      switch (__room_brightness) {
        case BrightnessVO.BRIGHT:
          THRESHOLD = 60
          break;
        case BrightnessVO.DARK:
          THRESHOLD = 120
          break;
        case BrightnessVO.AVERAGE:
        default:
          THRESHOLD = 80
          break;
      }
    }

    public static function get VIEW_WIDTH():Number { return CAMERA_WIDTH;    }
    public static function get VIEW_HEIGHT():Number {  return CAMERA_HEIGHT;  }

  }
}
