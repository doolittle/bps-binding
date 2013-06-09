package com.betweenpageandscreen.binding.views
{
  import com.betweenpageandscreen.binding.config.BookConfig;
  import com.betweenpageandscreen.binding.config.BookState;
  import com.betweenpageandscreen.binding.events.BookEvent;
  import com.betweenpageandscreen.binding.helpers.AnalyticsHelper;
  import com.betweenpageandscreen.binding.helpers.BookHelper;
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
  import org.papervision3d.materials.ColorMaterial;
  import org.papervision3d.objects.primitives.Plane;
  import org.papervision3d.render.LazyRenderEngine;
  import org.papervision3d.scenes.Scene3D;
  import org.papervision3d.view.Viewport3D;
  
  public class VideoDisplay extends Sprite
  {
  
    private var viewport:Viewport3D;
    private var camera3d:FLARCamera3D;
    private var scene_pv:Scene3D;
    private var renderer:LazyRenderEngine;
    private var marker:FLARMarkerNode;
    private var plane:Plane;
    private var scale:Matrix  = new Matrix;
    private var lost_marker:Number   = 0;
    private var found_marker:Number  = 0;
    private var TICK_DELAY:Number    = 6;
      
    private var webcam:Camera;
    private var video:Video;
    private var capture:BitmapData;
    
    public var screen:Sprite        = new Sprite;
    public var signal:Sprite        = new Sprite;
    
    private var module:iBookModule;      
    private var raster:FLARRgbRaster;
    private var detectors:Vector.<FLARSingleMarkerDetector> = new Vector.<FLARSingleMarkerDetector>(BookConfig.NUM_MARKERS)
    private var modules:Dictionary = new Dictionary
    private var num_detectors:Number = 0
    private var active_detector:FLARSingleMarkerDetector
    
    private var transformation:FLARTransMatResult  = new FLARTransMatResult;
    private var last_transformation:FLARTransMatResult
    private var transformation_stack:Array = new Array(16);     
    
    public function VideoDisplay() {
      scale.scale(BookConfig.DOWNSAMPLE, BookConfig.DOWNSAMPLE);
    }
    
    public function add_marker(patt:String, module:iBookModule,module_id:Number, params:CameraParams):void {
      if (!patt) return; 

      var flar_code:FLARCode = new FLARCode(BookConfig.MARKER_SIZE, BookConfig.MARKER_SIZE);
      flar_code.loadARPattFromFile(patt)
      
      var detector:FLARSingleMarkerDetector = new FLARSingleMarkerDetector(params.params, flar_code, BookConfig.CODE_WIDTH);
      detector.setContinueMode(true)
        
      detectors[ module_id] = detector
      
      module.id         = module_id
      modules[detector] = module
      
    }
    
    public function setup(params:CameraParams):void {
      trace("\n ### Prepping flar book")
      
      num_detectors = detectors.length
      setup_pv3d(params)
      setup_viewport()
  
    }    
    
    public function override_signal(custom_signal:Sprite):void {
      SpriteHelper.destroy(signal); 
      signal = custom_signal
    }
    
    public function start():void {
      if (hasEventListener(Event.ENTER_FRAME)) removeEventListener(Event.ENTER_FRAME, tick); 
      addEventListener(Event.ENTER_FRAME, tick);
    }
    
    public function setup_webcam():void {
      
      BookState.CAMERAS = Camera.names
      if (BookState.CAMERAS.length > 0) dispatchEvent(new BookEvent(BookEvent.WEBCAM_MULTIPLE));
      
      video       = new Video(BookConfig.CAMERA_WIDTH, BookConfig.CAMERA_HEIGHT);
      capture     = new BitmapData(BookConfig.SAMPLE_WIDTH, BookConfig.SAMPLE_HEIGHT, false)
      raster      = new FLARRgbRaster(BookConfig.SAMPLE_WIDTH, BookConfig.SAMPLE_HEIGHT)
      
      if (attach_webcam()) dispatchEvent(new BookEvent(BookEvent.WEBCAM_ATTACHED))
      
    }    
    
    public function attach_webcam():Boolean {
      
      if (webcam) webcam.removeEventListener(ActivityEvent.ACTIVITY, monitor_activity)
      trace("Trying to get camera:" + BookState.SELECTED_CAMERA + "|" + BookState.CAMERAS) 
      
      if (!BookState.SELECTED_CAMERA && GeneralHelper.is_on_a_mac()) {
        var index:int=0, i:Number = -1;
        while (++i < Camera.names.length) {
          if (Camera.names[i]=="USB Video Class Video") index = i
        }
        if (index!=0) BookState.SELECTED_CAMERA = index.toString() //Apparently camera[0] is not a camera on a mac. 
      }
      
      
      webcam = Camera.getCamera(BookState.SELECTED_CAMERA);   
      trace("You selected:" + BookState.SELECTED_CAMERA + "|" + webcam + "|" + webcam.muted)
      
      if (!webcam) {
        trace("Didn't find a webcam")
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_FAIL))
        return false;
      } else if (webcam.muted || Capabilities.avHardwareDisable) {
        trace("Webcam is muted")
        dispatchEvent(new BookEvent(BookEvent.WEBCAM_MUTED)); 
        return false; 
      }
      
      webcam.setMode(BookConfig.CAMERA_WIDTH, BookConfig.CAMERA_HEIGHT, BookConfig.CAM_FPS,false);
      webcam.setMotionLevel(BookConfig.MOTION_LEVEL,BookConfig.MOTION_LEVEL)
      webcam.addEventListener(ActivityEvent.ACTIVITY,monitor_activity);   
      webcam.addEventListener(StatusEvent.STATUS, monitor_status); 
      video.attachCamera(webcam);
      
      return true
      
    }    
    
    private function setup_viewport():void {
      
      var b:Rectangle = GraphicsHelper.rect(BookConfig.VIEW_WIDTH, BookConfig.VIEW_HEIGHT)        
      GraphicsHelper.box(screen, b, BookConfig.SCREENBACK_COLOR,1) //Screenback the camera image--white ghost to make 3d element more contrasty. 
      
      b.inflate(10,10)
      GraphicsHelper.border(signal, b, 0xFF0000, 0xFF0000)
      signal.alpha = .5
      signal.visible = false
      SpriteHelper.add_these(this, video, screen, signal, viewport)
    }    
    
    private function setup_pv3d(params:CameraParams):void {
      
      viewport = new Viewport3D(BookConfig.VIEW_WIDTH, BookConfig.VIEW_HEIGHT);
      camera3d = new FLARCamera3D(params.params);
      
      marker = new FLARMarkerNode
      marker.useClipping = true
      
      scene_pv = new Scene3D();
      scene_pv.addChild(marker)
      
      plane = new Plane( new ColorMaterial(0xff0000,.2),85,85);      
      if (BookConfig.DEBUG)  marker.addChild(plane); 
      
      renderer = new LazyRenderEngine(scene_pv, camera3d, viewport);    
    }  
        
    private function tick(e:Event = null):void {
      if (BookState.PAUSED) return; 
      if ((lost_marker > TICK_DELAY) && ((lost_marker%5) != 0)) { //Ease up on processing if no marker   
        lost_marker++
        test_timeout()
        renderer.render()
        return; 
      }
      
      if (webcam && (webcam.activityLevel > BookConfig.MOTION_LEVEL ||  !active_detector || !module)) { //Don't recalculate if there's no activity. stops flickering.
        capture.draw(video,scale);
        raster.setBitmapData(capture)
        var detected:Boolean = false, i:Number = -1, detector:FLARSingleMarkerDetector;
        
        try {
          if (active_detector) { //Do we already have a detector?
            detected = (active_detector.detectMarkerLite(raster, BookConfig.THRESHOLD) && active_detector.getConfidence() > BookConfig.MIN_CONFIDENCE);
            if (!detected && lost_marker > (TICK_DELAY*1)) active_detector = null; //don't kill current detector for a few ticks.
          } else  { //We don't already have a detector, loop through all of them.
            while (++i < num_detectors) { //TODO: This would be faster if we started one below the id of the last found marker since the user won't be randomly shuffling through the book. 
              detector = detectors[i]     
              if (detector && detector.detectMarkerLite(raster, BookConfig.THRESHOLD) && detector.getConfidence() > BookConfig.HIGH_CONFIDENCE) {
                active_detector = detector
                detected = true
                break;
              }
            }
          }
        } catch (e:Error) { 
          trace("Tick error") 
        }
        
        if (detected ) {
          
          signal.visible = true;
          plane.visible  = true;
          
          if (active_detector && (!module || lost_marker > 0)) {
            var temp:iBookModule = module_for(active_detector); 
            //if (temp==module)  { lost_marker = 0; return; }  // not sure why this would happen. 
            if (found_marker > TICK_DELAY && (module!=temp)) { //We new found a marker for a period of time, let's intro it. 
              if (module) module.remove();
              lost_marker = 0;
              module = temp;
              BookHelper.debug("Introing module:" + module.id)
              module.init(this, marker);
              module.intro();
              dispatchEvent(new BookEvent(BookEvent.MARKER_FOUND))
              BetweenAS3.tween(screen,{alpha:BookConfig.SCREEN_ALPHA_MAX},null,.5,Quad.easeIn).play()
              AnalyticsHelper.event("marker_found/" + module.id)
            }
          }
          
          if (active_detector) active_detector.getTransformMatrix(transformation)         
          if (transformation) {
            /*
            transformation.getValue(transformation_stack);
            trace ("n11:" + transformation_stack[0*4+0]); 
            trace ("n22:" + transformation_stack[1*4+2]); 
            trace ("n33:" + transformation_stack[2*4+2]);
            trace("\n");
            */
            marker.setTransformMatrix(transformation);
          }
          
          found_marker++
        } else {
          //trace("lost_marker " + lost_marker + "|" + module)
          signal.visible = false;
          plane.visible  = false;
          lost_marker++;
          found_marker = 0;
          if (module && (lost_marker > TICK_DELAY)) {
            BookHelper.debug("Removing module")
            dispatchEvent(new BookEvent(BookEvent.MARKER_LOST))
            BetweenAS3.tween(screen,{alpha:BookConfig.SCREEN_ALPHA_MIN},null,.5,Quad.easeIn).play()
            module.remove()
            module = null;
          } 
          test_timeout();
        }
      }
      
      if (module) module.tick(); 
      renderer.render()
    }    
    
    protected function module_for(target_detector:FLARSingleMarkerDetector):iBookModule {
      return modules[target_detector]
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
      if (lost_marker == BookConfig.LOST_MARKER_TIMEOUT) dispatchEvent(new BookEvent(BookEvent.MARKER_TIMEOUT))
    }
    
  }
}