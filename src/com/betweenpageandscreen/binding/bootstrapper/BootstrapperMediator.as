package com.betweenpageandscreen.binding.bootstrapper {
import com.betweenpageandscreen.binding.config.BookConfig;
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.models.CameraParams;
import com.betweenpageandscreen.binding.models.Markers;
import com.betweenpageandscreen.binding.models.Pages;
import com.betweenpageandscreen.binding.service.BookService;
import com.betweenpageandscreen.binding.service.MarkerService;
import com.betweenpageandscreen.binding.views.Book;
import com.bradwearsglasses.utils.debug.bwgFPS;
import com.bradwearsglasses.utils.helpers.LayoutHelper;

import flash.events.Event;
import flash.events.StatusEvent;
import flash.geom.Point;
import flash.media.Camera;
import flash.media.Video;
import flash.system.Security;
import flash.system.SecurityPanel;
import flash.utils.ByteArray;
import org.robotlegs.mvcs.Mediator;

//Ugh, need to put in mediator to get injection to work...?
public class BootstrapperMediator extends Mediator{

  [Inject]
  public var view:Book;

  [Inject]
  public var cameraService:BookService;

  [Inject]
  public var markerService:MarkerService;

  [Inject]
  public var markers:Markers;

  [Inject]
  public var cameraParams:CameraParams;

  private var fps:bwgFPS;

  override public function onRegister():void {

    if (BookConfig.SHOW_FPS) {
      fps = new bwgFPS(0xcccccc);
      contextView.stage.addChild(fps);
    }

    set_listeners();
    resize();
  }

  private function set_listeners():void {
    eventMap.mapListener(eventDispatcher, BookEvent.CAMERA_LOAD, camera_load, BookEvent);
    eventMap.mapListener(eventDispatcher, BookEvent.CAMERA_PARAMS_COMPLETE, next, BookEvent);
    eventMap.mapListener(eventDispatcher, BookEvent.MARKER_LOAD, markers_load, BookEvent);
    eventMap.mapListener(eventDispatcher, BookEvent.MARKERS_COMPLETE, markers_complete, BookEvent);


    eventMap.mapListener(eventDispatcher, BookEvent.WEBCAM_ATTACH, webcam_attach, BookEvent);
    eventMap.mapListener(eventDispatcher, BookEvent.VIEW_PREP, view_prep, BookEvent);

    eventMap.mapListener(view, BookEvent.VIEW_PREPPED, view_prepped, BookEvent);
    eventMap.mapListener(view, BookEvent.MARKERS_REASSIGN, markers_reassign, BookEvent);

    //TODO: If we need the webcam permission the interface appears to hang.
    eventMap.mapListener(view.videoDisplay, BookEvent.WEBCAM_ATTACHED, next, BookEvent);
    eventMap.mapListener(view.videoDisplay, BookEvent.WEBCAM_MULTIPLE, error, BookEvent);
    eventMap.mapListener(view.videoDisplay, BookEvent.WEBCAM_FAIL, error, BookEvent);
    eventMap.mapListener(view.videoDisplay, BookEvent.WEBCAM_MUTED, webcam_muted, BookEvent);

    eventMap.mapListener(contextView.stage, Event.RESIZE, resize);

  }

  private function next(event:BookEvent=null):void {
    trace("Next after: " + event.type);
    dispatch(new BookEvent(BookEvent.BOOTSTRAP_NEXT));
  }

  private function error(event:BookEvent=null):void {
    dispatch(new BookEvent(BookEvent.BOOTSTRAP_ERROR,'default', event));
  }

  private function camera_load(event:BookEvent=null):void {
    if (BookConfig.CACHED_CAMERA) {
      cameraService.parse_cached_camera(BookConfig.CAMERA_DATA);
    } else {
      // Only handle cached cameras in bootstrapper for now
    }
  }

  private function markers_load(event:BookEvent=null):void {
    if (BookConfig.CACHED_MARKERS) {
      var ba:ByteArray = BookConfig.MARKERS_DATA;
      ba.uncompress();
      var markers:Array = ba.readObject();
      markerService.markers_from_cache(markers);
      ba = null;
    } else {
      //Only handle cached markers in bootstrapper for now.
    }
  }

  //TODO: This should be part of the markers class.
  private function markers_complete(event:BookEvent=null):void {
    markers_assign();
    view.stop_waiting();
    next(event);
  }

  private function markers_assign():void {
    var module_num:int = 0;
    markers.markers.forEach(
      function(marker_string:String, ...rest):void {
        view.videoDisplay.add_marker(marker_string,Pages.PAGES[module_num],module_num++,cameraParams)
      }
    );
  }

  private function markers_reassign(event:BookEvent=null):void {
    trace("## Bootstrapper trying to re-assign markers.")
    markers_assign();
  }

  private function webcam_attach(event:BookEvent=null):void {
    view.videoDisplay.setup_webcam(); //All sorts of things can go wrong here.
  }

  private function view_prep(event:BookEvent=null):void {
    view.setup(cameraService.cameraParams);
    view.intro(); //Plays animation
  }

  private function view_prepped(event:BookEvent=null):void {
    view.start();
    next(event);
  }

  //If the webcam is muted we need to show the security panel
  private function webcam_muted(event:BookEvent=null):void {

    //Only way we know if user accepts security is if camera status changes (?)
    var camera:Camera = Camera.getCamera();
    if (camera) {
      camera.addEventListener(StatusEvent.STATUS, changed_camera_status);
      var video:Video = new Video(camera.width, camera.height);
      video.attachCamera(camera);
    }

    Security.showSettings(SecurityPanel.PRIVACY);
  }

  private function changed_camera_status(event:Event=null):void {
    trace("Camera changed status, reattaching.");
    dispatch(new BookEvent(BookEvent.WEBCAM_ATTACH));
  }

  private function resize(event:Event=null):void {

    view.display_port.scaleX = BookConfig.UPSCALE(contextView.stage);
    view.display_port.scaleY = BookConfig.UPSCALE(contextView.stage);

    LayoutHelper.center_on_stage(view,contextView.stage,new Point(0, -10));
    LayoutHelper.in_center(view, view, view.display_port);

    if (fps) {
      fps.x = 0;
      fps.y = contextView.stage.stageHeight - 25;
    }
  }

}
}
