package com.betweenpageandscreen.binding.views
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  import com.betweenpageandscreen.binding.config.BookState;
  import com.betweenpageandscreen.binding.events.BookEvent;
  import com.betweenpageandscreen.binding.helpers.AnalyticsHelper;
  import com.betweenpageandscreen.binding.helpers.BookHelper;
  import com.betweenpageandscreen.binding.helpers.PVHelper;
  import com.betweenpageandscreen.binding.interfaces.iBookModule;
  import com.betweenpageandscreen.binding.models.CameraParams;

  import com.bradwearsglasses.utils.helpers.GeneralHelper;
  import com.bradwearsglasses.utils.helpers.GraphicsHelper;
  import com.bradwearsglasses.utils.helpers.SpriteHelper;


  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.events.ActivityEvent;
  import flash.events.Event;
  import flash.events.StatusEvent;
  import flash.filters.BitmapFilterQuality;
  import flash.filters.BlurFilter;
  import flash.geom.Matrix;
  import flash.geom.Rectangle;
  import flash.media.Camera;
  import flash.media.Video;
  import flash.system.Capabilities;
  import flash.utils.Dictionary;

  import org.libspark.betweenas3.BetweenAS3;
  import org.libspark.betweenas3.easing.Quad;
  import org.libspark.flartoolkit.core.FLARCode;
  import org.libspark.flartoolkit.core.FLARRgbRaster;
  import org.libspark.flartoolkit.core.FLARTransMatResult;
  import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;
  import org.libspark.flartoolkit.support.pv3d.FLARCamera3D;
  import org.libspark.flartoolkit.support.pv3d.FLARMarkerNode;

  import org.papervision3d.core.math.Number3D;
  import org.papervision3d.materials.ColorMaterial;
  import org.papervision3d.objects.primitives.Plane;
  import org.papervision3d.render.LazyRenderEngine;
  import org.papervision3d.scenes.Scene3D;
  import org.papervision3d.view.Viewport3D;

  public class VideoDisplay extends Sprite
  {
    public var webcam:Camera;
    public var screen:Sprite      = new Sprite;
    public var signal:Sprite      = new Sprite;

    private var viewport:Viewport3D;
    private var scene_pv:Scene3D;
    private var renderer:LazyRenderEngine;
    private var markerWrapper3D:FLARMarkerNode;
    private var debug_plane:Plane;
    private var videoTransformation:Matrix  = new Matrix;
    private var lost_marker_count:int   = 0;
    private var found_marker_count:int  = 0;
    private var TICK_DELAY:int    = BookConfig.TICK_DELAY;

    private var preview_mode:Boolean = false;

    private var video:Video;
    private var capture:BitmapData;

    private var current_module:iBookModule;

    private var raster:FLARRgbRaster;
    private var markers:Vector.<FLARSingleMarkerDetector> = new Vector.<FLARSingleMarkerDetector>(BookConfig.NUM_MARKERS);
    private var modules:Dictionary = new Dictionary;
    private var num_markers:int = 0;
    private var detected_marker:FLARSingleMarkerDetector;

    private var transformation:FLARTransMatResult  = new FLARTransMatResult;

    public function VideoDisplay() {
      videoTransformation.scale(BookConfig.DOWNSAMPLE, BookConfig.DOWNSAMPLE);
    }

    // Matches markers to modules (i.e. pages)
    public function add_marker(patt:String, module:iBookModule,module_id:int, params:CameraParams):void {
      if (!patt || !module) return;

      var flar_code:FLARCode = new FLARCode(BookConfig.MARKER_SIZE, BookConfig.MARKER_SIZE);
      flar_code.loadARPattFromFile(patt);

      var marker:FLARSingleMarkerDetector = new FLARSingleMarkerDetector(params.params, flar_code, BookConfig.CODE_WIDTH);
      marker.setContinueMode(true);

      markers[module_id] = marker;

      module.id         = module_id;
      modules[marker]   = module;

    }

    public function setup(params:CameraParams):void {
      num_markers = markers.length;
      setup_papervision(params);
      setup_viewport();
    }

    public function override_signal(custom_signal:Sprite):void {
      SpriteHelper.destroy(signal);
      signal = custom_signal;
    }

    public function start():void {
      if (hasEventListener(Event.ENTER_FRAME)) removeEventListener(Event.ENTER_FRAME, tick);
      addEventListener(Event.ENTER_FRAME, tick);
      dispatchEvent(new BookEvent(BookEvent.BOOK_READY));
    }
/*
// Method to cleaning re-init the entire videoDisplay
// Does not work yet.
    public function kill():void {
      trace("Resetting.");

      if (video) {
        video.clear()
        video = null;
      }

      if (capture) {
        capture.dispose();
        capture = null;
      }

      if (raster) {
        raster.dispose();
        raster = null;
      }

      remove_tick_listeners();

    }
*/

    public function setup_webcam():void {

      BookState.CAMERAS = Camera.names;
      if (BookState.CAMERAS.length > 0) dispatchEvent(new BookEvent(BookEvent.WEBCAM_MULTIPLE));

      video       = new Video(BookConfig.CAMERA_WIDTH, BookConfig.CAMERA_HEIGHT);
      capture     = new BitmapData(BookConfig.SAMPLE_WIDTH, BookConfig.SAMPLE_HEIGHT, false);
      raster      = new FLARRgbRaster(BookConfig.SAMPLE_WIDTH, BookConfig.SAMPLE_HEIGHT);

      // Adds a blur to the webcam image.
      if (BookConfig.CAM_BLUR > 0) {
        var blur:BlurFilter = new BlurFilter();
        blur.blurX = BookConfig.CAM_BLUR;
        blur.blurY = BookConfig.CAM_BLUR;
        blur.quality = BitmapFilterQuality.LOW;
        video.filters = [blur];
      }

      if (attach_webcam()) {
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_ATTACHED));
      } else {
        // attach_webcam() broadcasts errors attaching webcam.
      }

    }

    public function attach_webcam():Boolean {

      if (webcam) webcam.removeEventListener(ActivityEvent.ACTIVITY, monitor_activity);
      trace("Trying to get camera:" + BookState.SELECTED_CAMERA + "|" + BookState.CAMERAS);

      if (!BookState.SELECTED_CAMERA && GeneralHelper.is_on_a_mac()) {
        var index:int=0, i:int = -1;
        while (++i < Camera.names.length) {
          if (Camera.names[i]=="USB Video Class Video") index = i;
        }
        if (index!=0) BookState.SELECTED_CAMERA = index.toString(); //Apparently camera[0] is not a camera on a mac.
      }

      webcam = Camera.getCamera(BookState.SELECTED_CAMERA);

      if (!webcam) {
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_FAIL));
        return false;
      } else if (webcam.muted || Capabilities.avHardwareDisable) {
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_MUTED));
        return false;
      }

      trace("Setting camera mode:" + BookConfig.CAMERA_WIDTH + "x" + BookConfig.CAMERA_HEIGHT);
      webcam.setMode(BookConfig.CAMERA_WIDTH, BookConfig.CAMERA_HEIGHT, BookConfig.CAM_FPS,true);

      // Flash gets the webcam to do the best it can. The results aren't necessarily what you asked for.
      trace("Camera actually set to:" + webcam.width + "x" + webcam.height + " | FPS:" + webcam.fps + "|" + webcam.currentFPS);

      webcam.setMotionLevel(BookConfig.MOTION_LEVEL);
      webcam.setQuality(0,100); //Not sure if this is relevant since we're not streaming.

      // Flash tells us whether anything is happening in the camera frame.
      // We're not doing anything with this right now.
      webcam.addEventListener(ActivityEvent.ACTIVITY,monitor_activity);

      // Listen for webcam muting (user disables it for whatever reason).
      webcam.addEventListener(StatusEvent.STATUS, monitor_status);

      video.attachCamera(webcam);

      return true;

    }

    private function setup_papervision(params:CameraParams):void {

      viewport = new Viewport3D(BookConfig.VIEW_WIDTH, BookConfig.VIEW_HEIGHT);

      //Flop viewport to support mirroring.
      viewport.x = BookConfig.VIEW_WIDTH;
      viewport.scaleX*=-1;

      var camera3d:FLARCamera3D = new FLARCamera3D(params.params);

      markerWrapper3D = new FLARMarkerNode(FLARMarkerNode.AXIS_MODE_PV3D);
      markerWrapper3D.useClipping = true;

      scene_pv = new Scene3D();
      scene_pv.addChild(markerWrapper3D);

      debug_plane = new Plane( new ColorMaterial(0xFF0000,.4),80,80);
      debug_plane.addChild(PVHelper.draw_axes());
      markerWrapper3D.addChild(debug_plane);
      debug_plane.visible = false;

      //add_reference_plane();

      renderer = new LazyRenderEngine(scene_pv, camera3d, viewport);

    }

    //This just places a square in the middle of the screen.
    private function add_reference_plane():void {
      var referencePlane:Plane = new Plane(new ColorMaterial(0xFF0000, 0.4),80,80);
      referencePlane.rotationX = 180;
      referencePlane.rotationY = 180;
      referencePlane.rotationZ = 90;
      referencePlane.position = new Number3D(40,-10,700);
      scene_pv.addChild(referencePlane);
    }

    private function setup_viewport():void {

      // Clear the graphics for screen and signal sprites.
      SpriteHelper.wipe(screen);
      SpriteHelper.wipe(signal);

      var b:Rectangle = GraphicsHelper.rect(BookConfig.VIEW_WIDTH, BookConfig.VIEW_HEIGHT);

      // Screenback the camera image
      // white ghost to make 3d element more contrasty.
      GraphicsHelper.box(screen, b, BookConfig.SCREENBACK_COLOR,1);
      screen.alpha = 0;

      b.inflate(BookConfig.BORDER_PADDING-1,BookConfig.BORDER_PADDING-1);
      GraphicsHelper.border(signal, b, 0xFF0000, 0xFF0000);
      signal.visible = false;

      SpriteHelper.add_these(this, video, screen, signal, viewport);

      //Flop image - this makes the webcam image a mirror.
      video.scaleX = -1;
      video.x = video.width;

    }

    // This is where all the good stuff happens.
    // Note: could switch ticks for different modes
    // instead of keeping all this logic in one function.
    private function tick(event:Event = null):void {

      if (BookState.PAUSED) return;

      // Ease up on processing if no marker
      // Looking for a marker is expensive because we need to
      // iterate through each marker on every tick.
      // The app bogs down, so we throttle it to 20%
      if (
          (lost_marker_count > TICK_DELAY) &&
          ((lost_marker_count%5) != 0) //Throttle to 1 in 5
      ) {
        lost_marker_count++;
        test_timeout();
        if (current_module) current_module.tick();
        renderer.render();
        return;
      }

      if (!webcam) return;

      // Don't recalculate position if there's no activity -
      // reduces flickering when reader is trying to hold still.
      if (!detected_marker || !current_module || webcam.activityLevel > BookConfig.MOTION_LEVEL) {

        // Update raster with the video data (i.e. webcam image)
        capture.draw(video,videoTransformation);
        raster.setBitmapData(capture);

        var detected:Boolean = false,
            i:int = -1,
            test_marker:FLARSingleMarkerDetector;

        try {

          //Do we already have a marker?
          if (detected_marker) {

            // Do we still have the marker?
            detected = (detected_marker.detectMarkerLite(raster, BookConfig.THRESHOLD)
                && detected_marker.getConfidence() > BookConfig.MIN_CONFIDENCE);

            if (!detected && lost_marker_count > (TICK_DELAY*1)) {
              // We lost the marker and we've waited long
              // enough that we should unset it
              // We delay a few ticks to reduce hiccups.
              detected_marker = null;
            }

          } else  {
            // We don't already have a detector,
            // so we loop through all of them.
            // This is expensive.
            while (++i < num_markers) {
              // TODO: This would be faster if we started one below the id
              // of the last found marker since the reader probably won't
              // be randomly shuffling through the book.
              test_marker = markers[i];
              if (
                  test_marker
                  && test_marker.detectMarkerLite(raster, BookConfig.THRESHOLD)
                  && test_marker.getConfidence() > BookConfig.HIGH_CONFIDENCE
              ) {
                // Found a marker we like.
                detected_marker = test_marker;
                detected = true;
                break;
              }
            }
          }
        } catch (e:Error) {
          trace("Tick error");
        }

        if (detected ) {

          signal.visible = true;

          if (detected_marker && !current_module) {

            // Get the module for this marker.
            var detected_module:iBookModule = module_for(detected_marker);

            // Has the marker been on screen for long enough?
            // If so, let's intro it.
            if (found_marker_count > TICK_DELAY && (current_module!==detected_module)) {

              lost_marker_count = 0;
              current_module = detected_module;

              BookHelper.debug("Introing module:" + current_module.id);

              // We pass 'this' (the sprite) so we can use stage.height/width when exploding modules.
              current_module.init(this, markerWrapper3D);
              current_module.intro();

              if (BookConfig.DEBUG) debug_plane.visible = true;

              dispatchEvent(new BookEvent(BookEvent.MARKER_FOUND));
              BetweenAS3.tween(screen, {alpha:BookConfig.SCREEN_ALPHA_MAX}, null, 0.5, Quad.easeIn).play();
              AnalyticsHelper.event("marker_found/" + current_module.id);

            }
          }

          found_marker_count++;

          if (detected_marker) {
            detected_marker.getTransformMatrix(transformation);
            markerWrapper3D.setTransformMatrix(transformation); //Update marker wrapper

            if (markerWrapper3D.z < 0) {
              // The disappearing marker problem might (?!) be caused by detection that
              // inverts the z position -- placing it waaaay offscreen.
              trace("Craaaazzzzy Z");
              markerWrapper3D.z = -markerWrapper3D.z;
              lost_marker_count++;
              found_marker_count = 0;
            }
          }

          //trace("Marker scale:" + markerWrapper3D.scaleX + "|" + markerWrapper3D.scaleY + "|" + markerWrapper3D.scaleZ);
          //trace("Marker position:" + markerWrapper3D.x + "|" + markerWrapper3D.y + "|" + markerWrapper3D.z);
          //trace("Marker rotation" + markerWrapper3D.rotationX + "|" + markerWrapper3D.rotationY + "|" + markerWrapper3D.rotationZ);

        } else {

          //trace("lost_marker " + lost_marker + "|" + module)
          signal.visible = false;
          lost_marker_count++;
          found_marker_count = 0;

          if (current_module && (lost_marker_count >= TICK_DELAY)) {
            BookHelper.debug("Removing module");
            dispatchEvent(new BookEvent(BookEvent.MARKER_LOST));
            BetweenAS3.tween(screen,{alpha:BookConfig.SCREEN_ALPHA_MIN},null,.5,Quad.easeIn).play();
            current_module.remove();
            current_module = null;
            if (BookConfig.DEBUG) debug_plane.visible = false;

          }
        }
      }

      if (current_module) current_module.tick();
      renderer.render();

    }

    // Preview markers are permanently visible.
    private var preview_module:iBookModule;
    private function preview_tick(event:Event=null):void {

      if (!preview_module) {
        preview_module = module_for(markers[0]); //Default to first marker.

        //Set markerWrapper position
        markerWrapper3D.position = preview_module.preview_position;
        markerWrapper3D.rotationX = preview_module.preview_rotation.x;
        markerWrapper3D.rotationY = preview_module.preview_rotation.y;
        markerWrapper3D.rotationZ = preview_module.preview_rotation.z;
        markerWrapper3D.scale = preview_module.preview_scale;
        markerWrapper3D.scaleX*=-1;

        preview_module.init(this, markerWrapper3D);
        preview_module.intro();

        BetweenAS3.tween(screen, {alpha:BookConfig.SCREEN_ALPHA_MAX}, null, 0.5, Quad.easeIn).play();
      }

      preview_module.tick();
      renderer.render();
    }

    public function reset_preview():void {
      if (preview_module) {
        preview_module.remove();
        preview_module = null;
      }
    }

    protected function module_for(target_detector:FLARSingleMarkerDetector):iBookModule {
      return modules[target_detector];
    }

    private function monitor_status(event:StatusEvent):void { //monitor webcam status
      if (event.code=="Camera.Muted") {
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_MUTED));
      } else {
        trace("Detected webcam status change:" + event.code);
      }
    }

    private function monitor_activity(event:ActivityEvent):void {
      //trace("Camera activity:" + webcam.activityLevel)
    }

    private function test_timeout():void {
      if (BookConfig.HIDE_TIMEOUT) return; // Do not show marker.
      if (lost_marker_count === BookConfig.LOST_MARKER_TIMEOUT) dispatchEvent(new BookEvent(BookEvent.MARKER_TIMEOUT));
    }

    private function remove_tick_listeners():void {
      if (hasEventListener(Event.ENTER_FRAME)) {
        removeEventListener(Event.ENTER_FRAME, tick);
        removeEventListener(Event.ENTER_FRAME, preview_tick);
      }
    }

    public function marker_preview_mode(status:Boolean):void {
      preview_mode = status;

      remove_tick_listeners();

      if (preview_mode) {
        addEventListener(Event.ENTER_FRAME, preview_tick);
      } else {
        addEventListener(Event.ENTER_FRAME, tick);
      }

    }
  }
}
