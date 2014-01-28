package com.betweenpageandscreen.binding.bootstrapper {
import com.betweenpageandscreen.binding.config.BookConfig;
import com.betweenpageandscreen.binding.events.BookEvent;
import com.betweenpageandscreen.binding.models.CameraParams;
import com.betweenpageandscreen.binding.models.Markers;
import com.betweenpageandscreen.binding.service.BookService;
import com.betweenpageandscreen.binding.service.MarkerService;
import com.betweenpageandscreen.binding.views.Book;
import com.bradwearsglasses.utils.helpers.ArrayHelper;

import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.media.Camera;

import flash.utils.ByteArray;

import org.robotlegs.mvcs.Context;

public class Bootstrapper extends Context{

  public var book:Book;
  public function get webcam():Camera {
    try {
      return book.videoDisplay.webcam;
    } catch(e:Error) {
      trace("## Bootstrapper: Could not get webcam. ##");
    }
    return null;
  }

  //Commands to call in order.
  private var init_sequence:Array =
      [
        BookEvent.CAMERA_LOAD,
        BookEvent.MARKER_LOAD,
        BookEvent.WEBCAM_ATTACH,
        BookEvent.VIEW_PREP
      ];

  //TODO: Non-relative urls?
  [Embed(source="../../../../resources/markers.ba", mimeType="application/octet-stream")]
  private static var _markers:Class;
  public static function get markers():ByteArray {
    return new _markers ;
  }

  [Embed(source="../../../../resources/camera.ba", mimeType="application/octet-stream")]
  private static var _camera_config:Class;
  public static function get camera_config():ByteArray {
    return new _camera_config
  }

  public function Bootstrapper(contextView:DisplayObjectContainer=null, autoStartup:Boolean=true)  {
    trace("\n### BPS Binding " + BookConfig.BINDING_VERSION + " ###\n");
    super(contextView, autoStartup);
    map();
    super.startup();
  }

  private function map():void {

    injector.mapSingleton( Markers );
    injector.mapSingleton( CameraParams );
    injector.mapSingleton( BookService );
    injector.mapSingleton( MarkerService );

    mediatorMap.mapView(Book, BootstrapperMediator);
  }

  // We need to run through a init_sequence of async actions
  // to get the app running. We'll set up listeners for each
  // action. Each listener calls the next() command when fired
  // to move through the stack.
  public function start(options:Object=null):void {

    // TEMP: Until we support bootstrapping uncached camera and markers,
    // set cached values for cameras and markers.
    BookConfig.CAMERA_DATA = camera_config;
    BookConfig.MARKERS_DATA = markers;

    setListeners();

    book = new Book();
    book.addEventListener(Event.ADDED_TO_STAGE, function(event:Event):void {
      next("Starting bootstrapper"); //Kick off the first event.
    });

    contextView.addChild(book);

  }

  private function setListeners():void {

    //For convenience, we're naming the callback the event name.
    //NOTE: not using these right now...
    ArrayHelper.concat(init_sequence).forEach(
      function(event_name:String,...rest):void {
        addEventListener(event_name, do_callback);
      }
    );

    addEventListener(BookEvent.BOOTSTRAP_ERROR, error);
    addEventListener(BookEvent.BOOTSTRAP_NEXT, next);
  }

  private function do_callback(event:BookEvent):void {
    try {
      this[event.type].call(this, event);
    } catch (e:Error) {
      trace(":: Failed callback for " + event.type);
    }
  }

  private function error(msg:String, event:BookEvent=null):void {
    trace("## Bootstrap error " + msg);
    trace(event);
  }

  //Call next event in the init sequence
  private function next(msg:String = null):void {
    dispatch(BookEvent.BOOTSTRAP_STATUS, {msg:msg});
    if (init_sequence.length > 0) {
      dispatch(init_sequence.shift() as String);
    } else {
      dispatch(BookEvent.BOOTSTRAP_COMPLETE);
    }
  }

  public function dispatch(type:String, data:*=null):void {
    trace("Bootstrapper: dispatching event:" + type);
    var event:BookEvent = new BookEvent(type, 'default', data);
    dispatchEvent(event);
  }
}
}
