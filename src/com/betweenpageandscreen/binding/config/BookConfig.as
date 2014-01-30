package com.betweenpageandscreen.binding.config
{
  import com.betweenpageandscreen.binding.fonts.BookHelveticaBold;
  import com.betweenpageandscreen.binding.models.vo.BrightnessVO;

  import flash.display.Stage;
  import flash.display.StageQuality;
import flash.utils.ByteArray;

import org.papervision3d.typography.Font3D;

  public class BookConfig {

    public static function get BINDING_VERSION():String {
      return "v.1.0.118";
    }

    // Debug settings
    public static var DEBUG:Boolean           = false;
    public static var SHOW_FPS:Boolean        = false; //Displays FPS monitor in lower left.

    // Cached configs are stored as byte arrays rather than loaded at runtime.
    public static var CACHED_MARKERS:Boolean  = true;
    public static var CACHED_CAMERA:Boolean   = true;

    public static var SHOW_INTRO:Boolean      = true; // Whether to show intro screen

    // Don't show timeout message when we can't find a marker, useful for presentations
    public static var HIDE_TIMEOUT:Boolean    = false;

    public static var TRACK_ANALYTICS:Boolean = true;

    // Flash settings
    public static var QUALITY:String          = StageQuality.HIGH;
    public static var FPS:int                 = 31; // Tom swears 31 FPS runs faster.

    // Camera settings
    public static var CAM_FPS:int             = 31;
    public static var MOTION_LEVEL:int        = 10;
    public static var CAM_BLUR:int            = 0; // Applies a blur to the webcam
    public static var CAM_WIDESCREEN:Boolean  = false;

    // We need this much confidence to accept a marker.
    // Lower numbers will increase false-positives,
    // higher numbers will increase flickering markers.
    public static var MIN_CONFIDENCE:Number   = 0.55;

    // If we don't already have a marker, require a higher tolerance
    public static var HIGH_CONFIDENCE:Number  = 0.75;

    // When to warn the user about a lost marker. In seconds.
    public static var LOST_MARKER_TIMEOUT:int = 30*10;

    // Grace period for dropped markers.
    public static var TICK_DELAY:int    = 6;

    // TODO: Remove. Only used to initialize the vector of markers in VideoDisplay.
    public static var NUM_MARKERS:int      = 17;

    // Type settings.
    public static var TYPEFACE:Font3D      = new BookHelveticaBold();
    public static var SCREENBACK_COLOR:int = 0xFFFFFF;
    public static var LETTER_COLOR:int     = 0x000000;
    public static var LINE_JUSTIFICATION_TOLERANCE:Number = 1.75;

    public static var SCREEN_ALPHA_MAX:Number = 0.5; // How white to make the screen over the image. Makes the black show up more.
    public static var SCREEN_ALPHA_MIN:Number = 0.0;

    // Data containers.
    // TODO: Do these need to be configurable?
    public static var CACHE_ID:String;
    public static var MARKERS_DATA:ByteArray;
    public static var CAMERA_DATA:ByteArray;

    // Marker settings.
    public static var CODE_WIDTH:Number       = 80;  // Width of marker hex (I think)
    public static var MARKER_SIZE:Number      = 8;   // Flar logo is 16

    // How much to degrade the image when sampling.
    // Smaller numbers mean faster performance, worse detection.
    public static var DOWNSAMPLE:Number       = 0.5;

    // Display config.
    public static var DISPLAY_PADDING:int     = 40;  // Padding around video frame.
    public static var BORDER_PADDING:int      = 3;   // Padding between video and border.
    public static var MAX_UPSCALE:Number      = 1.5; // We can make the image bigger by scaling up the sprite

    public static var SCALE:Number            = 1;

    // Camera height/width
    private static var camera_width:int = 640;
    public static function set CAMERA_WIDTH(n:int):void {
      camera_width = n;
    }

    public static function get CAMERA_WIDTH():int {
      return camera_width*SCALE;
    }

    private static var camera_height:int = 480;
    public static function set CAMERA_HEIGHT(n:int):void {
      camera_height = n;
    }

    public static function get CAMERA_HEIGHT():int {
      return camera_height*SCALE;
    }

    // View is the size of our 3D viewport.
    public static function get VIEW_WIDTH():int {
      return CAMERA_WIDTH;
    }

    public static function get VIEW_HEIGHT():int {
      return CAMERA_HEIGHT;
    }

    // Sample is the size of the image we send to the AR module.
    // Bigger images will be slower.
    public static function get SAMPLE_WIDTH():int {
      return CAMERA_WIDTH*DOWNSAMPLE;
    }
    public static function get SAMPLE_HEIGHT():int {
      return CAMERA_HEIGHT*DOWNSAMPLE;
    }

    // We scale up the image (video + 3d) to fill as much of the screen as possible.
    // This actually scales the sprite instead of rendering a larger image, which is dodgy
    // (since it makes pixel-lines bigger than one pixel) but possibly more CPU efficient?
    // Tries to fill browser window up to MAX_UPSCALE. Stops scaling up at MAX_UPSCALE
    // (i.e. if browser supports 6x and MAX_UPSCALE is 3, will stop at 3x)
    public static function UPSCALE(stage:Stage):Number {
      if (
          ((stage.stageHeight-DISPLAY_PADDING) > (VIEW_HEIGHT*MAX_UPSCALE))
          && ((stage.stageWidth-DISPLAY_PADDING) > (VIEW_WIDTH*MAX_UPSCALE))) {
        return MAX_UPSCALE; //We've got a big screen, but let's not go crazy.
      } else if (stage.stageHeight < stage.stageWidth) {
        return (stage.stageHeight - DISPLAY_PADDING)/VIEW_HEIGHT;
      } else {
        return (stage.stageWidth - DISPLAY_PADDING)/VIEW_WIDTH;
      }
    }

    // How much the parser posterizes the image before analysis.
    // The threshold reflects the inherent contrast of the video
    // image, which means we change it for bright/dark rooms.
    public static var THRESHOLD:int  = 80;

    private static var __room_brightness:String = BrightnessVO.AVERAGE;

    // Setting the room brightness
    // In a really awesome world, we'd somehow automatically calibrate this.
    public static function get ROOM_BRIGHTNESS():String {
      return __room_brightness;
    }

    public static function set ROOM_BRIGHTNESS(s:String):void {
      __room_brightness = s;
      switch (__room_brightness) {
        case BrightnessVO.BRIGHT:
          THRESHOLD = 60;
          break;
        case BrightnessVO.DARK:
          THRESHOLD = 120;
          break;
        case BrightnessVO.AVERAGE:
        default:
          THRESHOLD = 80;
          break;
      }
    }
  }
}
