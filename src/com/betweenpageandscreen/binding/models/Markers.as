package com.betweenpageandscreen.binding.models
{
  import flash.events.Event;
  import flash.net.FileReference;
  import flash.utils.ByteArray;
  
  public class Markers
  {
    
    private var _markers:Array = [];
    public function get markers():Array {
      return _markers; 
    }
    
    public function add(data:String):void {
      markers.push(data);
    }

    public function reset():void {
      _markers = [];
    }

    //Save markers as a bytearray
    public function save(event:Event=null):void {
      var ba:ByteArray = new ByteArray;
      var m:Array = markers;
      ba.writeObject(m);
      ba.compress();
      var f:FileReference = new FileReference;
      f.save(ba,"markers.ba");
    }

  }
}